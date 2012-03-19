#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering (enable autoflush) on STDIN, STDOUT, and STDERR (keeps output in order)
}

# untaint
# NOTE: IPC::System::Simple gives excellent taint explanations and is very useful in debugging IPC::Run3 taint errors
# $ENV{PATH}, $ENV{TMPDIR} or $ENV{TEMP} or $ENV{TMP}, $ENV{PERL5SHELL} :: all required to be un-tainted for IPC::Run3
# URLref: [Piping with Perl (in taint mode)] http://stackoverflow.com/questions/964426/why-doesnt-a-pipe-open-work-under-perls-taint-mode
{
## no critic ( RequireLocalizedPunctuationVars ProhibitCaptureWithoutTest )
$ENV{PATH}   = ($ENV{PATH} =~ /\A(.*)\z/msx, $1);
$ENV{TMPDIR} = ($ENV{TMPDIR} =~ /\A(.*)\z/msx, $1) if $ENV{TMPDIR};
$ENV{TEMP}   = ($ENV{TEMP} =~ /\A(.*)\z/msx, $1) if $ENV{TEMP};
$ENV{TMP}    = ($ENV{TMP} =~ /\A(.*)\z/msx, $1) if $ENV{TMP};
$ENV{PERL5SHELL} = ($ENV{PERL5SHELL} =~ /\A(.*)\z/msx, $1) if $ENV{PERL5SHELL};
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
}

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

sub add_test;
sub test_num;
sub do_tests;

# Tests

## setup
my $perl = Probe::Perl->find_perl_interpreter;
my $script = File::Spec->catfile( 'bin', 'xx.bat' );

# untaint :: find_perl_interpreter RETURNs tainted value
$perl = ( $perl =~ m/\A(.*)\z/msx ) ? $1 : q{};  	## no critic ( ProhibitCaptureWithoutTest )

## accumulate tests

# TODO: organize tests, add new tests for 'xx.bat'
# TODO: add tests (CMD and TCC) for x.bat => { x perl -e "$x = q{abc}; $x =~ s/a|b/X/; print qq{x = $x\n};" } => { x = Xbc }		## enclosed redirection

# TODO: test expansions
# PROBLEM: subshell execution no preserving setdos /x-which, any other changes in subshells? is there a setdos /x0 in the AutoRun somewhere?
# >which which
# C:\Users\Public\Documents\@bin\which.pl
# >xx -e $(which which)
# which is an internal command
# NOTES: occurs with both TCC and CMD shells and dependent on PERL5SHELL
# $ENV{PERL5SHELL}='tcc.exe /x/d/c' is the usual value => no AutoRun and the PROBLEM noted
# $ENV{PERL5SHELL}='tcc.exe /x/c' => AutoRun is executed and no difference between "which which" and "xx -e $(which which)" [or "xx -s echo $(which which)"]
#
# FRAGILE: test for differences between "COMMAND" and "xx -s echo $(COMMAND)" ## should be no differences but PERL5SHELL='tcc.exe /x/d/c' can introduce issues because of environmental differences arising from skipping AutoRuns (with the '/d' switch)

# TODO: PROBLEM: "xx -s echo $(alias)" => EXCEPTION: Assertion (Parsing is not proceeding ($s is unchanged)) failed!
#		## also, probably need to rename the assertion to claim the opposite in the assertion text

add_test( [ q{perl -e 'print "test"'} ], ( q{perl -e "print \"test\""} ) );
add_test( [ q{TEST -m "VERSION: update to 0.3.11"} ], ( q{TEST -m "VERSION: update to 0.3.11"} ) );
add_test( [ q{perl -MPerl::MinimumVersion -e "$pmv = Perl::MinimumVersion->new('lib/Win32/CommandLine.pm'); @m=$pmv->version_markers(); for ($i = 0; $i<(@m/2); $i++) {print qq{$m[$i*2] = { @{$m[$i*2+1]} }\n};}"} ], ( q{perl -MPerl::MinimumVersion -e "$pmv = Perl::MinimumVersion->new('lib/Win32/CommandLine.pm'); @m=$pmv->version_markers(); for ($i = 0; $i<(@m/2); $i++) {print qq{$m[$i*2] = { @{$m[$i*2+1]} }\n};}"} ) );
add_test( [ q{perl -e "$_ = 'abc'; s/a/bb/; print"} ], ( q{perl -e "$_ = 'abc'; s/a/bb/; print"} ) );
add_test( [ q{xx -e perl -e "$x = split( /x/, q{}); print $x;"} ], ( q{xx -e perl -e "$x = split( /x/, q{}); print $x;"} ) );		## prior BUG

# design decision = should non-quoted/non-glob expanded tokens be dosified or not
add_test( [ q{/NOT_A_FILE} ], ( q{\NOT_A_FILE} ) );		# non-files (can screw up switches)

if ($ENV{TEST_FRAGILE} or ($ENV{TEST_ALL} and (defined $ENV{TEST_FRAGILE} and $ENV{TEST_FRAGILE}))) {
	if ($haveExtUtilsMakeMaker)
		{# ExtUtilsMakeMaker present
		add_test( [ q{-v} ], ( q{xx.bat v}.MM->parse_version($script) ) );
		}
	add_test( [ q{c:/windows} ], ( q{c:\windows} ) );		# non-expanded files									## FRAGILE (b/c case differences between WINDOWS)
	add_test( [ q{c:/windows/system*} ], ( q{c:\windows\system c:\windows\system.ini c:\windows\system32} ) );		# non-expanded files ## FRAGILE (b/c case differences between WINDOWS)
	}

# /dev/nul vs nul (?problem or ok)
#FRAGILE? #CMD vs TCC as COMSPEC# add_test( [ q{$( echo > /dev/nul )} ], ( q{The system cannot find the path specified.} ) );
## this test FAILS if CMD.exe is not on the PATH and PERL5SHELL not set correctly before running script (others get the updated PERL5SHELL without WARNING [due to HARNESS_ACTIVE gating])
#add_test( [ q{$( echo > nul )} ], ( ) );
# ERROR output:
#   Failed test 'no warnings'
#   at c:/strawberry/perl/vendor/lib/Test/NoWarnings.pm line 38.
# There were 1 warning(s)
#       Previous test 7 '[line:68] testing: `/NOT_A_FILE`'
#       Can't spawn "cmd.exe": No such file or directory at c:/strawberry/perl/vendor/lib/IPC/Run3.pm line 403.
#  at c:/strawberry/perl/vendor/lib/IPC/Run3.pm line 403
#       eval {...} called at c:/strawberry/perl/vendor/lib/IPC/Run3.pm line 375
#       IPC::Run3::run3('c:\STRAWB~1\perl\bin\perl.exe bin\xx.bat -e $( echo > nul )', 'SCALAR(0x38aa30)', 'SCALAR(0x232fea0)', 'SCALAR(0x232fed0)') called at t\13.xx.t line 135
#       eval {...} called at t\13.xx.t line 135
#       main::do_tests() called at t\13.xx.t line 129
#
# Looks like you failed 1 test of 17.

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

$ENV{'~TEST'} = "/test";  	## no critic ( RequireLocalizedPunctuationVars )
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
