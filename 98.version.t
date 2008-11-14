#!perl -w   -*- tab-width: 4; mode: perl -*-

# check for CPAN/PAUSE parsable VERSIONs ( URLref: http://cpan.org/modules/04pause.html )
#
#

use strict;
use warnings;

#use Test::More;
use Cwd;

#my $haveExtUtilsMakeMaker = eval { require ExtUtils::MakeMaker; 1; };
use ExtUtils::MakeMaker;

my @files = ( '.\lib\Win32\Command.pm' );

print cwd();

#plan skip_all => '(ExtUtils::MakeMaker) Author tests, not required for installation [To run test(s): set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR};

#plan skip_all => 'ExtUtils::MakeMaker required to check code versioning' if !$haveExtUtilsMakeMaker;

#plan tests => scalar( @files );

#isnt( MM->parse_version($_), undef, "Has ExtUtils::MakeMaker parsable version") for @files;
MM->parse_version($_) for @files;
