#!perl -w  -- -*- tab-width: 4; mode: perl -*-

# check that CPAN/PAUSE parsable VERSIONs have correctly corresponding default versions

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering on STDIN, STDOUT, and STDERR
}

# untaint
if (defined($ENV{_BUILD_versioned_file_globs})) { untaint( $ENV{_BUILD_versioned_file_globs} ); }

use English qw( -no_match_vars ); ##	# long Perl built-on variable names ['-no_match_vars' avoids regex performance penalty]

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

my $haveExtUtilsMakeMaker = eval { require ExtUtils::MakeMaker; 1; };

my @files = ( map { glob $_ } split(/;/, $ENV{_BUILD_versioned_file_globs}) );

plan skip_all => 'ExtUtils::MakeMaker required to check code versioning' if !$haveExtUtilsMakeMaker;

plan tests => scalar( @files ) * 3 + 1;

ok( (scalar(@files) > 0), "Found ".scalar(@files)." files to check");

for (@files) {
	my $defaultV = parse_default_version($_);
	SKIP: {
	    my $message = qq{"$_" has no parsable \$defaultVERSION};
		if (!defined($defaultV)) {
			diag $message;
			skip $message, 1;
			}
		ok( (version_non_alpha_form($defaultV) =~ /[0-9]+\.[0-9]+/), qq{"$_" has at least M.m default version});
		};
	}

ok( (index (version_non_alpha_form(MM_parse_version($_)), version_non_alpha_form(parse_default_version($_))) == 0), qq{"$_" has default version which is a subset prefix of it's ExtUtils::MakeMaker version}) for @files;

is( is_alpha_version(MM_parse_version($_)), is_alpha_version(parse_default_version($_)), qq{"$_" has correct correspondance of alpha/release versions between default and ExtUtils::MakeMaker version}) for @files;

#-----------------------------------------------------------------------------

use Carp;		# included with perl [?version]

sub MM_parse_version {
	## MM_parse_version( $ ): returns $
	# detainted version of MM->parse_version
	# Bypass taint failure in MM->parse_version when called directly with active taint-mode
	# NOTE: MM->parse_version() has EVAL taint failure ("Insecure dependency in eval while running with -T switch at c:/strawberry/perl/lib/ExtUtils/MM_Unix.pm line 2663, <$fh> line 43.")
	# ToDO: ask about this on PerlMonks; this seems kludgy
	my ($file) = shift;

	use ExtUtils::MakeMaker;
	use Probe::Perl;

	my $perl = Probe::Perl->find_perl_interpreter;

	untaint( $perl );
	$file =~ s:\\\\:\\:g;
	$file =~ s:\\:\/:g;
	untaint( $file );

	my $v = `$perl -MExtUtils::MakeMaker -e "print MM->parse_version(q{$file})"`;  		## no critic ( ProhibitBacktickOperators ) ## ToDO: revisit/remove

	return $v;
	}

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
		if (!defined($v)) { $v = q{}; }
		$v =~ s/_/./g; # replace interior '_' with '.'
		}

	return wantarray ? @{$v_ref} : "@{$v_ref}";
}

sub version_mmr
{ ## version_mmr( $ [,\%] ): returns $|@ ['shortcut' function]
	# version_mmr( $version )
	#
	# transform $version into <major>.<minor>.<release> form
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

	if (!defined($version)) { $version = q{}; }
	if ($version =~ /_/) { $is_in_alpha_form = "true"; };

	return $is_in_alpha_form;
}

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
