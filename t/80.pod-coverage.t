#!perl -wT   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;
my $haveTestPodCoverage = eval { use Test::Pod::Coverage 1.04; 1; };
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' if !$haveTestPodCoverage;
all_pod_coverage_ok();
