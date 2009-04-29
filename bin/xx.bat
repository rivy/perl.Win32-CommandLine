@rem = q{--*-Perl-*--
@::# $Id$
@echo off
:: eXpand and eXecute command line
:: similar to linux xargs
:: TODO: clean up documentation/comments
:: parent environment is kept untouched except as modified by "sourcing" of target command line text or executable output
:: contains batch file techniques to allow "sourcing" of target command line text or executable output
:: :"sourcing" => running commands in the parents environmental context, allowing modification of parents environment and CWD

:: NOTE: TCC/4NT quirk => use %% for %, whereas CMD.exe % => as long as it does not introduce a known variable (eg, %not_a_var => %not_a_var although %windir => C:\WINDOWS)

:: localize ENV changes until sourcing is pending
setlocal

set _xx_bat=nul

::echo *=%*

if [%1]==[-s] ( goto :find_unique_temp )
if [%1]==[-so] ( goto :find_unique_temp )
goto :find_unique_temp_PASS

:: find bat file for sourcing and instantiate it with 1st line of text
:find_unique_temp
set _xx_bat="%temp%\xx.bat.source.%RANDOM%.bat"
if EXIST %_xx_bat% ( goto :find_unique_temp )
echo @:: %_xx_bat% TEMPORARY file > %_xx_bat%
:find_unique_temp_PASS
:: %_xx_bat% is now quoted [or it is simply "nul" and doesn't need quotes]
::echo _xx_bat=%_xx_bat%

:: TCC/4NT
::DISABLE command aliasing (aliasing may loop if perl is aliased to use this script to sanitize its arguments); over-interpretation of % characters; disable redirection; backquote removal from commands
if 01 == 1.0 ( setdos /x-14567 )

if NOT [%_xx_bat%]==[nul] ( goto :source_expansion )
::echo "perl output - no -s/-so"
perl -x -S %0 %*
if %errorlevel% NEQ 0 (
::	endlocal & exit /B %errorlevel%
	exit /B %errorlevel%
	)
endlocal																						s
goto :_DONE

:source_expansion
:: setdos /x0 needed? how about for _xx_bat execution? anyway to save RESET back to prior settings without all env vars reverting too? check via TCC help on setdos and endlocal
if 01 == 1.0 ( setdos /x0 )
echo @echo OFF >> %_xx_bat%
::echo perl output [source expansion { perl -x -S %0 %* }]
perl -x -S %0 %* >> %_xx_bat%
::echo "sourcing - BAT created"
if %errorlevel% NEQ 0 (
	set _ERROR=%errorlevel%
::	echo _ERROR=%ERROR%
	erase %_xx_bat% 1>nul 2>nul
	exit /B %_ERROR%
	)
::echo "sourcing & cleanup..."
:: how to propagate exit code from _xx_bat?
:: :: needed?
::    :: maybe not, since _xx_bat is a file of shell statements
::    :: but probably, since any error code generated in _xx_bat would be removed by erase (?confirm this).
:: :: %errorlevel% is set upon line read (not after %_xx_bat% execution
:: :: erase RESETS %errorlevel% depending on outcome (overriding any %_xx_bat% errors
:: :: if ERRORLEVEL N doesn't check for negative ERRORLEVELs
::endlocal & call %_xx_bat% & erase %_xx_bat% 1>nul 2>nul
:: use subroutines to preserve ENVIRONMENT (can use %N instead of polluting ENV)
endlocal & call :source_expansion_FINAL %_xx_bat%
goto :_DONE
::
:source_expansion_FINAL
::echo in FINAL [exec "%1%"]
call %1
call :source_expansion_CLEANUP %1 %errorlevel%
goto :EOF
:source_expansion_CLEANUP
::echo FINAL [erase TEMP (file=%1), ERRORLEVEL=%2]
erase %1 1>nul 2>nul
exit /B %2
goto :EOF

:_DONE
goto :endofperl
@rem };
#!perl -w  -- -*- tab-width: 4; mode: perl -*-
#NOTE: #line NN (where NN = LINE#+1)
#line 90

## TODO: add normal .pl utility documentation/POD, etc [IN PROCESS]

# xx [OPTIONS] <command> <arg(s)>
# execute <command> with parsed <arg(s)>
# a .bat file to work around Win32 I/O redirection bugs with execution of '.pl' files via the standard Win32 filename extension execution mechanism (see documentation for pl2bat [ADVANTAGES, specifically Method 5] for further explanation)
# see linux 'xargs' and 'source' commands for something similar
# FIXED (for echo): note: command line args are dequoted so commands taking string arguments and expecting them quoted might not work exactly the same (eg, echo 'a s' => 'a s' vs xx echo 'a s' => "a s")
#	NOTE: using $"<string>" => "<string>" quote preservation behavior can overcome this issue (eg, xx perl -e $"print 'test'")
#		[??] $"<string>" under bash ignores the $ if C or POSIX locale in force, and only leaves string qq'd if translated to another locale
#	NOTE: or use another method to preserve quotes for appropriate commands (such as "'"'<string'"'" (noisy but it works)

#TODO: add option to see "normal", "dosify", and "unixify" options for echo/args to see what a command using Win32::CommandLine will get
#	??	-a = -ad => expanded arguments as xx.bat would for an another executable (dosified)
#	??	-au => unixify
#	??	-ai => normal (non-d/u expansion) == default expansion of arguments as a perl exe using Win32::commandLine::argv()
##TODO (-d and -u options)
# -d: => dosify [default]
# -d:all => dosify='all'
# -u: => unixify
# -u:all => unixify='all'
#
# ==> DON'T do this, leave xx as is. it's to expand/execute cmd.exe commands which have no internal expansion ability. add another utility to show what expansion occurs for each type of expansion option.

# TODO: add option to reverse all canonical forward slashes in options to backslash to avoid interpretation as options by commands
# TODO: add option to NOT quote a command (such as for echo) and take the special processing out of the code? (what about the echo.bat situation, maybe 'alias echo=xx -Q echo $*' or 'alias echo.bat=xx echo.bat' or would that not solve it....)

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

Expand the command line (using Win32::CommandLine) and then B<source> the resulting expanded command. This allows B<modification of the current process environment> by the expanded command line. NOTE: MUST be the first argument.

=item -so

Expand the command line (using Win32::CommandLine) and then B<source> the B<OUTPUT> of the execution of the expanded command. This allows B<modification of the current process environment> based on the OUTPUT of the execution of the expanded command line. NOTE: MUST be the first argument.

=item --echo, -e

Print (but do not execute) the results of expanding the command line.

=item --args, -a

Print detailed information about the command line and it's expansion, including all resulting ARGS (B<without> executing the resultant expansion).

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
??? what about pl2bat'ed perl scripts? Since the command line is used within the wrapping batch file, is it clean for the .pl file or does it need xx wrapping as well?

=head1 EXAMPLES

Here are some examples of what's possible in the standard cmd and tcc shells:

    xx $( perl -MConfig -e "print $Config{cc}" ) $(perl -MExtUtils::Embed -e ccopts) foo.c -o foo

    xx $( perl -MConfig -e "print $Config{cc}" ) $(perl -MExtUtils::Embed -e ccopts) -c bar.c -o bar.o

=for future-documentation
	xx $( perl -MConfig -e "print $Config{ld}" ) $("perl -MExtUtils::Embed -e ldopts 2>nul") bar.o

=cut

use strict;
use warnings;

# VERSION: major.minor.release[.build]]  { minor is ODD => alpha/beta/experimental; minor is EVEN => stable/release }
# generate VERSION from $Version$ SCS tag
# $defaultVERSION 	:: used to make the VERSION code resilient vs missing keyword expansion
# $generate_alphas	:: 0 => generate normal versions; true/non-0 => generate alpha version strings for ODD numbered minor versions
use version qw(); our $VERSION; { my $defaultVERSION = '0.5'; my $generate_alphas = 0; $VERSION = ( $defaultVERSION, qw( $Version$ ))[-2]; if ($generate_alphas) { $VERSION =~ /(\d+)\.(\d+)\.(\d+)(?:\.)?(.*)/; $VERSION = $1.'.'.$2.((!$4&&($2%2))?'_':'.').$3.($4?((($2%2)?'_':'.').$4):q{}); $VERSION = version::qv( $VERSION ); }; } ## no critic ( ProhibitCallsToUnexportedSubs ProhibitCaptureWithoutTest ProhibitNoisyQuotes ProhibitMixedCaseVars ProhibitMagicNumbers)

use Pod::Usage;

use Carp::Assert;

use FindBin;	## NOCPAN :: BEGIN used in FindBin, so incompatible with any other modules using it; !!!: don't use within any CPAN package/module that will be 'use'd or 'require'd by other code [ok for executables] (does another way exist using File::Spec rel2abs()??); ??? any problem with this since it's not loaded and only calls outside executables

use ExtUtils::MakeMaker;

#-- config
#my %fields = ( 'quotes' => qq("'`), 'seperators' => qq(:,=) );	#"

use Win32::CommandLine;

@ARGV = Win32::CommandLine::argv( { dosify => 'true', dosquote => 'true' } );	# if eval { require Win32::CommandLine; }; ## depends on Win32::CommandLine so we want the error if its missing or unable to load

#-- getopt
use Getopt::Long qw(:config bundling bundling_override gnu_compat no_getopt_compat no_permute pass_through); ##	# no_permute/pass_through to parse all args up to 1st unrecognized or non-arg or '--'
my %ARGV = ();
# NOTE: the 'source' option '-s' is bundled into the 'echo' option since 'source' is exactly the same as 'echo' to the internal perl script. Sourcing is done by the wrapping .bat script by executing the output of the perl script.
GetOptions (\%ARGV, 'echo|e|s', 'so', 'args|a', 'help|h|?|usage', 'man', 'version|ver|v') or pod2usage(2);
#Getopt::Long::VersionMessage() if $ARGV{'version'};
pod2usage({-verbose => 99, -sections => '', -message => (File::Spec->splitpath($0))[2].qq{ v$::VERSION}}) if $ARGV{'version'};
pod2usage(1) if $ARGV{'help'};
pod2usage({-verbose => 2}) if $ARGV{'man'};

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
	if ($ARGV{echo} ) { print join(" ",@ARGV); } else { if ($ARGV{so}) { my $x = join(" ",@ARGV); print `$x`; exit($? >> 8);} else { exit((system @ARGV) >> 8); }}
	}

__END__
:endofperl
