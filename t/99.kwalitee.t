#!perl -w   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

my $haveTestKwalitee = eval { require Test::Kwalitee; 1; };

plan skip_all => 'Test::Kwalitee required to test CPANTS kwalitee' if !$haveTestKwalitee;

#Test::Kwalitee->import( tests => [ qw( use_strict has_tests ) ] );						# import specific kwalitee tests
#Test::Kwalitee->import( tests => [ qw( -has_test_pod -has_test_pod_coverage ) ] );		# disable specific kwalitee tests
Test::Kwalitee->import();																# all kwalitee tests
