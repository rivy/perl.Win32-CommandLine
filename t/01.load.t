#!perl -w   -*- tab-width: 4; mode: perl -*-

# t/00.load.t - check module loading

use strict;
use warnings;

use Test::More tests => 1;
BEGIN {
    use_ok( 'Win32::CommandLine' );
}
