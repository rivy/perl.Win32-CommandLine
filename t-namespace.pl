#!perl -w
#tab:4

use strict;
use warnings;

use File::Glob;
use File::DosGlob;

use lib qw{ lib blib/arch };
use Win32::CommandLine ();

print "==1=\n";
print join ("\n", grep { /^(?!isa|bootstrap|dl_load_flags|qv)[^_][a-zA-Z_]*[a-z]+[a-zA-Z_]*$/ } keys %Win32::CommandLine::);
print "\n";

print "==2=\n";
print join ("\n", keys %Win32::CommandLine::);
print "\n";
#
#print "==3=\n";
#my @a = keys %Win32::CommandLine::;
#print ":@a:\n";
