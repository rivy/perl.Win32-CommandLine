#!perl -w  -- -*- tab-width: 4; mode: perl -*-
# [no -T]: Test::More EVAL tainted

# t/00.load.t - check module loading

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More tests => 1;

use_ok( $ENV{_BUILD_module_name} );

diag("$ENV{_BUILD_module_name}, $^O, perl v$], $^X");
