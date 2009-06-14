#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

my $haveTestDistribution = eval { require Test::Distribution; 1; };

plan skip_all => 'Test::Distribution required to run distribution tests' if !$haveTestDistribution;

import Test::Distribution;
