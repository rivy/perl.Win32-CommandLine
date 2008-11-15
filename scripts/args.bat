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

# args <command> <arg(s)>
# showed command line and parsed <arg(s)> (currently the <arg(s)> ready to be pushed off to CreateProcess() for execution, change when options are implemented)

# TODO: command line options
#
#	-a:<int(s)>	show args (optional list of ints listing arg numbers to show [0] = command name, ... [ranges are possible and no errors are generated for missing arg(s) at intN]
#	-c 	show command_line
#	-p	show final <arg(s)> just before handoff to CreateProcess() (currently the default, change when options are implemented)
#	-v	verbose = label output "command_line() = ..." and "$ARGV[0] = ..."

# a .bat file to work around Win32 I/O redirection bugs with execution of '.pl' files via the standard Win32 filename extension execution mechanism (see documentation for pl2bat [ADVANTAGES, specifically Method 5] for further explanation)
# see linux 'xargs' command for something similar
# FIXED (for echo): note: command line args are dequoted so commands taking string arguments and expecting them quoted might not work exactly the same (eg, echo 'a s' => 'a s' vs x echo 'a s' => "a s")
#	NOTE: using $"<string>" => "<string>" quote preservation behavior can overcome this issue (eg, x perl -e $"print 'test'")
#		[??] $"<string>" under bash ignores the $ if C or POSIX locale in force, and only leaves string qq'd if translated to another locale
#	NOTE: or use another method to preserve quotes for appropriate commands (such as "'"'<string'"'" (noisy but it works)

use strict;
use warnings;

# VERSION: major.minor.revision[.build]]  { minor is ODD = alpha/beta/experimental; minor is EVEN = release }
# generate VERSION from $Version$ SCS tag
# $defaultVERSION 	:: used to make the VERSION code resilient vs missing keyword expansion
# $generate_alphas	:: 0 => generate normal versions; true/non-0 => generate alpha version strings for ODD numbered minor versions
use version qw(); our $VERSION; { my $defaultVERSION = '0.1.0'; my $generate_alphas = "true"; $VERSION = qw( $defaultVERSION $Version$ )[-2]; if ($generate_alphas) { $VERSION =~ /(\d+)\.(\d+)\.(\d+)(?:\.)?(.*)/; $VERSION = $1.'.'.$2.((!$4&&($2%2))?'_':'.').$3.($4?((($2%2)?'_':'.').$4):''); $VERSION = version::qv( $VERSION ); }; } ## no critic ( ProhibitCallsToUnexportedSubs ProhibitCaptureWithoutTest ProhibitNoisyQuotes )

@ARGV = Win32::CommandLine::argv() if eval { require Win32::CommandLine; };

my $cl = Win32::CommandLine::command_line();
print 'command_line()'." = '$cl'\n";
#
#for (my $i = 0; $i < @ARGV; $i++) { print '$ARGV'."[$i] = '$ARGV[$i]'\n"; }
#print "====\n";

# unfortunately the args (which are correct here) are reparsed while going to the target command through CreateProcess() (PERL BUG: despite explicit documentation in PERL that system bypasses the shell and goes directly to execvp() for scalar(@ARGV) > 1 although there is no obvious work around since execvp() doesn't really exist in Win32 and must be emulated through CreateProcess())
# so, protect the ARGs from CreateProcess() reparsing destruction
# echo is a special case (it must get it's command line directly, skipping the ARGV reparsed arguments of CreateProcess()... so check and don't re-escape quotes) for 'echo'
## checking for echo is a bit complicated any command starting with echo followed by a . or whitespace is treated as an internal echo command unless a file exists which matches the entire 1st argument, then it is executed instead
if (!-e $ARGV[0] || !$ARGV[0] =~ m/^echo(.|\s)/)
	{ ## protect internal ARGV double quotes by escaping them and surrounding the ARGV with another set of double quotes
	for (1..$#ARGV) {$ARGV[$_] =~ s/\"/\\\"/g; $ARGV[$_] = '"'.$ARGV[$_].'"'}
	}

for (my $i = 0; $i < @ARGV; $i++) { print '$ARGV'."[$i] = '$ARGV[$i]'\n"; }

#system { $ARGV[0] } @ARGV;		# doesn't see "echo" as a command (?? problem for all CMD built-ins?)
#system @ARGV;

__END__
:endofperl
