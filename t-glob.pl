#!perl -w
#tab:4

use strict;
use warnings;

use File::Glob;
use File::DosGlob;

use lib qw{ lib blib/arch };
use Win32::CommandLine ();

$| = 1;     # autoflush for warnings to be in sequence with regular output

@ARGV = Win32::CommandLine::argv() if eval { require Win32::CommandLine; };

foreach (@ARGV)
    {
    print "`$_`\n";
    }
