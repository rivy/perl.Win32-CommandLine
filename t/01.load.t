#!perl -w  -- -*- tab-width: 4; mode: perl -*-

# t/01.load.t - check module loading

# ToDO: Modify untaint() to allow UNDEF argument(s) [needs to be changed across all tests]

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;  # DISABLE buffering (enable autoflush) on STDIN, STDOUT, and STDERR (keeps output in order)
}

use Test::More;     # included with perl v5.6.2+

use version qw//;
my @modules = ( 'CPAN::Meta' );  # @modules = ( '<MODULE> [<MIN_VERSION> [<MAX_VERSION>]]', ... )
my $haveRequired = 1;
foreach (@modules) {my ($module, $min_v, $max_v) = /\S+/gmsx; my $v = eval "require $module; $module->VERSION();"; if ( !$v || ($min_v && ($v < version->new($min_v))) || ($max_v && ($v > version->new($max_v))) ) { $haveRequired = 0; my $out = $module . ($min_v?' [v'.$min_v.($max_v?" - $max_v":'+').']':q//); diag("$out is not available"); }}  ## no critic (ProhibitStringyEval)

plan skip_all => '[ '.join(', ',@modules).' ] required for testing' if not $haveRequired;

my $metaFile = q//;
    $metaFile = 'META.json' if (($metaFile eq q//) && (-f 'META.json'));
    $metaFile = 'META.yaml' if (($metaFile eq q//) && (-f 'META.yaml'));
my $haveMetaFile = ($metaFile ne q//);
my $haveNonEmptyMetaFile = $haveMetaFile && (-s $metaFile);
my $meta_ref = CPAN::Meta->load_file( $metaFile );
my $packages_href = (defined $meta_ref) ? $meta_ref->{provides} : undef;

plan tests => scalar( defined $packages_href ? keys %{$packages_href} : 0 );

diag("$^O, perl v$], $^X");

foreach my $module_name ( sort keys %{$packages_href} ) {
    my $message = 'Missing $module_name';
    if (!defined($module_name)) {
        diag $message;
        skip $message, 1;
        }
    use_ok( $module_name );
    diag( qq{$module_name, v${$packages_href}{$module_name}{version}} );
    }

#### SUBs ---------------------------------------------------------------------------------------##

sub _is_const { my $isVariable = eval { ($_[0]) = $_[0]; 1; }; return !$isVariable; }

sub untaint {
    # untaint( $|@ ): returns $|@
    # RETval: variable with taint removed

    # BLINDLY untaint input variables
    # URLref: [Favorite method of untainting] http://www.perlmonks.org/?node_id=516577
    # URLref: [Intro to Perl's Taint Mode] http://www.webreference.com/programming/perl/taint

    use Carp;

    #my $me = (caller(0))[3];
    #if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me.'($_) instead?)'; return; }
    #if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

    my $arg_ref;
    $arg_ref = \@_;
    $arg_ref = [ @_ ] if defined wantarray;     ## no critic (ProhibitPostfixControls)  ## break aliasing if non-void return context

    for my $arg ( @{$arg_ref} ) {
        if (defined($arg)) {
            if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
            $arg = ( $arg =~ m/\A(.*)\z/msx ) ? $1 : undef;
            }
        }

    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
    }

sub is_tainted {
    ## no critic ( ProhibitStringyEval RequireCheckingReturnValueOfEval ) # ToDO: remove/revisit
    # URLref: [perlsec - Laundering and Detecting Tainted Data] http://perldoc.perl.org/perlsec.html#Laundering-and-Detecting-Tainted-Data
    return ! eval { eval(q{#} . substr(join(q{}, @_), 0, 0)); 1 };
    }

sub in_taint_mode {
    ## no critic ( RequireBriefOpen RequireInitializationForLocalVars ProhibitStringyEval RequireCheckingReturnValueOfEval ProhibitBarewordFileHandles ProhibitTwoArgOpen ) # ToDO: remove/revisit
    # modified from Taint source @ URLref: http://cpansearch.perl.org/src/PHOENIX/Taint-0.09/Taint.pm
    my $taint = q{};

    if (not is_tainted( $taint )) {
        $taint = substr("$0$^X", 0, 0);
        }

    if (not is_tainted( $taint )) {
        $taint = substr(join("", @ARGV, %ENV), 0, 0);
        }

    if (not is_tainted( $taint )) {
        local(*FILE);
        my $data = q{};
        for (qw(/dev/null nul / . ..), values %INC, $0, $^X) {
            # Why so many? Maybe a file was just deleted or moved;
            # you never know! :-)  At this point, taint checks
            # are probably off anyway, but this is the ironclad
            # way to get tainted data if it's possible.
            # (Yes, even reading from /dev/null works!)
            #
            last if open FILE, $_
            and defined sysread FILE, $data, 1
            }
        close( FILE );
        $taint = substr($data, 0, 0);
        }

    return is_tainted( $taint );
    }
