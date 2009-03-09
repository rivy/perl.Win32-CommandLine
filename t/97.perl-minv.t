#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{AUTOMATED_TESTING} or $ENV{TEST_AUTHOR} or $ENV{TEST_RELEASE} or $ENV{TEST_ALL};

my @modules = ( 'Test::MinimumVersion 0.008' );
my $haveRequired = 1;
foreach (@modules) { if (!eval "use $_; 1;") { $haveRequired = 0; diag("$_ is not available");} }	## no critic (ProhibitStringyEval)

plan skip_all => '[ '.join(', ',@modules).' ] required for testing' if !$haveRequired;

all_minimum_version_from_metayml_ok();

#to find hints for specific versions: perl -MPerl::MinimumVersion -e "$pmv = Perl::MinimumVersion->new( 'lib/<NAME.pm>' ); @m=$pmv->version_markers(); for ($i = 0; $i<(@m/2); $i++) {print qq{$m[$i*2] = { @{$m[$i*2+1]} }\n};}

#FROM Test-SubCalls-1.08
##!/usr/bin/perl
#
## Test that our declared minimum Perl version matches our syntax
#
#use strict;
#BEGIN {
#	$|  = 1;
#	$^W = 1;
#}
#
#my $MODULE = 'Test::MinimumVersion 0.008';
#
## Don't run tests for installs
#use Test::More;
#unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
#	plan( skip_all => "Author tests not required for installation" );
#}
#
## Load the testing module
#eval "use $MODULE";
#if ( $@ ) {
#	$ENV{RELEASE_TESTING}
#	? die( "Failed to load required release-testing module $MODULE" )
#	: plan( skip_all => "$MODULE not available for testing" );
#}
#
#all_minimum_version_from_metayml_ok();