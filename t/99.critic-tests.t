#!perl -w   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;

##-- config
my %config;
#$config{-top} = 10; 		# limit number of criricisms to top <N> criticisms
$config{-severity} = 3;		# [ 5 = gentle, 4 = stern, 3 = harsh, 2 = cruel, 1 = brutal ]
$config{-exclude} = [ qw( CodeLayout::ProhibitHardTabs RegularExpressions::RequireExtendedFormatting Subroutines::RequireArgUnpacking Miscellanea::RequireRcsKeywords ) ];
$config{-verbose} = '[%l:%c]: (%p; Severity: %s) %m. %e. ';
##

my $haveTestPerlCritic = eval {	require Test::Perl::Critic;	import Test::Perl::Critic ( %config );	1; };

plan skip_all => 'Test::Perl::Critic only run for author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR};

plan skip_all => 'Test::Perl::Critic required to criticize code' if !$haveTestPerlCritic;

my @files = glob('t/*.t');

plan tests => $#files+1;

for my $file (@files) { critic_ok( $file ); };

