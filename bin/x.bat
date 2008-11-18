@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!perl -w   -*- tab-width: 4; mode: perl -*-
#line 15

# $Id$

# x [-a] <command> <arg(s)>
# execute <command> with parsed <arg(s)>
# a .bat file to work around Win32 I/O redirection bugs with execution of '.pl' files via the standard Win32 filename extension execution mechanism (see documentation for pl2bat [ADVANTAGES, specifically Method 5] for further explanation)
# see linux 'xargs' command for something similar
# FIXED (for echo): note: command line args are dequoted so commands taking string arguments and expecting them quoted might not work exactly the same (eg, echo 'a s' => 'a s' vs x echo 'a s' => "a s")
#	NOTE: using $"<string>" => "<string>" quote preservation behavior can overcome this issue (eg, x perl -e $"print 'test'")
#		[??] $"<string>" under bash ignores the $ if C or POSIX locale in force, and only leaves string qq'd if translated to another locale
#	NOTE: or use another method to preserve quotes for appropriate commands (such as "'"'<string'"'" (noisy but it works)

# '-a' is the one optional paramater (placed immediately before the <command>) => print expanded args and quit (WITHOUT executing the command)

# TODO: add option to reverse all canonical forward slashes in options to backslash to avoid interpretation as options by commands
# TODO: add option to NOT quote a command (such as for echo) and take the special processing out of the code? (what about the echo.bat situation, maybe 'alias echo=x -Q echo $*' or 'alias echo.bat=x echo.bat' or would that not solve it....)

use strict;
use warnings;

# VERSION: major.minor.revision[.build]]  { minor is ODD = alpha/beta/experimental; minor is EVEN = release }
# generate VERSION from $Version$ SCS tag
# $defaultVERSION 	:: used to make the VERSION code resilient vs missing keyword expansion
# $generate_alphas	:: 0 => generate normal versions; true/non-0 => generate alpha version strings for ODD numbered minor versions
use version qw(); our $VERSION; { my $defaultVERSION = '0.1.0'; my $generate_alphas = 0; $VERSION = qw( $defaultVERSION $Version$ )[-2]; if ($generate_alphas) { $VERSION =~ /(\d+)\.(\d+)\.(\d+)(?:\.)?(.*)/; $VERSION = $1.'.'.$2.((!$4&&($2%2))?'_':'.').$3.($4?((($2%2)?'_':'.').$4):''); $VERSION = version::qv( $VERSION ); }; } ## no critic ( ProhibitCallsToUnexportedSubs ProhibitCaptureWithoutTest ProhibitNoisyQuotes )

use Pod::Usage;
use Getopt::Long qw(:config bundling bundling_override gnu_compat no_getopt_compat no_permute); ##	# no_permute to parse all args up to 1st non-arg or '--'

use Carp::Assert;

use FindBin;	## NOCPAN: BEGIN used, so incompatible with any other modules using it; !!!: don't use for any CPAN package/module/script

use ExtUtils::MakeMaker;

#-- config
#my %fields = ( 'quotes' => qq("'`), 'seperators' => qq(:,=) );	#"

@ARGV = Win32::CommandLine::argv( { dospath => 'true' } ) if eval { require Win32::CommandLine; };
# TODO:: dospaths == should fix the /X option issues for files
#@ARGV = Win32::CommandLine::argv( dospaths => 'true' ) if eval { require Win32::CommandLine; };

#my %ARGV = ();
#if (lc($ARGV[0]) eq '-a') { $ARGV{'args'} = 'true'; shift @ARGV; }

# getopt
my %ARGV = ();
GetOptions (\%ARGV, 'args|a', 'dospath|dos|d', 'help|h|?|usage', 'man', 'version|ver|v') or pod2usage(2);
Getopt::Long::VersionMessage() if $ARGV{'version'};
pod2usage(1) if $ARGV{'help'};
pod2usage(-verbose => 2) if $ARGV{'man'};

pod2usage(1) if @ARGV < 1;

if ( $ARGV{'args'} )
	{
	my $cl = Win32::CommandLine::command_line();
	print 'command_line()'." = '$cl'\n";
	}

## unfortunately the args (which are correct here) are reparsed while going to the target command through CreateProcess() (PERL BUG: despite explicit documentation in PERL that system bypasses the shell and goes directly to execvp() for scalar(@ARGV) > 1 although there is no obvious work around since execvp() doesn't really exist in Win32 and must be emulated through CreateProcess())
## so, protect the ARGs from CreateProcess() reparsing destruction
## echo is a special case (it must get it's command line directly, skipping the ARGV reparsed arguments of CreateProcess()... so check and don't re-escape quotes) for 'echo'
### checking for echo is a bit complicated any command starting with echo followed by a . or whitespace is treated as an internal echo command unless a file exists which matches the entire 1st argument, then it is executed instead
#if ((-e $ARGV[0]) || not $ARGV[0] =~ m/^\s*echo(.|\s*)/)
#	{ ## protect internal ARGV whitespace and double quotes by escaping them and surrounding the ARGV with another set of double quotes
#	## ???: do we need to just protect the individual whitespace and quote runs individually instead of a whole ARGV quote surround?
#	## ???: do we need to protect other special characters (such as I/O redirection and continuation characters)?
#	for (1..$#ARGV) {if ($ARGV[$_] =~ /\s/ || $ARGV[$_] =~ /["]/) {$ARGV[$_] =~ s/\"/\\\"/g; $ARGV[$_] = '"'.$ARGV[$_].'"'}; }
#	}

if ( $ARGV{'args'} )
	{
	for (my $i = 0; $i < @ARGV; $i++) { print '$ARGV'."[$i] = '$ARGV[$i]'\n"; }
	}

#system { $ARGV[0] } @ARGV;		# doesn't see "echo" as a command (?? problem for all CMD built-ins?)
if ( not $ARGV{'args'} )
	{
	system @ARGV;
	}

__END__
:endofperl
