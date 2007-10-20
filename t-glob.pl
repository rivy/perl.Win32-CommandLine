#!perl -w   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

#use File::Glob;
#use File::DosGlob;

use lib qw{ lib blib/arch };
use Win32::CommandLine qw( command_line parse );

$| = 1;     # autoflush for warnings to be in sequence with regular output

#@ARGV = Win32::CommandLine::argv() if eval { require Win32::CommandLine; };

print "<nullglob = 0>\n";
@ARGV = parse( command_line(), { 'nullglob' => 0 } );     # get commandline and reparse it returning the new ARGV array
foreach (@ARGV)
    {
    print "`$_`\n";
    }

print "<nullglob = 1>\n";
@ARGV = parse( command_line(), { 'nullglob' => 1 } );     # get commandline and reparse it returning the new ARGV array
foreach (@ARGV)
    {
    print "`$_`\n";
    }
