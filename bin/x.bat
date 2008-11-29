@rem = '--*-Perl-*--
@::# $Id$
@echo off
:: batch file tricks to allow 'sourcing' of <commands>
:: :'sourcing' => running commands in the parents environmental context, allowing modification of parents environment and CWD

:: need one GLOBAL var to allow sourcing (should be unique so that we don't tramp on our parent's %ENV
set _x_a6f4d9b1c3e6a0b7_bat_=nul
if NOT [%1]==[-S] ( goto :pass_findUniqueTemp )
:findUniqueTemp
set _x_a6f4d9b1c3e6a0b7_bat_=%temp%\x.source.%RANDOM%.bat
if EXIST %_x_a6f4d9b1c3e6a0b7_bat_% ( goto :findUniqueTemp )
:pass_findUniqueTemp
::echo _x_a6f4d9b1c3e6a0b7_bat_=%_x_a6f4d9b1c3e6a0b7_bat_%

:: localize all other ENV changes until sourcing is pending
setlocal

:: under 4NT/TCC, DISABLE command aliasing (aliasing may loop if perl is aliased to use this script to sanitize it's arguments)
if NOT "%_4ver%" == "" ( setdos /x-1 )

:: gather all arguments (work for WinNT [and should work for previous versions as well])
set "args=%*"
:::: :unable to just use shifts b/c CMD splits command lines on some non-whitespace characters (such as '=') for interpretation of batch vars (%1, %2, ...)
::set "args="
::set "arg="
::set "line="
::set line=%*
::::echo "(preloop) line=%line%"
:::gatherargs
::for /f "tokens=1,*" %%a in ("%line%") do (
::	set "arg=%%a"
::	set "line=%%b"
::	)
::if NOT "%arg%" == "" (
::	if NOT "%args%" == "" ( set "args=%args% " )
::	set "args=%args%%arg%"
::	)
::if NOT "%line%"=="" ( goto :gatherargs )
::echo args=%args%


if NOT [%_x_a6f4d9b1c3e6a0b7_bat_%]==[nul] ( goto :source_output )
::perl -x -S %0 %*
perl -x -S %0 %args%
if NOT %errorlevel% == 0 (
	endlocal
	set "_x_a6f4d9b1c3e6a0b7_bat_="
	exit /B %errorlevel%
	)
goto :cleanup

:source_output
echo @:: %_x_a6f4d9b1c3e6a0b7_bat_% file > %_x_a6f4d9b1c3e6a0b7_bat_%
echo @echo OFF >> %_x_a6f4d9b1c3e6a0b7_bat_%
::echo "perl output"
perl -x -S %0 %args% >> %_x_a6f4d9b1c3e6a0b7_bat_%
::echo "sourcing - started"
if NOT %errorlevel% == 0 (
	endlocal
	set "_x_a6f4d9b1c3e6a0b7_bat_="
	erase %_x_a6f4d9b1c3e6a0b7_bat_% 1>nul 2>nul
	exit /B %errorlevel%
	)
endlocal
call %_x_a6f4d9b1c3e6a0b7_bat_%
::echo "sourcing - done"
erase %_x_a6f4d9b1c3e6a0b7_bat_% 1>nul 2>nul

:cleanup
::echo cleanup
set "_x_a6f4d9b1c3e6a0b7_bat_="
goto endofperl
@rem ';
#!perl -w   -*- tab-width: 4; mode: perl -*-
#line 77

# x [-a] <command> <arg(s)>
# execute <command> with parsed <arg(s)>
# a .bat file to work around Win32 I/O redirection bugs with execution of '.pl' files via the standard Win32 filename extension execution mechanism (see documentation for pl2bat [ADVANTAGES, specifically Method 5] for further explanation)
# see linux 'xargs' command for something similar
# FIXED (for echo): note: command line args are dequoted so commands taking string arguments and expecting them quoted might not work exactly the same (eg, echo 'a s' => 'a s' vs x echo 'a s' => "a s")
#	NOTE: using $"<string>" => "<string>" quote preservation behavior can overcome this issue (eg, x perl -e $"print 'test'")
#		[??] $"<string>" under bash ignores the $ if C or POSIX locale in force, and only leaves string qq'd if translated to another locale
#	NOTE: or use another method to preserve quotes for appropriate commands (such as "'"'<string'"'" (noisy but it works)

# '-a' is the one optional paramater (placed immediately before the <command>) => print expanded args and quit (WITHOUT executing the command)

##TODO (-d and -u options)
# -d: => dosify [default]
# -d:all => dosify='all'
# -u: => unixify
# -u:all => unixify='all'

# TODO: add option to reverse all canonical forward slashes in options to backslash to avoid interpretation as options by commands
# TODO: add option to NOT quote a command (such as for echo) and take the special processing out of the code? (what about the echo.bat situation, maybe 'alias echo=x -Q echo $*' or 'alias echo.bat=x echo.bat' or would that not solve it....)

use strict;
use warnings;

# VERSION: major.minor.revision[.build]]  { minor is ODD = alpha/beta/experimental; minor is EVEN = release }
# generate VERSION from $Version$ SCS tag
# $defaultVERSION 	:: used to make the VERSION code resilient vs missing keyword expansion
# $generate_alphas	:: 0 => generate normal versions; true/non-0 => generate alpha version strings for ODD numbered minor versions
use version qw(); our $VERSION; { my $defaultVERSION = '0.1.0'; my $generate_alphas = 0; $VERSION = ( $defaultVERSION, qw( $Version$ ))[-2]; if ($generate_alphas) { $VERSION =~ /(\d+)\.(\d+)\.(\d+)(?:\.)?(.*)/; $VERSION = $1.'.'.$2.((!$4&&($2%2))?'_':'.').$3.($4?((($2%2)?'_':'.').$4):q{}); $VERSION = version::qv( $VERSION ); }; } ## no critic ( ProhibitCallsToUnexportedSubs ProhibitCaptureWithoutTest ProhibitNoisyQuotes ProhibitMixedCaseVars ProhibitMagicNumbers)

use Pod::Usage;
use Getopt::Long qw(:config bundling bundling_override gnu_compat no_getopt_compat no_permute); ##	# no_permute to parse all args up to 1st non-arg or '--'

use Carp::Assert;

use FindBin;	## NOCPAN :: BEGIN used in FindBin, so incompatible with any other modules using it; !!!: don't use for any CPAN package/module

use ExtUtils::MakeMaker;

#-- config
#my %fields = ( 'quotes' => qq("'`), 'seperators' => qq(:,=) );	#"

@ARGV = Win32::CommandLine::argv( { dosify => 'true' } ) if eval { require Win32::CommandLine; };

# getopt
my %ARGV = ();
GetOptions (\%ARGV, 'source|S|e', 'args|a', 'help|h|?|usage', 'man', 'version|ver|v') or pod2usage(2);
Getopt::Long::VersionMessage() if $ARGV{'version'};
pod2usage(1) if $ARGV{'help'};
pod2usage(-verbose => 2) if $ARGV{'man'};

pod2usage(1) if @ARGV < 1;

if ( $ARGV{args} )
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

if ( $ARGV{args} )
	{
	for (my $i = 0; $i < @ARGV; $i++) { print '$ARGV'."[$i] = '$ARGV[$i]'\n"; }
	}

#system { $ARGV[0] } @ARGV;		# doesn't see "echo" as a command (?? problem for all CMD built-ins?)
if ( not $ARGV{args} )
	{
	## TODO: is it possible to run the process as an extension of this process (i.e. not as a sub-process, so that it can modify the parent environment?? x.bat is already in the CLI parent environment? is this wise? but otherwise, how would 'cd ~' work?)
	if ($ARGV{source} ) { print join(" ",@ARGV); } else { system @ARGV; }
	}

__END__
:endofperl
