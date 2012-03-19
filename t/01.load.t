#!perl -w  -- -*- tab-width: 4; mode: perl -*-

# t/00.load.t - check module loading

# ToDO: Modify untaint() to allow UNDEF argument(s) [needs to be changed across all tests]

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering (enable autoflush) on STDIN, STDOUT, and STDERR (keeps output in order)
}

# untaint
if (defined($ENV{_BUILD_module_name})) { untaint( $ENV{_BUILD_module_name} ); }

use Test::More tests => 1;

SKIP: {
	my $message = 'Missing $ENV{_BUILD_module_name}';
	if (!defined($ENV{_BUILD_module_name})) {
		diag $message;
		skip $message, 1;
		}
	use_ok( $ENV{_BUILD_module_name} );
	}

diag( (defined($ENV{_BUILD_module_name}) ? qq{$ENV{_BUILD_module_name}, }:q{}) . "$^O, perl v$], $^X");


#### SUBs ---------------------------------------------------------------------------------------##


sub _is_const { my $isVariable = eval { ($_[0]) = $_[0]; 1; }; return !$isVariable; }

sub untaint {
	# untaint( $|@ ): returns $|@
	# RETval: variable with taint removed

	# BLINDLY untaint input variables
	# URLref: [Favorite method of untainting] http://www.perlmonks.org/?node_id=516577
	# URLref: [Intro to Perl's Taint Mode] http://www.webreference.com/programming/perl/taint

	use Carp;

    my $me = (caller(0))[3];
    if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me.'($_) instead?)'; return; }
    if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

    my $arg_ref;
    $arg_ref = \@_;
    $arg_ref = [ @_ ] if defined wantarray; 	## no critic (ProhibitPostfixControls) 	## break aliasing if non-void return context

    for my $arg ( @{$arg_ref} ) {
		if (defined($arg)) {
			if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
			$arg = ( $arg =~ m/\A(.*)\z/msx ) ? $1 : undef;
			}
        }

    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
    }
