#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

#use lib 't/lib';
use Test::More;
use Test::Differences;
my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; };

#plan skip_all => 'Tilde tests are highly configuration dependent [to run: set TEST_FRAGILE]' unless $ENV{TEST_FRAGILE} or $ENV{TEST_ALL};

if ( !$ENV{HARNESS_ACTIVE} ) {
	# not executing under Test::Harness
	use lib qw{ lib };		# for ease of testing from command line and testing immediacy, use the 'lib' version (so 'blib/arch' version doesn't have to be updated 1st)
	}

use Win32::CommandLine;

sub add_test;
sub test_num;
sub do_tests;

# Tests

## accumulate tests

if ($ENV{TEST_FRAGILE} or ($ENV{TEST_ALL} and (defined $ENV{TEST_FRAGILE} and $ENV{TEST_FRAGILE}))) {
	##
	## TODO: this is really not a fair test on all computers unless we make sure the specific account(s) exist and know what the expansion should be...
	## use TEST_FRAGILE
	add_test( [ qq{$0 ~*} ], ( q{~*} ) );
	add_test( [ qq{$0 ~} ], ( q{C:/Documents and Settings/Administrator} ) );
	add_test( [ qq{$0 ~ ~administrator} ], ( q{C:/Documents and Settings/Administrator}, q{C:/Documents and Settings/Administrator} ) );
	add_test( [ qq{$0 ~administrator/} ], ( q{C:/Documents and Settings/Administrator/} ) );
	add_test( [ qq{$0 x ~administrator\\ x} ], ( 'x', q{C:/Documents and Settings/Administrator/}, 'x' ) );
	add_test( [ qq{$0 ~ ~Administrator} ], ( q{C:/Documents and Settings/Administrator}, q{C:/Documents and Settings/Administrator} ) );
	add_test( [ qq{$0 ~ ~ADMINistrator} ], ( q{C:/Documents and Settings/Administrator}, q{C:/Documents and Settings/Administrator} ) );
	add_test( [ qq{$0 ~ ~ADMINISTRATOR} ], ( q{C:/Documents and Settings/Administrator}, q{C:/Documents and Settings/Administrator} ) );
	##
	}

## TODO: check for correct expansion of ~ to "%USERPROFILE" { note: this could be fragile, if ~ is defined as something else or if there is some asynchrony between %userprofile% and the registry (( can this happen? or is %userprofile% set from the registry? prob could happen if the registry is changed after the shell is started... ))
	## unset ~ before checking

## TODO: add ENV variable "~x" and check for correct expansion



## TODO: check both with and without nullglob, including using %opts for argv()
add_test( [ qq{$0 foo\\bar}, { nullglob => 0 } ], ( q{foo\\bar} ) );

## do tests

$ENV{nullglob} = 0;	# setup a known environment

#plan tests => test_num() + ($Test::NoWarnings::VERSION ? 1 : 0);
plan tests => test_num() + ($haveTestNoWarnings ? 1 : 0);

do_tests(); # test re-parsing of command_line() by argv()
##
my @tests;
sub add_test { push @tests, [ (caller(0))[2], @_ ]; return; }		## NOTE: caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
sub test_num { return scalar(@tests); }
## no critic (Subroutines::ProtectPrivateSubs)
sub do_tests { foreach my $t (@tests) { my $line = shift @{$t}; my @args = @{shift @{$t}}; my @exp = @{$t}; my @got; eval { @got = Win32::CommandLine::_argv(@args); 1; } or ( @got = ( $@ =~ /^(.*)\s+at.*$/ ) ); eq_or_diff \@got, \@exp, "[line:$line] testing: `@args`"; } return; }
