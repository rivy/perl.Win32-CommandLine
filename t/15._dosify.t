#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

# use lib "t/lib";
use Test::More;
use Test::Differences;

my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; }; # (should be AFTER any plan skip_all ...)

# use lib qw{ lib blib/lib blib/arch };

use Win32::CommandLine;

local $| = 1;     # autoflush for warnings to be in sequence with regular output

sub add_test;
sub test_num;
sub do_tests;

# Tests

## accumulate tests

add_test( [ q{} ], [ q{} ] );
add_test( [ q{argument} ], [ q/argument/ ] );
add_test( [ q{space within} ], [ q/"space within"/ ] );
add_test( [ q{postspace  } ], [ q/"postspace  "/ ] );
add_test( [ q{ prespace} ], [ q/" prespace"/ ] );
add_test( [ q{ arg1}, qq{arg2} ], [ q/" arg1"/, q/arg2/ ] );
add_test( [ q{arg"} ], [ q/"arg\""/ ] );
add_test( [ q{special_char&} ], [ q/"special_char&"/ ] );
add_test( [ q{special_char|within} ], [ q/"special_char|within"/ ] );
add_test( [ q{back_slash\within} ], [ q.back_slash\within. ] );
add_test( [ q{forward_slash/within} ], [ q.forward_slash\within. ] );
add_test( [ q{special<and>\back_slashes\within} ], [ q."special<and>\back_slashes\within". ] );
add_test( [ q{special<and>/forward_slashes/within} ], [ q."special<and>\forward_slashes\within". ] );
add_test( [ q{\\leading_back_slash} ], [ q.\\leading_back_slash. ] );
add_test( [ q{/leading_forward_slash} ], [ q.\\leading_forward_slash. ] );
add_test( [ q{trailing_back_slash\\} ], [ q.trailing_back_slash\\. ] );
add_test( [ q{trailing_forward_slash/} ], [ q.trailing_forward_slash\\. ] );
add_test( [ q{\\multiple\\back\\\\slashes\\} ], [ q.\\multiple\\back\\\\slashes\\. ] );
add_test( [ q{//multiple/forward//slashes/} ], [ q.\\\\multiple\\forward\\\\slashes\\. ] );

## do tests

#plan tests => test_num() + ($Test::NoWarnings::VERSION ? 1 : 0);
plan tests => (test_num() * 5) + ($haveTestNoWarnings ? 1 : 0);

do_tests();

##
my @tests;
sub add_test { push @tests, \@_; return; }
sub test_num { return scalar(@tests); }
## no critic (Subroutines::ProtectPrivateSubs)
sub do_tests {
    my $sub_name = '_dosify';
    my $sub_ref = \&{"Win32::CommandLine::${sub_name}"};
    foreach my $t (@tests) {
        my $arg_ref = shift @{$t};
        my $exp_ref = shift @{$t};
        # my $opt_ref = shift @{$t};

        my $arg_opt_ref;
        $arg_opt_ref = pop @{$arg_ref} if ( @{$arg_ref} && (ref($arg_ref->[-1]) eq 'HASH'));
        my $arg_opt_dump = ($arg_opt_ref ? ';{'.join(",",map { "$_ => ".$arg_opt_ref->{$_}} keys %{$arg_opt_ref}).'}': '');

        my @arg = @{$arg_ref};
        my @exp = @{$exp_ref};

        my $arg = $arg[0];
        my $got_scalar_to_scalar = $arg; $got_scalar_to_scalar = $arg_opt_ref ? $sub_ref->($got_scalar_to_scalar, $arg_opt_ref) : $sub_ref->($got_scalar_to_scalar);
        my $got_scalar_to_void = $arg; $arg_opt_ref ? $sub_ref->($got_scalar_to_void, $arg_opt_ref) : $sub_ref->($got_scalar_to_void);
        # $_ = $arg[0];
        # my @got_void_to_list = $arg_opt_ref ? $sub_ref->($_, $arg_opt_ref) : $sub_ref->();
        # $_ = $arg[0];
        # my $got_void_to_scalar = $arg_opt_ref ? $sub_ref->($_, $arg_opt_ref) : $sub_ref->();
        # $sub_ref->(); ## void_to_void => fails
        eq_or_diff $got_scalar_to_scalar, $exp[0], "testing \$ = `${sub_name}(${arg}${arg_opt_dump})`";
        eq_or_diff $got_scalar_to_void, $exp[0], "testing `${sub_name}(${arg}${arg_opt_dump})`";
        # eq_or_diff @got_void_to_list, [$exp[0]], "testing `\@ = ${sub_name}(${arg_opt_dump})`";
        # eq_or_diff $got_void_to_scalar, $exp[0], "testing `\$ = ${sub_name}(${arg_opt_dump})`";

        my $got_list_to_scalar = $arg_opt_ref ? $sub_ref->(@arg, $arg_opt_ref) : $sub_ref->(@arg);
        my @got_list_to_list = $arg_opt_ref ? $sub_ref->(@arg, $arg_opt_ref) : $sub_ref->(@arg);
        my @got_list_to_void = @arg; $arg_opt_ref ? $sub_ref->(@got_list_to_void, $arg_opt_ref) : $sub_ref->(@got_list_to_void);
        eq_or_diff $got_list_to_scalar, "@exp", "testing \$ = `${sub_name}(\@${arg_opt_dump})`";
        eq_or_diff \@got_list_to_list, \@exp, "testing \@ = `${sub_name}(\@${arg_opt_dump})`";
        eq_or_diff \@got_list_to_void, \@exp, "testing `${sub_name}(\@${arg_opt_dump})`";
        }
    return;
}
