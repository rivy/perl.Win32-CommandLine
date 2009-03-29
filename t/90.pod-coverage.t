#!perl -wT   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

my $haveTestPodCoverage = eval { require Test::Pod::Coverage 1.04; 1; };
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' if !$haveTestPodCoverage;

all_pod_coverage_ok();
