#!perl -wT   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{AUTOMATED_TESTING} or $ENV{TEST_AUTHOR} or $ENV{TEST_RELEASE} or $ENV{TEST_ALL};

my @modules = ( 'Test::CPAN::Meta 0.12' );
my $haveRequired = 1;
foreach (@modules) { if (!eval "require $_; 1;") { $haveRequired = 0; diag("$_ is not available");} }	## no critic (ProhibitStringyEval)

plan skip_all => '[ '.join(', ',@modules).' ] required for testing' if !$haveRequired;

meta_yaml_ok();

#FROM Test-SubCalls-1.08
#!/usr/bin/perl
#
## Test that our META.yml file matches the current specification.
#
#use strict;
#BEGIN {
#	$|  = 1;
#	$^W = 1;
#}
#
#my $MODULE = 'Test::CPAN::Meta 0.12';
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
#meta_yaml_ok();
