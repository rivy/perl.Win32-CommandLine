@rem = '--*-Perl-*--
@::# $Id$
:: rename? xx.bat
@echo off
:: eXpand and eXecute command line
:: similar to linux xargs
:: ToDO: clean up documentation/comments
:: contains batch file tricks to allow 'sourcing' of target executable output
:: :'sourcing' => running commands in the parents environmental context, allowing modification of parents environment and CWD

:: NOTE: 4nt/TCC/TCMD quirk => use %% for %, whereas cmd.exe % => as long as it doesn't introduce a known variable (eg, %not_a_var => %not_a_var although %windir => C:\WINDOWS)

:: localize ENV changes until sourcing is pending
setlocal

set _xx_bat=nul

::echo *=%*

if [%1]==[-s] ( goto :findUniqueTemp )
if [%1]==[-so] ( goto :findUniqueTemp )
goto :pass_findUniqueTemp

:: find bat file for sourcing and instantiate it with 1st line of text
:findUniqueTemp
set _xx_bat="%temp%\x.bat.source.%RANDOM%.bat"
if EXIST %_xx_bat% ( goto :findUniqueTemp )
echo @:: %_xx_bat% file > %_xx_bat%
:pass_findUniqueTemp
::echo _xx_bat=%_xx_bat%

:: 4NT/TCC
::DISABLE command aliasing (aliasing may loop if perl is aliased to use this script to sanitize it's arguments); over-interpretation of % characters; disable redirection; backquote removal from commands
if 01 == 1.0 ( setdos /x-14567 )

if NOT [%_xx_bat%]==[nul] ( goto :source_expansion )
::echo "perl output"
perl -x -S %0 %*
if NOT %errorlevel% == 0 (
::	endlocal & exit /B %errorlevel%
	exit /B %errorlevel%
	)
endlocal
goto :done

:source_expansion
if 01 == 1.0 ( setdos /x0 )
echo @echo OFF >> %_xx_bat%
::echo "perl output"
perl -x -S %0 %* >> %_xx_bat%
::echo "sourcing - started"
if NOT %errorlevel% == 0 (
	erase %_xx_bat% 1>nul 2>nul
::	endlocal &  exit /B %errorlevel%
	exit /B %errorlevel%
	)
::echo "sourcing & cleanup..."
endlocal & call %_xx_bat% & erase %_xx_bat% 1>nul 2>nul

:done
goto endofperl
@rem ';
#!perl -w   -*- tab-width: 4; mode: perl -*-
#line 65

## TODO: add normal .pl utility documentation/POD, etc [IN PROCESS]

# xx [OPTIONS] <command> <arg(s)>
# execute <command> with parsed <arg(s)>
# a .bat file to work around Win32 I/O redirection bugs with execution of '.pl' files via the standard Win32 filename extension execution mechanism (see documentation for pl2bat [ADVANTAGES, specifically Method 5] for further explanation)
# see linux 'xargs' and 'source' commands for something similar
# FIXED (for echo): note: command line args are dequoted so commands taking string arguments and expecting them quoted might not work exactly the same (eg, echo 'a s' => 'a s' vs x echo 'a s' => "a s")
#	NOTE: using $"<string>" => "<string>" quote preservation behavior can overcome this issue (eg, x perl -e $"print 'test'")
#		[??] $"<string>" under bash ignores the $ if C or POSIX locale in force, and only leaves string qq'd if translated to another locale
#	NOTE: or use another method to preserve quotes for appropriate commands (such as "'"'<string'"'" (noisy but it works)

#TODO: add option to see "normal", "dosify", and "unixify" options for echo/args to see what a command using Win32::CommandLine will get
#	??	-a = -ad => expanded arguments as x.bat would for an another executable (dosified)
#	??	-au => unixify
#	??	-ai => normal (non-d/u expansion) == default expansion of arguments as a perl exe using Win32::commandLine::argv()
##TODO (-d and -u options)
# -d: => dosify [default]
# -d:all => dosify='all'
# -u: => unixify
# -u:all => unixify='all'
#
# ==> DON'T do this, leave x/xx as is. it's to expand/execute cmd.exe commands which have no internal expansion ability. add another utility to show what expansion occurs for each type of expansion option.

# TODO: add option to reverse all canonical forward slashes in options to backslash to avoid interpretation as options by commands
# TODO: add option to NOT quote a command (such as for echo) and take the special processing out of the code? (what about the echo.bat situation, maybe 'alias echo=x -Q echo $*' or 'alias echo.bat=x echo.bat' or would that not solve it....)

# Script Summary

=head1 NAME

xx - eXpand (reparse) and eXecute the command line

=head1 VERSION

This document describes C<xx> ($Version$).

=head1 SYNOPSIS

xx [-s|-so] [B<<option(s)>>] B<<command>> [B<<argument(s)>>]

=begin HIDDEN-OPTIONS

Options:

		--version       version message
	-?, --help          brief help message

=end HIDDEN-OPTIONS

=head1 OPTIONS

=over

=item -s

Expand the commandline and then source the resultant expanded command, causing possible modification of the current process environment. MUST be the first argument.

=item -so

Expand the commandline and then source the resulting output of executing the expanded command, causing possible modification of the current process environment. MUST be the first argument.

=item --version

=item --usage

=item --help, -?

=item --man

Print the usual program information

=back

=head1 REQUIRED ARGUMENTS

=over

=item <command>

COMMAND...

=back

=head1 DESCRIPTION

B<xx> will read expand the command line and execute the COMMAND.

NOTE: B<xx> is designed for use with legacy commands to graft on better command line interpretation behaviors. It shouldn't generally be necessary to use B<xx> on commands which already use Win32::CommandLine::argv() internally as the command line will be re-interpreted. If that's the behavior desired, that's fine; but think about it.
??? what about pl2bat'ed perl scripts? Since the command line is used within the wrapping batch file, is it clean for the .pl file or does it need x wrapping as well?

=cut

use strict;
use warnings;

# VERSION: major.minor.release[.build]]  { minor is ODD => alpha/beta/experimental; minor is EVEN => stable/release }
# generate VERSION from $Version$ SCS tag
# $defaultVERSION 	:: used to make the VERSION code resilient vs missing keyword expansion
# $generate_alphas	:: 0 => generate normal versions; true/non-0 => generate alpha version strings for ODD numbered minor versions
use version qw(); our $VERSION; { my $defaultVERSION = '0.3'; my $generate_alphas = 0; $VERSION = ( $defaultVERSION, qw( $Version$ ))[-2]; if ($generate_alphas) { $VERSION =~ /(\d+)\.(\d+)\.(\d+)(?:\.)?(.*)/; $VERSION = $1.'.'.$2.((!$4&&($2%2))?'_':'.').$3.($4?((($2%2)?'_':'.').$4):q{}); $VERSION = version::qv( $VERSION ); }; } ## no critic ( ProhibitCallsToUnexportedSubs ProhibitCaptureWithoutTest ProhibitNoisyQuotes ProhibitMixedCaseVars ProhibitMagicNumbers)

use Pod::Usage;

use Carp::Assert;

use FindBin;	## NOCPAN :: BEGIN used in FindBin, so incompatible with any other modules using it; !!!: don't use within any CPAN package/module that will be 'use'd or 'require'd by other code [ok for executables] (does another way exist using File::Spec rel2abs()??); ??? any problem with this since it's not loaded and only calls outside executables

use ExtUtils::MakeMaker;

#-- config
#my %fields = ( 'quotes' => qq("'`), 'seperators' => qq(:,=) );	#"

@ARGV = Win32::CommandLine::argv( { dosify => 'true', dosquote => 'true' } ) if eval { require Win32::CommandLine; };

#-- getopt
use Getopt::Long qw(:config bundling bundling_override gnu_compat no_getopt_compat no_permute pass_through); ##	# no_permute/pass_through to parse all args up to 1st unrecognized or non-arg or '--'
my %ARGV = ();
# NOTE: the 'source' option '-s' is bundled into the 'echo' option since 'source' is exactly the same as 'echo' to the internal perl script. Sourcing is done by the wrapping .bat script by executing the output of the perl script.
GetOptions (\%ARGV, 'echo|e|s', 'so', 'args|a', 'help|h|?|usage', 'man', 'version|ver|v') or pod2usage(2);
Getopt::Long::VersionMessage() if $ARGV{'version'};
pod2usage(1) if $ARGV{'help'};
pod2usage(-verbose => 2) if $ARGV{'man'};

pod2usage(1) if @ARGV < 1;

if ( $ARGV{args} )
	{
	my $cl = Win32::CommandLine::command_line();
	print ' $ENV{CMDLINE}'." = `".($ENV{CMDLINE}?$ENV{CMDLINE}:'<null>')."`\n";
	print 'command_line()'." = `$cl`\n";
	}

## unfortunately the args (which are correct at this point) are reparsed while going to the target command through CreateProcess() (PERL BUG: despite explicit documentation in PERL that system bypasses the shell and goes directly to execvp() for scalar(@ARGV) > 1 although there is no obvious work around since execvp() doesn't really exist in Win32 and must be emulated through CreateProcess())
## so, we must protect the ARGs from CreateProcess() reparsing destruction
## echo is a special case (it must get it's command line directly, skipping the ARGV reparsed arguments of CreateProcess()... so check and don't re-escape quotes) for 'echo'
### checking for echo is a bit complicated any command starting with echo followed by a . or whitespace is treated as an internal echo command unless a file exists which matches the entire 1st argument, then it is executed instead
#if ((-e $ARGV[0]) || not $ARGV[0] =~ m/^\s*echo(.|\s*)/)
#	{ ## protect internal ARGV whitespace and double quotes by escaping them and surrounding the ARGV with another set of double quotes
#	## ???: do we need to just protect the individual whitespace and quote runs individually instead of a whole ARGV quote surround?
#	## ???: do we need to protect other special characters (such as I/O redirection and continuation characters)?
#	for (1..$#ARGV) {if ($ARGV[$_] =~ /\s/ || $ARGV[$_] =~ /["]/) {$ARGV[$_] =~ s/\"/\\\"/g; $ARGV[$_] = '"'.$ARGV[$_].'"'}; }
#	}
# [2009-02-18] the protection is now automatically done already with the 'dosify' option above ... ? remove it for echo or just note the issue? or allow command line control of it instead? command line control might be problematic => finding the command string without reparsing the command line multiple times (could cause side effects if $(<COMMAND>) is implemented => make it similar to -S (solo and only prior to 1st non-option?)
#		== just note that echo has no command line parsing

if ( $ARGV{args} )
	{
	for (my $i = 0; $i < @ARGV; $i++) { print '$ARGV'."[$i] = `$ARGV[$i]`\n"; }
	}

#system { $ARGV[0] } @ARGV;		# doesn't see "echo" as a command (?? might be a problem for all CMD built-ins)
if ( not $ARGV{args} )
	{
	## TODO: REDO this comment -- unfortunately the args (which are correct at this point) are reparsed while going to the target command through CreateProcess() (PERL BUG: despite explicit documentation in PERL that system bypasses the shell and goes directly to execvp() for scalar(@ARGV) > 1 although there is no obvious work around since execvp() doesn't really exist in Win32 and must be emulated through CreateProcess())
	if ($ARGV{echo} ) { print join(" ",@ARGV); } else { if ($ARGV{so}) { my $x = join(" ",@ARGV); print `$x`; } else { system @ARGV; }}
	}

__END__
:endofperl
