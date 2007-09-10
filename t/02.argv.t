#!perl -w   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Test::Differences;
eval { require Test::NoWarnings; import Test::NoWarnings; };

use lib qw{ lib blib/arch };

use Win32::CommandLine;

sub add_test;
sub test_num;
sub do_tests;

# Tests

## accumulate tests

add_test( qq{$0}, qw( ) );

add_test( qq{ $0}, qw( ) );

add_test( qq{$0 }, qw( ) );

add_test( qq{ $0 }, qw( ) );

add_test( qq{ a }, qw( ) );

add_test( qq{ a b c }, qw( ) );

add_test( qq{ a 'b' c }, qw( ) );

add_test( qq{$0 a b c}, qw( a b c ) );

add_test( qq{$0 "a b" c}, ( "a b", "c" ) );

add_test( qq{$0 'a b' c'' }, ( "a b", "c" ) );

add_test( qq{$0 "a b" c"" }, ( "a b", "c" ) );

add_test( qq{$0 "a b" c""d }, ( "a b", "cd" ) );

add_test( qq{$0 'a b" c'}, ( qq{a b" c} ) );

add_test( qq{$0 'a bb" c'}, ( qq{a bb" c} ) );

add_test( qq{$0 \$'test'}, ( qq{test} ) );

add_test( qq{$0 \$'\\x34\\x34'}, ( qq{44} ) );

add_test( qq{$0 \*.t}, ( q{*.t} ) );

#add_test( qq{$0 '*.t}, ( q{*.t} ) );   # exception: unbalanced quotes

add_test( qq{$0 a b c \*.t}, ( qw{a b c}, q{*.t} ) );

add_test( qq{$0 a b c t/\*.t}, ( qw{a b c}, glob('t/*.t') ) );

add_test( qq{$0 a t/\*.t b}, ( "a", glob('t/*.t'), "b" ) );

add_test( qq{$0 t/\"*".t}, ( glob('t/*.t') ) );

add_test( qq{$0 t/\'*'.t}, ( q{t/*.t} ) );

add_test( qq{$0 t/{0}\*.t}, ( glob('t/{0}*.t') ) );

add_test( qq{$0 t/{0,}\*.t}, ( glob('t/{0,}*.t') ) );

add_test( qq{$0 t/{0,p}\*.t}, ( glob('t/{0,p}*.t') ) );

add_test( qq{$0 t/\{0,t,p\}\*.t}, ( glob('t/{0,t,p}*.t') ) );

add_test( qq{$0 t/\{t,p,0\}\*.t}, ( glob('t/{t,p,0}*.t') ) );

add_test( qq{$0 t/\*}, ( glob('t/*') ) );

add_test( qq{$0 't\*'}, ( qw{t*} ) );

## do tests

plan tests => test_num() + ($Test::NoWarnings::VERSION ? 1 : 0);

do_tests(); # test re-parsing of command_line() by argv()

##
my @tests;
sub add_test { push @tests, \@_; return; }
sub test_num { return scalar(@tests); }
## no critic (Subroutines::ProtectPrivateSubs)
sub do_tests { foreach my $t (@tests) { my $cl = shift @{$t}; my @exp = @{$t}; my @got = Win32::CommandLine::_argv($cl); eq_or_diff \@got, \@exp, "testing _argv parse: `$cl`"; } return; }
