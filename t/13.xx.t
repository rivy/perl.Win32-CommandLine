#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;				# included with perl
use Test::Differences;		# included with perl

my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; };

my $haveExtUtilsMakeMaker = eval { require ExtUtils::MakeMaker; 1; };

if ( !$ENV{HARNESS_ACTIVE} ) {
	# not executing under Test::Harness
	use lib qw{ blib/arch };	# only needed for dynamic module loads (eg, compiled XS) [ remove if no XS ]
	use lib qw{ lib };			# use the 'lib' version (for ease of testing from command line and testing immediacy; so 'blib/arch' version doesn't have to be built/updated 1st)
	}

my @modules = ( 'File::Spec', 'IPC::Run3', 'Probe::Perl' );
my $haveRequired = 1;
foreach (@modules) { if (!eval "use $_; 1;") { $haveRequired = 0; diag("$_ is not available");} }	## no critic (ProhibitStringyEval)

plan skip_all => '[ '.join(', ',@modules).' ] required for testing' if !$haveRequired;

sub add_test;
sub test_num;
sub do_tests;

# Tests

# autoflush to keep output in order
my $stdout = select(STDERR);
$|=1;
select($stdout);
$|=1;

#plan tests =>  9 ;
#my $perl = Probe::Perl->find_perl_interpreter;
#my $hello = File::Spec->catfile(qw/t helloworld.pl/);
#my $tee = File::Spec->catfile(qw/scripts ptee/);
#my $tempfh = File::Temp->new;
#my $tempname = $tempfh->filename;
#my ($got_stdout, $got_stderr);
#
#ok( -r $hello,
#    "hello script readable"
#);
#
#ok( -r $tee,
#    "tee script readable"
#);
#
## check direct output of hello world
#run3 "$perl $hello", undef, \$got_stdout, \$got_stderr;
#
#is( $got_stdout, expected("STDOUT"),
#    "hello world program output (direct)"
#);
#
## check output through ptee
#truncate $tempfh, 0;
#run3 "$perl $hello | $perl $tee $tempname", undef, \$got_stdout, \$got_stderr;
#
#is( $got_stdout, expected("STDOUT"),
#    "hello world program output (tee stdout)"
#);
#
#open FH, "< $tempname";
#$got_stdout = do { local $/; <FH> };
#close FH;
#
#is( $got_stdout, expected("STDOUT"),
#    "hello world program output (tee file)"
#);
#
## check appended output
#run3 "$perl $hello | $perl $tee -a $tempname", undef, \$got_stdout, \$got_stderr;
#
#open FH, "< $tempname";
#$got_stdout = do { local $/; <FH> };
#close FH;
#
#is( $got_stdout, expected("STDOUT") x 2,
#    "hello world program output (tee -a)"
#);
#
#run3 "$perl $hello | $perl $tee --append $tempname", undef, \$got_stdout, \$got_stderr;
#
#open FH, "< $tempname" or die "Can't open $tempname for reading";
#
#$got_stdout = do { local $/; <FH> };
#close FH;
#
#is( $got_stdout, expected("STDOUT") x 3,
#    "hello world program output (tee --append)"
#);
#
## check multiple files
#my $temp2 = File::Temp->new;
#truncate $tempfh, 0;
#run3 "$perl $hello | $perl $tee $tempname $temp2", undef, \$got_stdout, \$got_stderr;
#
#open FH, "< $tempname";
#$got_stdout = do { local $/; <FH> };
#close FH;
#
#is( $got_stdout, expected("STDOUT"),
#    "hello world program output (tee file1 file2 [1])"
#);
#
#open FH, "< $temp2";
#$got_stdout = do { local $/; <FH> };
#close FH;
#
#is( $got_stdout, expected("STDOUT"),
#    "hello world program output (tee file1 file2 [2])"
#);

## setup
my $perl = Probe::Perl->find_perl_interpreter;
my $script = File::Spec->catfile( 'bin', 'xx.bat' );

## accumulate tests

# TODO: organize tests, add new tests for 'xx.bat'
if ($haveExtUtilsMakeMaker)
	{# ExtUtilsMakeMaker present
	add_test( [ q{-v} ], ( q{xx.bat v}.MM->parse_version($script) ) );
	}
add_test( [ q{TEST -m "VERSION: update to 0.3.11"} ], ( q{TEST -m "VERSION: update to 0.3.11"} ) );
add_test( [ q{perl -MPerl::MinimumVersion -e "$pmv = Perl::MinimumVersion->new('lib/Win32/CommandLine.pm'); @m=$pmv->version_markers(); for ($i = 0; $i<(@m/2); $i++) {print qq{$m[$i*2] = { @{$m[$i*2+1]} }\n};}"} ], ( q{perl -MPerl::MinimumVersion -e "$pmv = Perl::MinimumVersion->new('lib/Win32/CommandLine.pm'); @m=$pmv->version_markers(); for ($i = 0; $i<(@m/2); $i++) {print qq{$m[$i*2] = { @{$m[$i*2+1]} }\n};}"} ) );
add_test( [ q{perl -e "$_ = 'abc'; s/a/bb/; print"} ], ( q{perl -e "$_ = 'abc'; s/a/bb/; print"} ) );

## do tests

#plan tests => test_num() + ($Test::NoWarnings::VERSION ? 1 : 0);
plan tests => test_num() + ($haveTestNoWarnings ? 1 : 0) + 1;

ok( -r $script, "script readable" );

do_tests(); # test
##
my @tests;
sub add_test { push @tests, [ (caller(0))[2], @_ ]; return; }		## NOTE: caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
sub test_num { return scalar(@tests); }
## no critic (Subroutines::ProtectPrivateSubs)
sub do_tests { foreach my $t (@tests) { my $line = shift @{$t}; my @args = @{shift @{$t}}; my @exp = @{$t}; my @got; my ($got_stdout, $got_stderr); eval { IPC::Run3::run3( "$perl $script -e @args", \undef, \$got_stdout, \$got_stderr ); chomp($got_stdout); chomp($got_stderr); if ($got_stdout) { push @got, $got_stdout }; if ($got_stderr) {push @got, $got_stderr}; 1; } or ( @got = ( $@ =~ /^(.*)\s+at.*$/ ) ); eq_or_diff \@got, \@exp, "[line:$line] testing: `@args`"; } return; }
