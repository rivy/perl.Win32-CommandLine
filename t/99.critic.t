#!perl -w   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;

##-- config
my %config;
#$config{-top} = 10;        # limit number of criricisms to top <N> criticisms
#$config{-severity} = 1;     # [ 5 = gentle, 4 = stern, 3 = harsh, 2 = cruel, 1 = brutal ]
#$config{-exclude} = [ qw( CodeLayout::RequireTidyCode CodeLayout::ProhibitHardTabs CodeLayout::ProhibitParensWithBuiltins Documentation::RequirePodAtEnd RegularExpressions::RequireExtendedFormatting RegularExpressions::RequireLineBoundaryMatching Miscellanea::RequireRcsKeywords ControlStructures::ProhibitPostfixControls Subroutines::RequireArgUnpacking Variables::RequireLocalizedPunctuationVars ) ];
$config{-severity} = 1;     # [ 5 = gentle, 4 = stern, 3 = harsh, 2 = cruel, 1 = brutal ]
$config{-exclude} = [ qw( CodeLayout::RequireTidyCode CodeLayout::ProhibitHardTabs CodeLayout::ProhibitParensWithBuiltins ControlStructures::ProhibitPostfixControls Documentation::RequirePodAtEnd ) ];
$config{-verbose} = '[%l:%c]: (%p; Severity: %s) %m. %e. ';
##

my $haveTestPerlCritic = eval { require Test::Perl::Critic; import Test::Perl::Critic ( %config ); 1; };

plan skip_all => 'Test::Perl::Critic only run for author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR};

#plan skip_all => 'Test::Perl::Critic required to criticize code' if $@;
plan skip_all => 'Test::Perl::Critic required to criticize code' if !$haveTestPerlCritic;

all_critic_ok('lib');
#all_critic_ok('lib', 'blib');
#all_critic_ok('blib', 't');
#all_critic_ok();

