#!perl -wT   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;
my $haveTestPodCoverage = eval { use Test::Pod::Coverage 1.04; 1; };
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' if !$haveTestPodCoverage;
plan skip_all => 'Test::Pod only run for author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};
all_pod_coverage_ok();
