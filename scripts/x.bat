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

# x <command> <arg(s)>
# execute <command> with parsed <arg(s)>
# a .bat file to work around Win32 I/O redirection bugs with execution of '.pl' files via the standard Win32 filename extension execution mechanism (see documentation for pl2bat [ADVANTAGES, specifically Method 5] for further explanation)
# see linux 'xargs' command for something similar

use strict;
use warnings;

use version qw(); our $VERSION = version::qv(qw( default-v 0.3 $Version: 0.3.20071001.20342 $ )[-2]);	## no critic ( ProhibitCallsToUnexportedSubs ) ## [NOTE: "default-v 0.1" makes the code resilient vs missing keyword expansion]

@ARGV = Win32::CommandLine::argv() if eval { require Win32::CommandLine; };

#exec { $ARGV[0] } @ARGV;	# doesn't see "echo" as a command
#print "argv = @ARGV\n";

system @ARGV;

#system { $ARGV[0] } @ARGV;

__END__
:endofperl
