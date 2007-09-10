#!perl -w   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;

eval { require Test::Kwalitee; };

plan skip_all => 'Test::Kwalitee only run for author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR};

plan skip_all => 'Test::Kwalitee not installed; skipping CPANTS kwalitee tests' if $@;

#Test::Kwalitee->import( tests => [ qw( use_strict has_tests ) ] );						# import specific kwalitee tests
#Test::Kwalitee->import( tests => [ qw( -has_test_pod -has_test_pod_coverage ) ] );		# disable specific kwalitee tests
Test::Kwalitee->import();																# all kwalitee tests
