#!perl -w   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More tests => 3;

use lib qw{ lib blib/arch };

# Tests

require_ok('Win32::CommandLine');
Win32::CommandLine->import( qw( command_line ) );

my $zero = quotemeta $0;
my $string = command_line();
print "command_line = $string\n";
ok($string =~ /.*perl.*$zero.*/, "command_line() returned {matches /.*perl.*\$0.*/}");

my @argv2 = Win32::CommandLine::argv();
print "ARGV[$#ARGV] = {".join(':',@ARGV)."}\n";
print "argv2[$#argv2] = {".join(':',@argv2)."}\n";
ok($#argv2 < 0, "successful command_line() reparse; ARGV has no args");
