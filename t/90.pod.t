#!perl -wT   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

my $haveTestPod = eval { require 'Test::Pod 1.14'; 1; };

plan skip_all => "Test::Pod 1.14 required for testing POD" if !$haveTestPod;

#all_pod_coverage_ok();
all_pod_files_ok( all_pod_files(qw( . )) );
