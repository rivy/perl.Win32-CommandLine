#!perl -w   -*- tab-width: 4; mode: perl -*-

# check that CPAN/PAUSE parsable VERSIONs have correctly corresponding default versions

use strict;
use warnings;

use English qw( -no_match_vars ); ##	# long Perl built-on variable names ['-no_match_vars' avoids regex performance penalty]

use Test::More;

my $haveExtUtilsMakeMaker = eval { require ExtUtils::MakeMaker; 1; };
use ExtUtils::MakeMaker;

my @files = ( '.\lib\Win32\CommandLine.pm' );

#print cwd();

plan skip_all => '(ExtUtils::MakeMaker) Author tests, not required for installation [To run test(s): set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

plan skip_all => 'ExtUtils::MakeMaker required to check code versioning' if !$haveExtUtilsMakeMaker;

plan tests => scalar( @files ) * 2 ;

is( version_mmr(version_non_alpha_form(MM->parse_version($_))), version_mmr(version_non_alpha_form(parse_default_version($_))), "'$_' has equal ExtUtils::MakeMaker and default versions [MMR]") for @files;
is( is_alpha_version(MM->parse_version($_)), is_alpha_version(parse_default_version($_)), "'$_' has correct correspondance of alpha/release versions") for @files;

#-----------------------------------------------------------------------------

sub parse_default_version
{ ## parse_default_version( $ [,\%] ): returns $
	# parse_default_version( $file ): returns $default_v
	#
	# parse $file for any defined default version string and return it (undef if missing)

	my ($file) = @_;

	my $default_v = undef;

	my $comment_only_re = qr{^\s*#};
	my $extutils_version_re = qr{(?<!\\)([\$*])(([\w\:\']*)\bVERSION)\b.*\=};							# from ExtUtils::MM_Unix.pm	(v6.48)
	my $default_equals_re = qr{\s*\$defaultVERSION\s*=\s*['"]?([0-9._]+?)["']?\s*;};
	my $default_inarray_re = qr{\s*\$VERSION\s*=\s*qw\s*\(.*?['"]?([0-9._]+)["']?.*?\)\s*\[\s*\S+\s*\]\s*;};	## no critic (ProhibitComplexRegexes)
#	my $VERSION_equals_re = qr{\s*\$VERSION\s*=\s*['"](v|V)?([0-9._]+)["']\s*;}; 	# ?? does this need a leading possible v for completeness (and possible capitalization)
	my $VERSION_equals_re = qr{\s*\$VERSION\s*=\s*['"]([0-9._]+)["']\s*;};

	open( my $fh, '<', $file ) or die "Can't open '$file': $OS_ERROR\n"; ## no critic ( RequireCarping RequireBriefOpen)
	while ( my $s = <$fh> ) {
		next if $s =~ $comment_only_re;
		next if not $s =~ $extutils_version_re;
		# $s is now an ExtUtils::MakeMaker candidate for $VERSION
		#print $s;
		if ($s =~ $default_equals_re) { $default_v = $1; last; }	# 1st: check for $defaultVERSION = <v>;
		if ($s =~ $default_inarray_re) { $default_v = $1; last; }	# 2nd: check for $VERSION = qw( ... <v> ...);
		last if $s =~ $VERSION_equals_re;							# last: stop looking if we find $VERSION = <v>;
		}
	close $fh;

	return $default_v;
}

sub	_is_const { my $is_const = !eval { ($_[0]) = $_[0]; 1; }; return $is_const; }

sub version_non_alpha_form
{ ## version_non_alpha_form( $ ): returns $|@ ['shortcut' function]
	# version_non_alpha_form( $version )
	#
	# transform $version into non-alpha form
	#
	# NOTE: not able to currently determine the difference between a function call with a zero arg list {"f(());"} and a function call with no arguments {"f();"} => so, by the Principle of Least Surprise, f() in void context is disallowed instead of being an alias of "f($_)" so that f(@array) doesn't silently perform f($_) when @array has zero elements
	# ** use "f($_)" instead of "f()" when needed

	my $me = (caller(0))[3];	## no critic ( ProhibitMagicNumbers )	## caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
	if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me.'($_) instead?)'; return; } ## no critic ( RequireInterpolationOfMetachars ) #
	if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

	my $v_ref;
	$v_ref = \@_;
	$v_ref = [ @_ ] if defined wantarray; ## no critic (ProhibitPostfixControls) #	# break aliasing if non-void return context

	for	my $v ( @{$v_ref} ) {
		if (_is_const($v)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
		$v =~ s/_/./g;	# replace interior '_' with '.'
		}

	return wantarray ? @{$v_ref} : "@{$v_ref}";
}

sub version_mmr
{ ## version_mmr( $ [,\%] ): returns $|@ ['shortcut' function]
	# version_mmr( $version )
	#
	# transform $version into <major>.<minor>.<revision> form
	#
	# assumes $version is a set of numbers intersperced with '.' or '_'
	# returns undef for $version == undef or unparsable as a version string (do allow and ignore leading/trailing whitespace)
	#
	# NOTE: not able to currently determine the difference between a function call with a zero arg list {"f(());"} and a function call with no arguments {"f();"} => so, by the Principle of Least Surprise, f() in void context is disallowed instead of being an alias of "f($_)" so that f(@array) doesn't silently perform f($_) when @array has zero elements
	# ** use "f($_)" instead of "f()" when needed

	my $me = (caller(0))[3];	## no critic ( ProhibitMagicNumbers )	## caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
	if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me.'($_) instead?)'; return; } ## no critic ( RequireInterpolationOfMetachars ) #
	if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

	my $v_ref;
	$v_ref = \@_;
	$v_ref = [ @_ ] if defined wantarray; ## no critic (ProhibitPostfixControls) #	# break aliasing if non-void return context

	my $mmr_re = qr{^\s*(\d+\.\d+\.\d+)(?:\.\d+)*\s*};

	for	my $v ( @{$v_ref} ) {
		if (_is_const($v)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
		my $working_v = $v.'.0.0';		# add enough dotted numbers to make a full M.M.R version (for versions with only <major>.<minor> or just <major> numbers)
		if ($working_v =~ $mmr_re) { $v = $1 } else { $v = undef; }
		}

	return wantarray ? @{$v_ref} : "@{$v_ref}";
}

sub is_alpha_version
{ ## is_alpha_version( $ ): returns $
	# is_alpha_version( $version ): returns $is_in_alpha_form
	my ($version) = @_;

	my $is_in_alpha_form = 0;

	if ($version =~ /_/) { $is_in_alpha_form = "true"; };

	return $is_in_alpha_form;
}
