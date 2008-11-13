#!perl -wT   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;
my $haveTestPod = eval { use Test::Pod 1.14; 1; };
plan skip_all => "Test::Pod 1.14 required for testing POD" if !$haveTestPod;
#all_pod_coverage_ok();
all_pod_files_ok( all_pod_files(qw( . )) );
