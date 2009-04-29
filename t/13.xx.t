#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;				# included with perl [see Standard Modules in perlmodlib]
use Test::Differences;		# included with perl [see Standard Modules in perlmodlib]

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

# autoflush to keep output in order
my $stdout = select(STDERR);		## no critic (ProhibitOneArgSelect)
$|=1;								## no critic (RequireLocalizedPunctuationVars)
select($stdout);					## no critic (ProhibitOneArgSelect)
$|=1;								## no critic (RequireLocalizedPunctuationVars)

sub add_test;
sub test_num;
sub do_tests;

# Tests

## setup
my $perl = Probe::Perl->find_perl_interpreter;
my $script = File::Spec->catfile( 'bin', 'xx.bat' );

## accumulate tests

# TODO: organize tests, add new tests for 'xx.bat'
# TODO: add tests (CMD and TCC) for x.bat => { x perl -e "$x = q{abc}; $x =~ s/a|b/X/; print qq{x = $x\n};" } => { x = Xbc }		## enclosed redirection

if ($haveExtUtilsMakeMaker)
	{# ExtUtilsMakeMaker present
	add_test( [ q{-v} ], ( q{xx.bat v}.MM->parse_version($script) ) );
	}
add_test( [ q{perl -e 'print "test"'} ], ( q{perl -e "print \"test\""} ) );
add_test( [ q{TEST -m "VERSION: update to 0.3.11"} ], ( q{TEST -m "VERSION: update to 0.3.11"} ) );
add_test( [ q{perl -MPerl::MinimumVersion -e "$pmv = Perl::MinimumVersion->new('lib/Win32/CommandLine.pm'); @m=$pmv->version_markers(); for ($i = 0; $i<(@m/2); $i++) {print qq{$m[$i*2] = { @{$m[$i*2+1]} }\n};}"} ], ( q{perl -MPerl::MinimumVersion -e "$pmv = Perl::MinimumVersion->new('lib/Win32/CommandLine.pm'); @m=$pmv->version_markers(); for ($i = 0; $i<(@m/2); $i++) {print qq{$m[$i*2] = { @{$m[$i*2+1]} }\n};}"} ) );
add_test( [ q{perl -e "$_ = 'abc'; s/a/bb/; print"} ], ( q{perl -e "$_ = 'abc'; s/a/bb/; print"} ) );
add_test( [ q{xx -e perl -e "$x = split( /x/, q{}); print $x;"} ], ( q{xx -e perl -e "$x = split( /x/, q{}); print $x;"} ) );		## prior BUG

# design decision = should non-quoted/non-glob expanded tokens be dosified or not
add_test( [ q{/NOT_A_FILE} ], ( q{\NOT_A_FILE} ) );		# non-files (can screw up switches)

if ($ENV{TEST_FRAGILE} or ($ENV{TEST_ALL} and (defined $ENV{TEST_FRAGILE} and $ENV{TEST_FRAGILE}))) {
	add_test( [ q{c:/windows} ], ( q{c:\windows} ) );		# non-expanded files									## FRAGILE (b/c case differences between WINDOWS)
	add_test( [ q{c:/windows/system*} ], ( q{c:\windows\system c:\windows\system.ini c:\windows\system32} ) );		# non-expanded files ## FRAGILE (b/c case differences between WINDOWS)
	}

# /dev/nul vs nul (?problem or ok)
add_test( [ q{$( echo > nul )} ], ( ) );
#FRAGILE? #CMD vs TCC as COMSPEC# add_test( [ q{$( echo > /dev/nul )} ], ( q{The system cannot find the path specified.} ) );

add_test( [ q{perl -e 'print 0'} ], ( q{perl -e "print 0"} ) );
add_test( [ q{perl -e "print 0"} ], ( q{perl -e "print 0"} ) );
#add_test( [ q{$( perl -e 'print 0' )} ], ( q{0} ) );	## ERROR -- ? fixable, ? should it be fixed? ## design decision = ?attempt to fix the single quote issue == NOTE: _with xx alias of perl_, q{perl -e 'print 0'} WORKS, so shouldn't q{$( perl -e 'print 0' )} work as well?
add_test( [ q{$( perl -e "print 0" )} ], ( q{0} ) );

add_test( [ q{$( echo 0 )} ], ( q{0} ) );
add_test( [ q{$( echo TEST )} ], ( q{TEST} ) );

add_test( [ q{perl -e "print `xx -e t/*.t`"} ], ( q{perl -e "print `xx -e t/*.t`"} ) );
add_test( [ q{perl -e "print `xx -e t\*.t`"} ], ( q{perl -e "print `xx -e t\*.t`"} ) );	## prior BUG

if ($ENV{TEST_FRAGILE} or ($ENV{TEST_ALL} and (defined $ENV{TEST_FRAGILE} and $ENV{TEST_FRAGILE}))) {
	add_test( [ q{~} ], ( q{"}.$ENV{USERPROFILE}.q{"} ) );	## FRAGILE (b/c quotes are dependent on internal spaces)
	}

$ENV{'~TEST'} = "/test";
add_test( [ q{~TEST} ], ( q{\\test} ) );	## ? FRAGILE

## FRAGILE = uncomment this and make it better
#my $version_output = `ver`;	## no critic (ProhibitBacktickOperators)
#chomp( $version_output );
#$version_output =~ s/^\n//s;		# NOTE: initial \n is removed by subshell expansion ## design decision: should the initial NL be removed?
#add_test( [ q{set os_version=$(ver)} ], ( "set os_version=".$version_output ) );

## TODO: add additional test for each add_test which checks double expansion (xx -e xx <TEST> should equal xx -e <TEST> EXCEPT for some special characters which can't be represented on cmd.exe commandline even with quotes (eg, CTRL-CHARS, TAB, NL))

## TODO: add tests for exit code propagation (internal/perl script _and_ source BAT script errors)
## eg: 'xx -so foobar', 'xx -so echo perl -e 1', 'xx -so echo perl -e "exit(1)"', 'xx -so echo perl -e "exit(-1)"', 'xx -so echo perl -e "exit(255)"', 'xx -so echo perl -e "exit(100)"', 'xx -so echo foobar', 'xx -so exit /B 1', 'xx -so exit /B 2', 'xx -so exit /B 255', 'xx -so exit /B -1'

## do tests

#plan tests => test_num() + ($Test::NoWarnings::VERSION ? 1 : 0);
plan tests => 1 + test_num() + ($haveTestNoWarnings ? 1 : 0);

ok( -r $script, "script readable" );

#my (@args, @exp, @got, $got_stdout, $got_stderr);
#$ENV{'~TEST'} = "/test";
#@args = ( q{~TEST} );
## check multiple expansion (for NORMAL characters)
#@exp = ( q{\\test} );
#eval { IPC::Run3::run3( "$perl $script $script -e @args", \undef, \$got_stdout, \$got_stderr ); chomp($got_stdout); chomp($got_stderr); if ($got_stdout ne q{}) { push @got, $got_stdout }; if ($got_stderr ne q{}) {push @got, $got_stderr}; 1; } or ( @got = ( $@ =~ /^(.*)\s+at.*$/ ) ); eq_or_diff \@got, \@exp, '[line:'.__LINE__."] testing: `@args`";

# TODO: check multiple expansion (for NON-PRINTABLE characters) -- SHOULD FAIL

do_tests(); # test
##
my @tests;
sub add_test { push @tests, [ (caller(0))[2], @_ ]; return; }		## NOTE: caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
sub test_num { return scalar(@tests); }
## no critic (Subroutines::ProtectPrivateSubs)
sub do_tests { foreach my $t (@tests) { my $line = shift @{$t}; my @args = @{shift @{$t}}; my @exp = @{$t}; my @got; my ($got_stdout, $got_stderr); eval { IPC::Run3::run3( "$perl $script -e @args", \undef, \$got_stdout, \$got_stderr ); chomp($got_stdout); chomp($got_stderr); if ($got_stdout ne q{}) { push @got, $got_stdout }; if ($got_stderr ne q{}) {push @got, $got_stderr}; 1; } or ( @got = ( $@ =~ /^(.*)\s+at.*$/ ) ); eq_or_diff \@got, \@exp, "[line:$line] testing: `@args`"; } return; }
