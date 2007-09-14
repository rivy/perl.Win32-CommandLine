#-*- tab-width: 4; mode: perl -*-
package Win32::CommandLine;
#$Id$

use strict;
use warnings;

# VERSION: x.y[.date[.build]]  { y is odd = beta/experimental; y is even = release }
#use version qw(); our $VERSION = version::qv('0.1'.'.'.join(q{}, split(/\//xms,qw($Date$)[-3])).q{.}.qw($Rev$)[-2]);		## no critic ( ProhibitCallsToUnexportedSubs )
use version qw(); our $VERSION = version::qv(qw($Version$)[-2]);		## no critic ( ProhibitCallsToUnexportedSubs )
our $REVISION = qw($Revision$)[-2];

 # Module Summary

=head1 NAME

Win32::CommandLine - Retrieve and reparse the Win32 command line

=head1 VERSION

This document describes C<Win32::CommandLine> ($Revision$, $Date$).

=cut

#use 5.006;      # 5.6: for 'use charnames qw( :full )'

# Module base/ISA and Exports

use base qw( DynaLoader Exporter );

#our @EXPORT = qw( );   # no default exported symbols
our %EXPORT_TAGS = (
    'ALL'       => [ (grep { /^(?!bootstrap|dl_load_flags|isa|qv)[^_][a-zA-Z_]*[a-z]+[a-zA-Z_]*$/ } keys %Win32::CommandLine::) ],  # all non-internal symbols [Note: internal symbols are ALL_CAPS or start with a leading '_']
#   'INTERNAL'  => [ (grep { /^(?!bootstrap|dl_load_flags|isa|qv)[_][a-zA-Z_]*[a-z]+[a-zA-Z_]*$/ } keys %Win32::CommandLine::) ],   # all internal functions [Note: internal functions start with a leading '_']
    );
our @EXPORT_OK = ( map { @{$_} } values %EXPORT_TAGS );

# Module Interface

sub command_line;   # return Win32 command line string
sub argv;           # get commandline and reparse it, returning the new ARGV array

####

# Module Implementation

bootstrap Win32::CommandLine $VERSION;

sub command_line{
    # command_line(): returns $
    return _wrap_GetCommandLine();
}

sub argv{
    # argv(): returns @
    return _argv( command_line() );     # get commandline and reparse it returning the new ARGV array
}

use Carp qw();
use Carp::Assert qw();
#use Regexp::Autoflags;
#use Readonly;
#use Getopt::Clade;
#use Getopt::Euclid;
#use Class::Std;

use File::Spec qw();
use File::Which qw();

my %_PG = ( # package globals
    #$_PG{'single_q'} = "'";
    #$_PG{'double_q'} = '"';
    #$_PG{'quote'} = $_PG{'single_q'}.$_PG{'double_q'};
    #$_PG{'quote_meta'} = quotemeta $_PG{'quote'};
    #
    #$_PG{'escape_char'} = q$_PG{'escape_char'};
    #
    #$_PG{'glob_char'} = quotemeta ( "?*[{" );  # glob signal characters
    #
    #$_PG{'unbalanced_quotes'} = 0;
    'single_q'			=> q{'},				# '
    'double_q'			=> q{"},				# "
    'quote'				=> q{'"},				# ' and "
    'quote_meta'		=> quotemeta q{'"},		# quotemeta ' and "
    'escape_char'		=> q{\\},
    'glob_char'			=> quotemeta ( '?*[{' ),  # glob signal characters
    'unbalanced_quotes' => 0,
    );

{
sub _decode; # _decode( <null>|$|@ ): returns <null>|$|@ ['shortcut' function]
my %table;
###
#Escape Sequences
#\\ - 0x5c - Backslash
#\' - 0x27 - Single Quote (not sure if it is hex 27 ???)
#\" - 0x22 - Double Quote (not sure if it is hex 22 ???)
#\? - 0x3f - Question Mark
#\0 - 0x00 - null
#\a - 0x07 - Alert = Produces an audible or visible alert.
#\b - 0x08 - Backspace = Moves the cursor back one position (non-destructive).
#\f - 0x0c - Form Feed = Moves the cursor to the first position of the next page.
#\n - 0x0a - New Line = Moves the cursor to the first position of the next line.
#\r - 0x0d - Carriage Return = Moves the cursor to the first position of the current line.
#\t - 0x09 - Horizontal Tab = Moves the cursor to the next horizontal tabular position.
#\v - 0x0b- Vertical Tab = Moves the cursor to the next vertical tabular position.
#
#Numeric Escape Sequences
#\nnn - n = octal digit, 8 bit
#\xnn - n = hexadecimal digit, 8 bit
#\Xnn - n = hexadecimal digit, 8 bit
#\unnnn - n = hexadecimal digit, 16 bit
#\Unnnnnnnn - n = hexadecimal digit, 32 bit###
#              \a     alert (bell)
#              \b     backspace
#              \e     an escape character
#              \f     form feed
#              \n     new line
#              \r     carriage return
#              \t     horizontal tab
#              \v     vertical tab
#              \\     backslash
#              \'     single quote
#              \nnn   the eight-bit character whose value is the octal value  nnn  (one  to
#                     three digits)
#              \xHH   the  eight-bit character whose value is the hexadecimal value HH (one
#                     or two hex digits)
#              \XHH   the  eight-bit character whose value is the hexadecimal value HH (one
#                     or two hex digits)
#              \cx    a control-x character

# Not implemented (not used in bash):
#\unnnn - n = hexadecimal digit, 16 bit
#\Unnnnnnnn - n = hexadecimal digit, 32 bit
$table{'0'} = chr(0x00);    # NUL (REMOVE: implemented with octal section)
$table{'a'} = "\a";         # BEL
$table{'b'} = "\b";         # BS
$table{'e'} = "\e";         # ESC
$table{'f'} = "\f";         # FF
$table{'n'} = "\n";         # NL
$table{'r'} = "\r";         # CR
$table{'t'} = "\t";         # TAB/HT
$table{'v'} = chr(0x0b);    # VT

$table{$_PG{'single_q'}} = $_PG{'single_q'};		# single-quote
$table{$_PG{'double_q'}} = $_PG{'double_q'};		# double-quote
$table{$_PG{'escape_char'}} = $_PG{'escape_char'}; 	# backslash-escape

#octal
#   for (my $i = 0; $i < oct('1000'); $i++) { $table{sprintf("%3o",$i)} = chr($i); }
for my $i (0..oct('777')) { $table{sprintf('%3o',$i)} = chr($i); }

#hex
#   for (my $i = 0; $i < 0x10; $i++) { $table{"x".sprintf("%1x",$i)} = chr($i); $table{"X".sprintf("%1x",$i)} = chr($i); $table{"x".sprintf("%2x",$i)} = chr($i); $table{"X".sprintf("%2x",$i)} = chr($i); }
#   for (my $i = 0x10; $i < 0x100; $i++) { $table{"x".sprintf("%2x",$i)} = chr($i); $table{"X".sprintf("%2x",$i)} = chr($i); }
for my $i (0..0xf) { $table{'x'.sprintf('%1x',$i)} = chr($i); $table{'X'.sprintf('%1x',$i)} = chr($i); $table{'x'.sprintf('%2x',$i)} = chr($i); $table{'X'.sprintf('%2x',$i)} = chr($i); }
for my $i (0x10..0xff) { $table{'x'.sprintf('%2x',$i)} = chr($i); $table{'X'.sprintf('%2x',$i)} = chr($i); }

#control characters
#   for (my $i = 0; $i < 0x20; $i++) { $table{"c".chr(ord('@')+$i)} = chr($i); }
my $base_char = ord(q{@});
for my $i (0..(0x20 - 1)) { $table{'c'.chr($base_char+$i)} = chr($i); }
$table{'c?'} = chr(0x7f);

sub _decode {
    # _decode( <null>|$|@ ): returns <null>|$|@ ['shortcut' function]
    # decode ANSI C string
    @_ = @_ ? @_ : $_ if defined wantarray;     # break aliasing if non-void return context           ## no critic (ProhibitPostfixControls)

    my $c = '0abefnrtv'.$_PG{'escape_char'}.$_PG{'single_q'}.$_PG{'double_q'};
    for (@_ ? @_ : $_) { s/\\([$c]|[0-7]{1,3}|x[0-9a-fA-F]{2}|X[0-9a-fA-F]{2}|c.)/$table{$1}/g }

    return wantarray ? @_ : "@_";
    }
}

# remember...
# lodin says  Re Is silent use of $_ for empty argument lists reasonable for "shortcut" functions? If you ask me, just use "for" and "map" for lists and only care about $_[0]. Good node btw. I ++:ed it.
# lodin says Re Is silent use of $_ for empty argument lists reasonable for "shortcut" functions? Perhaps that didn't make sense. I mean use "@bar = map trim(), @foo" and "trim() for @foo" if you have lists.
# [aka] - these should _always_ work no matter what the implementation
#   @bar = map trim($_, {}), @foo;
#   @bar = trim($_, {}) for @foo;
sub _ltrim_standard_shortcut {
    # _ltrim( <null>|$|@ ): returns <null>|$|@ ['shortcut' function]
    # trim leading whitespace
    @_ = @_ ? @_ : $_ if defined wantarray;     # disconnect aliasing if non-void return context

    for (@_ ? @_ : $_) { s/\A\s+// }

    return wantarray ? @_ : "@_";
    }

sub _ltrim_lex_version {
    # _ltrim( <null>|$|@ ): returns <null>|$|@ ['shortcut' function]
    # trim leading whitespace
    # NOTE: not able to currently determine the difference between a function call with a zero arg list {"f([]);"} and a function call with no arguments {"f();"}
    #@_ = @_ ? @_ : $_ if defined wantarray;        # break aliasing if non-void return context
    use Lexical::Alias ( qw(alias_a) );             # TODO: "use Data::Alias" if perl version >= 5.8.1

    my @args;

    alias_a( @_, @args );
    @args = @_ if defined wantarray;        # disconnect aliasing if non-void return context

    #for (@_ ? @_ : $_) { s/\A\s+// }
    for ( @args ) { s/\A\s+//; }

    return wantarray ? @args : "@args";
    }

sub _is_const { return !eval { ($_[0]) = $_[0]; 1; }; }

sub _is_const_B {use B; return B::SVf_READONLY & B::svref_2object(\$_[0])->FLAGS; }

sub _ltrim_shortcut_idiom {
    # _ltrim( <null>|$|@ [,\%] ): returns <null>|$|@ [standard 'shortcut' function] (with optional hash_ref containing function options)
    # trim leading characters (defaults to whitespace)
    my $opt_ref;
    $opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));  # pop last argument only if it's a HASH reference
    my %opt = (
        'trim_re' => '\s+',
        );
    # retrieve and validate options if they exist
    if ($opt_ref) { for (keys %{$opt_ref}) { if (defined $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown option '$_' to for function ".(caller(0))[3]; } } }

    my $t = $opt{'trim_re'};

    my $arg_ref;
    $arg_ref = \@_;
    $arg_ref = @_ ? [ @_ ] : [ $_ ] if defined wantarray;       # break aliasing if non-void return context

    for my $arg ( @{$arg_ref} ? @{$arg_ref} : $_ ) {    # all args or just $_ if no args
        if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
        $arg =~ s/\A$t//;
        }

    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
    }

#sub _trim_disambiguate_model(;\[$@]@)
#{
#    return _trim( $_ )
#        if  ! @_;
#    my $ref= shift @_;
#    return _trim( eval{@$ref;1} ? @$ref : $$ref, @_ )
#}

# _l()
# _l($)
# _l($, $)
# _l($, @)
# _l(@)
# _l(@, $)
# _l(@, @)


sub _ltrim_disambiguate_o(;\[$@]@) {    ## no critic (Subroutines::ProhibitSubroutinePrototypes Subroutines::ProhibitManyArgs)
    my $t = '\s+';

    my $arg_ref_ref = [ [] ];
    # if (! @_) { leave $arg_ref_ref as empty array }
    if (@_) {
        # have arguments
        if (defined wantarray) {
            # disconnect aliases by copying to local
            if (ref($_[0]) eq 'SCALAR') { $arg_ref_ref = [ [${shift @_}, @_] ]; }
            else { $arg_ref_ref = [ [@{shift @_}, @_] ]; }
            }
        else {
            # void-context (keep aliases)
            if (ref($_[0]) eq 'SCALAR') { $arg_ref_ref = [ shift @_, \@_ ]; }
            else { $arg_ref_ref = [ \@{shift @_}, \@_ ]; }
            }
        }

    for my $arg_ref ( @{$arg_ref_ref} ? @{$arg_ref_ref} : \$_ ) {   # all args or just $_ if no args
        if (_is_const(${$arg_ref})) { Carp::carp 'Attempt to modify readonly scalar'; return; }
        ${$arg_ref} =~ s/\A$t//;
        }

    return wantarray ? @{${$arg_ref_ref}} : "@{${$arg_ref_ref}}";
}

sub _ltrim_prototype(;\[$@]@) {     ## no critic (Subroutines::ProhibitSubroutinePrototypes Subroutines::ProhibitExcessComplexity Subroutines::ProhibitManyArgs)
    # fails for things like _ltrim(<STDIN>) because '<STDIN>' doesn't match the prototype
    # @arg = (qq{ testing}, { trim_re => '[\st]+'}) => _ltrim(@arg) fails because @arg is forced into ref and function options are integrated as a part of 1st argument
    use Data::Dump qw( dump );
    #print "\n";
    print '_lt:@'.'_:'.dump(@_)."\n";

    my $opt_ref;
    $opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));  # pop last argument only if it's a HASH reference
    my %opt = (
        'trim_re' => '\s+',
        );
    if ($opt_ref) { for (keys %{$opt_ref}) { if (defined $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown option '$_' to for function ".(caller(0))[3]; return; } } }

    my $t = $opt{'trim_re'};

    print '_lt:@'.'_:'.dump(@_)."\n";

    my $use_alias = 0;
    my @arg_ref_array = ([]);
    print '_lt:@'.'arg_ref_array:'.dump(@arg_ref_array)."\n";
    # if (! @_) { leave $arg_ref_ref as empty array }
    if (@_) {
        # have arguments
        if (defined wantarray) {
            # disconnect aliases by copying to local
            if (ref($_[0]) eq 'SCALAR') { my @a1 = ( ${shift @_} ); my @a2 = @_; @arg_ref_array = ( \(@a1), (@a2 ? \(@a2) : ()) ); }
            else { my @a1 = @{shift @_}; my @a2 = @_; @arg_ref_array = ( \(@a1), (@a2 ? \(@a2) : ()) ); }
            }
        else {
            # void-context (keep aliases)
            if (ref($_[0]) eq 'SCALAR') { @arg_ref_array = ( shift @_, (@_ ? \(@_) : ()) ); }
            else { @arg_ref_array = ( \(@{shift @_}), (@_ ? \(@_) : ()) ); }
            }
        }
    else {
        # no arguments
        if (defined wantarray) { my @a1 = ( $_ ); @arg_ref_array = \(@a1); }    # disconnect $_ alias
#       else { $arg_ref_ref = [ [\$_] ]; }                      # keep $_ alias
        else { $use_alias = 1; }                                # keep $_ alias
        }

#   my @x = ( @{$arg_ref_ref} );
#   print '_lt:@x:'.dump(@x)."\n";
#   my $y = [ 1, 2 ];
#   foreach (@$y) {
#       print '_lt:@y[]:'.dump($_)."\n";
#       }
#   print '_lt:$y:'.dump($y)."\n";
    print '_lt:@'.'arg_ref_array:'.dump(@arg_ref_array)."\n";
#   print '_lt:@{$arg_ref_ref}:'.dump(@{$arg_ref_ref})."\n";
#   print '_lt:@$arg_ref_ref->[0]:'.dump(@$arg_ref_ref->[0])."\n";
#   print '_lt:@{@$arg_ref_ref->[0]}:'.dump(@{@$arg_ref_ref->[0]})."\n";
#   print '_lt:@$arg_ref_ref->[0]->[0]:'.dump(@$arg_ref_ref->[0]->[0])."\n";

#   for my $arg_ref ( @$arg_ref_ref->[0] ? @$arg_ref_ref->[0] : \$_ ) { # all args or just $_ if no args
#   for my $arg ( @{@$arg_ref_ref->[0]} ? @{@$arg_ref_ref->[0]} : $_ ) {    # all args or just $_ if no args
    print "use_alias = $use_alias\n";
#   for my $arg ( $use_alias ? $_ : @{$arg_ref_ref} ) {
    for my $arg_ref ( $use_alias ? \$_ : @arg_ref_array ) {
#       print '_lt:$arg_ref:'.dump($arg_ref)."\n";
#       print '_lt:@{$arg_ref}:'.dump(@{$arg_ref})."\n";
        print '_lt:$'.'{$'.'arg_ref}:'.dump(${$arg_ref})."\n";
        if (_is_const(${$arg_ref})) { Carp::carp 'Attempt to modify readonly scalar'; return; }
        ${$arg_ref} =~ s/\A$t//;
        }

    if ($use_alias) { return; }
    my @return_array = map { ${$_} } @arg_ref_array;
    return wantarray ? @return_array : "@return_array";
}

sub _ltrim_no_array {
    # _ltrim( $ [,\%] ): returns $ (with optional hash_ref containing function options)
    # trim leading characters (defaults to whitespace)
    # remember...
    # lodin says  Re Is silent use of $_ for empty argument lists reasonable for "shortcut" functions? If you ask me, just use "for" and "map" for lists and only care about $_[0]. Good node btw. I ++:ed it.
    # lodin says Re Is silent use of $_ for empty argument lists reasonable for "shortcut" functions? Perhaps that didn't make sense. I mean use "@bar = map trim(), @foo" and "trim() for @foo" if you have lists.
    my $me = (caller(0))[3];
    my $opt_ref;
    $opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));  # pop last argument only if it's a HASH reference (assumed to be options for our function)
    my %opt = (
        'trim_re' => '\s+',
        );
    if ($opt_ref) { for (keys %{$opt_ref}) { if (defined $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown option '$_' to for function ".$me; } } }

    my $t = $opt{'trim_re'};

    #if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me.'($_) instead?)'; return; }
    #if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }
    if ( @_ > 1 ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

    my $arg_ref;
    $arg_ref = \@_;
    $arg_ref = [ @_ ] if defined wantarray;     # break aliasing if non-void return context

@_ = @_ ? @_ : $_ if defined wantarray;     # disconnect aliasing if non-void return context

for (@_ ? @_ : $_) { s/\A\s+// }

return wantarray ? @_ : "@_";

    for my $arg ( @{$arg_ref} ) {
        if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
        $arg =~ s/\A$t//;
        }

    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
    }

sub _ltrim {
    # _ltrim( $|@ [,\%] ): returns $|@ ['shortcut' function] (with optional hash_ref containing function options)
    # trim leading characters (defaults to whitespace)
    # NOTE: not able to currently determine the difference between a function call with a zero arg list {"f(());"} and a function call with no arguments {"f();"}
    #       so, by the Principle of Least Surprise, f() in void context is disallowed instead of being an alias of "f($_)" so that f(@array) doesn't silently perform f($_) when @array has zero elements
    #       use "f($_)" instead of "f()" when needed
    #       carp on both
    # NOTE: alternatively, could use _ltrim( <null>|$|\@[,\%] ), carping on more than one argument
    # NOTE: alternatively, could use _ltrim( <null>|$|@|\@[,\%] ), carping on more than one argument
    # NOTE: after thinking and reading PBP (specifically Dollar-Underscore (p85) and Interator Variables (p105)), I think disallowing zero arguments is for the best.
    #       making operation on $_ require explicit coding breeds more maintainable code with little extra effort
    # so:
    #   $foo = _ltrim($bar);
    #   @foo = _ltrim(@bar) if @bar;
    #   $foo = _ltrim(@bar) if @bar;
    #   _ltrim($bar);
    #   _ltrim(@bar) if @bar;
    #   $foo = _ltrim($_);
    #   _ltrim($_);
    #   @bar = ();  $xxx = ltrim(@bar); ## ERROR
    #   $xxx = ltrim();                 ## ERROR
    #   ltrim();                        ## ERROR
    my %opt = (
        'trim_re' => '\s+',
        );

    my $me = (caller(0))[3];
    my $opt_ref;
    $opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));  # pop last argument only if it's a HASH reference (assumed to be options for our function)
    if ($opt_ref) { for (keys %{$opt_ref}) { if (defined $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown option '$_' to for function ".$me; return; } } }
    if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me."($_) instead?)"; return; }
    if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

    my $t = $opt{'trim_re'};

    my $arg_ref;
    $arg_ref = \@_;
    $arg_ref = [ @_ ] if defined wantarray;     # break aliasing if non-void return context

    for my $arg ( @{$arg_ref} ) {
        if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
        $arg =~ s/\A$t//;
        }

    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
    }

sub _gen_delimeted_regexp {
    # _gen_delimeted_regexp ( $delimiters, $escapes ): returns $
    # from "Mastering Regular Expressions, 2e; p. 281" and modified from Text::Balanced::gen_delimited_pat($;$) [v1.95]
    # $DOUBLE = qr{"[^"\\]+(?:\\.[^"\\]+)+"};
    # $SINGLE = qr{'[^'\\]+(?:\\.[^'\\]+)+'};
    ## no critic (ControlStructures::ProhibitCStyleForLoops)
    my ($dels, $escs) = @_;
    return q{} unless $dels =~ /^\S+$/;
    $escs = q{} unless $escs;

    #print "dels = $dels\n";
    #print "escs = $escs\n";

    my @pat = ();
    for (my $i=0; $i<length $dels; $i++)
        {
            my $d = quotemeta substr($dels,$i,1);
            if ($escs)
                {
                for (my $j=0; $j < length $escs; $j++)
                    {
                    my $e = quotemeta substr($escs,$j,1);
                    if ($d eq $e)
                        {
                        push @pat, "$d(?:[^$d]*(?:(?:$d$d)[^$d]*)*)$d";
                        }
                    else
                        {
                        push @pat, "$d(?:[^$e$d]*(?:$e.[^$e$d]*)*)$d";
                        }
                    }
                }
            else { push @pat, "$d(?:[^$d]*)$d"; }
        }
    my $pat = join q{|}, @pat;

    return "(?:$pat)";
    }

sub _dequote{
    # _dequote( <null>|$|@ [,\%] ): returns <null>|$|@ ['shortcut' function] (with optional hash_ref containing function options)
    # trim balanced outer quotes
    # $opt{'surround_re'} = 'whitespace' surround which is removed	[default = '\s*']
    # $opt{'allowed_quotes_re'} = balanced 'quote' delimeters which are removed	[default = q{['"]} ]

    my %opt = (
        'surround_re' => '\s*',
        'allowed_quotes_re' => '['.$_PG{'quote_meta'}.']',
        );

    my $me = (caller(0))[3];
    my $opt_ref;
    $opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));  # pop last argument only if it's a HASH reference (assumed to be options for our function)
    if ($opt_ref) { for (keys %{$opt_ref}) { if (defined $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown option '$_' to for function ".$me; } } }

	my $w = $opt{'surround_re'};
	my $q = $opt{'allowed_quotes_re'};

    @_ = @_ ? @_ : $_ if defined wantarray;  # break aliasing if non-void return context

    for (@_ ? @_ : $_)
        {
		s/^$w($q)(.*)\1$w$/$2/;
        #print "_ = $_\n";
        }

    return wantarray ? @_ : "@_";
    }

sub _zero_position {
    my $q = shift @_;
    my @a = @_;
    my $pos;
    # find $0 in the ARGV array
    #print "0 = $0\n";
    #win32 - filenames are case-preserving but case-insensitive [so, case doesn't matter]
    my $zero = $0;      ## no critic (Variables::ProhibitPunctuationVars)
    my $zero_lc = lc($zero);
    my $zero_dq = _dequote($zero_lc);  # dequoted $0

    print "zero = $zero\n";
    print "zero_lc = $zero_lc\n";
    print "zero_dq = $zero_dq\n";

#   while (my $arg = shift @a) {
    for ($pos=0; $pos<$#a; $pos++) {		## no critic (ProhibitCStyleForLoops)
        my $arg = $a[$pos];
#    for my $arg (@a) {
        print "arg = $arg\n";
        if ($zero_lc eq lc($arg))
            { # direct match
            #print "\tMATCH (direct)\n";
            last;
            }
        $arg =~ s/([$q])(.*)\1/$2/;
        print "arg = $arg\n";
        if ($zero_lc eq lc($arg))
            { # dequoted match
            #print "\tMATCH (dequoted)\n";
            last;
            }
        print 'rel2abs(arg) = '.File::Spec->rel2abs($arg)."\n";
        if (-e $arg && (lc(File::Spec->rel2abs( $zero_dq )) eq lc(File::Spec->rel2abs( $arg ))))
            { # rel2abs match
            #print "\tMATCH (rel2abs)\n";
            last;
            }
        if (!-e $arg)
            { # find file on PATH with File::Which (needed for compiled perl executables)
            my ($fn, $r);
            my ($split_1, $split_2);
            ($split_1, $split_2, $fn) = File::Spec->splitpath( $arg );
            #print "split_1 = $split_1\n";
            #print "split_2 = $split_2\n";
            #print "fn = $fn\n";
            $r = File::Which::which($fn);
            if (defined $r) { $r = File::Spec->rel2abs( $r ); }
            #print $arg."\t\t=(find with which)> ".((defined $r) ? $r : "undef");
            if (lc($r) eq lc(File::Spec->rel2abs($zero)))
                {# which found
                #print "\tMATCH (which)\n";
                last;
                }
            }
        #print "\n";
        }

    return $pos;
}

sub _argv_parse{}
sub _argv_go_glob{}
sub _zero_position_NEW{}
sub _argv_NEW{
    # _argv( $command_line )

    my $command_line = shift @_;

    # parse tokens from the $command_line string
    my %argv2 = _argv_parse( $command_line );

    # remove $0 (and any prior entries) from ARGV array (and the matching glob_ok signal array)
    my $p = _zero_position_NEW( \%argv2 );
    #print "p = $p\n";
    my $n = scalar($argv2{'argv'});
    #print "n = $n\n";
  ##$argv2{'argv'} = $argv2{'argv'}[ $p+1..$n ];
  ##$argv2{'glob_ok'} = $argv2{'glob_ok'}[ $p+1..$n ];

    # check for unbalanced quotes and croak if so...
    if ($_PG{'unbalanced_quotes'}) { Carp::croak 'Unbalanced command line quotes (at token `'.$argv2{'argv'}[-1].'`)'; }

    # do globbing
    my @argv2_g = _argv_do_glob( \%argv2 );

    return @argv2_g;
}

sub _argv{  ## no critic (Subroutines::ProhibitExcessComplexity)
    # _argv( $command_line )

    # [seperated for testing]
    # '...'     => literal (no escapes and no globbing within quotes)
    # $'...'    => ANSI C string escapes (\a, \b, \e, \f, \n, \r, \t, \v, \\, \', \n{1,3}, \xh{1,2}, \cx; all other \<x> =>\<x>), no globbing within quotes
    # "..." => literal (no escapes but allows internal globbing) [differs from bash]
    # $"..."  => same as "..."

    my @argv2;
    my @argv2_globok;           # glob signal per argv2 entry

    my $sq = $_PG{'single_q'};              # single quote (')
    my $dq = $_PG{'double_q'};              # double quote (")
    my $quotes = $sq.$dq;       # quote chars ('")
    my $q = quotemeta $quotes;

    my $gc = quotemeta ( '?*[{' );  # glob signal characters

    my $escape = $_PG{'escape_char'};

    my $_unbalanced_command_line_quotes = 0;

    my $re_q_esc = _gen_delimeted_regexp( $sq, $escape );   # regexp for single quoted string with escaped characters allowed
    my $re_qq = _gen_delimeted_regexp( $dq );               # regexp for double quoted string (no escaped characters)
    my $re_q = _gen_delimeted_regexp( $sq );                # regexp for single quoted string (no escaped characters)
    my $re_noesc = _gen_delimeted_regexp($quotes);          # regexp for any-quoted string (no escaped characters)

    #print "re_esc = $re_q_esc\n";
    #print "re_qq = $re_qq\n";
    #print "re_q = $re_q\n";
    #print "re_noesc = $re_noesc\n";

    #my $re_superescape = _gen_delimeted_regexp($quotes, "\\#");
    #print "re_superescape = $re_superescape\n";

    my $command_line = shift @_;    # "extract_..." is destructive of the original string
    my $s = $command_line;
    my $glob_this_token = 1;
    while ($s)
        {
        #print "s = `$s`\n";

        _ltrim($s); # remove leading whitespace
        $glob_this_token = 1;

        # have leading token with no quote delimeters?
        if ($s =~ /^([^\s$q]+)(\s.*$|$)/)
            {# token with no quote delimeter characters
            # $1 = non-whitespace/non-quote token
            # $2 = rest of string (with leading whitespace) [if exists]
            #print "1-push `$1` (g_ok = $glob_this_token)\n";
            push @argv2, $1;
            push @argv2_globok, $glob_this_token;
            $s = $2 ? $2 : q{};
            _ltrim($s);
            next;
            }

        # token contains quote delimeters
        Carp::Assert::assert( $s =~ /[$q]/ );
        my $t = q{};
        while ($s =~ /^[^\s]/)
            {# $s contains non-whitespace characters
            if ($s =~ /^((?:[^\s$q\$]|\$[^$q])*)((?:(\$([$q]))|[$q])?(.*))$/)
                {
                # initial non-quotes now removed
                # $1 = initial non-quote/non-whitespace characters (excepting '$<quote-char>')
                # $2 = rest of string after non-quote characters (including possible $<quote-char><...>)
                # $3 = $<quote-char> [if exists]
                # $4 = <quote-char> (of '$<quote-char>') [if exists]
                # $5 = rest of quoted string (and any extra following characters)
                #print "1.1 = `$1`\n" if $1;
                #print "1.2 = `$2`\n" if $2;
                #print "1.3 = `$3`\n" if $3;
                #print "1.4 = `$4`\n" if $4;
                #print "1.5 = `$5`\n" if $5;
                if ($1) { $t .= $1; }
                $s = $2 ? $2 : q{};
                _ltrim($s);
                if (! $s ) { last; }
                #if ($2) { $s = $2; } else {$s = q{}; last; }
                if ($3)
                    {# $'<...> or $"<...>
                    $s = $4.$5;
                    if ($s =~ /^($re_q_esc)(.*)$/)
                        {# $'...'
                        my $d_one = _decode($1);
                        my $two = $2;
                        #print "d_one = $d_one\n";
                        #if ($d_one =~ /[$gc]/) { $glob_this_token = 0; }
                        $glob_this_token = 0 if ($d_one =~ /[$gc]/);
                        $t .= _dequote($d_one);
                        $s = $two;
                        next;
                        }
                    if ($s =~ /^($re_qq)(.*)$/)
                        {# $"..."
                        #my $one = $1;
                        #my $two = $2;
                        #if ($one =~ /[$gc]/) { $glob_this_token = 0; } # globbing within ""'s is ok
                        #$t .= $one;
                        #$s = $two;
                        $t .= $1;
                        $s = $2;
                        next;
                        }
                    $t .= q{$}.$s;
                    $_unbalanced_command_line_quotes = 1;
                    $s = q{};
                    last;
                    }
                if ($s =~ /^(?:($re_noesc)(.*))|(.*)$/)
                    {
                    #print "2.1 = `$1`\n" if $1;
                    #print "2.2 = `$2`\n" if $2;
                    #print "2.3 = `$3`\n" if $3;
                    ##print "2.4 = `$4`\n" if $4;
                    #$t .= $1;
                    my $one = $1 ? $1 : q{};
                    my $two = $2 ? $2 : q{};
                    my $three = $3 ? $3 : q{};
                    if ($one)
                        {
                        #print "one = $one\n";
                        #if ($one =~ /^\'.*[$gc]+.*/) { $glob_this_token = 0; }
                        $glob_this_token = 0 if ($one =~ /^\'.*[$gc]+.*/);
                        $t .= _dequote($one);
                        $s = $two;
                        }
                    else { $t .= $three; $_unbalanced_command_line_quotes = 1; $s = q{}; last; }
                    #else { $t .= $4; $s = q{}; $_unbalanced_command_line_quotes = 1; last; }
                    }
                }
			else { Carp::croak q{no match: shouldn't get here...}; };
            }

        _ltrim($s);
        if ($t)
            {
            #print "2-push `$t` (g_ok = $glob_this_token)\n";
            push @argv2, $t;
            push @argv2_globok, $glob_this_token;
            next;
            }

        # no prior token match
        Carp::croak q{shouldn't get here...};
        #print "*-push `$s` (g_ok = $glob_this_token)\n";
        push @argv2, $s;
        push @argv2_globok, $glob_this_token;
        $s = q{};
        }

    #@argv2 = Text::Balanced::extract_multiple($command_line, [ qr/\s*([^\s'"]+)\s/, sub { _mytokens($_[0]) }, qr/\S+/ ], undef, 1);


    # remove $0 (and any prior entries) from ARGV array (and the matching glob signal array)
    my $n = _zero_position( $q, @argv2 );
    print "n = $n\n";
    @argv2 = @argv2[$n+1..$#argv2];
    @argv2_globok = @argv2_globok[$n+1..$#argv2_globok];

    # check for unbalanced quotes and croak if so...
    if ($_unbalanced_command_line_quotes) { Carp::croak 'Unbalanced command line quotes (at token `'.$argv2[-1].'`)'; }

    # do globbing
    my @argv2_g;
    for (my $i=0; $i<=$#argv2; $i++)		## no critic (ProhibitCStyleForLoops)
        {
        my @g;
        #print "argv2[$i] = $argv2[$i] (globok = $argv2_globok[$i])\n";
        my $pat = $argv2[$i];
        $pat =~ s/\\/\//g;      # change '\' to '/' within path for correct globbing [Win32]
        if ($pat =~ /\s/) { $pat = $_PG{'single_q'}.$pat.$_PG{'single_q'}; }
        #if ($argv2_globok[$i]) { @g = File::DosGlob::glob( $pat ) if $pat =~ /[$gc]/; }
        if ($argv2_globok[$i]) { @g = glob( $pat ) if $pat =~ /[$gc]/; }
        push @argv2_g, @g ? @g : $argv2[$i];        # default to non-nullglob
        }

    return @argv2_g;
}

####

#sub _mytokens
#{# parse tokens with one or more quotes (balanced or not)
## bash-like tokens ($'...' and $"...")
## ToDO: Rename => extract_quotedToken? remove_semiquoted? ...
## ToDO?: make more general specifying quote character sets
#my $textref = defined $_[0] ? \$_[0] : \$_;
#my $wantarray = wantarray;
#my $position = pos $$textref || 0;
#
##--- config
#my $unbalanced_as_seperate_last_arg = 0;       # if unbalanced quote exists, make it a last seperate argument (even if not seperated from last argument by whitespace)
##---
#
#my $r = q{};
#my $s = q{};
#my $p = q{};
#
#my $q = qq{\'\"};      # quote characters
#my $e = q$_PG{'escape_char'};        # quoted string escape character
#
#print "[in@($position)] = :$$textref: => :".substr($$textref, $position).":\n";
#if ($$textref =~ /\G(\s*)([\S]*['"]+.*)/g)
#   {# at least one quote character exists in the next token of the string; $1 = leading whitespace, $2 = string
#   $p = defined $1 ? $1 : q{};
#   $s = $2;
#   #print "prefix = '$p'\n";
#   #print "start = '$s'\n";
#   while ($s =~ m/^([^\s'"]*)(.*)$/)
#       {# $1 = non-whitespace prefix, $2 = quote + following characters
#       #print "1 = '$1'\n";
#       #print "2 = '$2'\n";
#       my $one = $1;
#       my $two = $2;
#       $r .= $one;
#       $s = $two;
#       if ($two =~ /^[^'"]/) {
#           #print "last (no starting quote)\n";
#           # shouldn't happen
#           last;
#           }
#       my ($tok, $suffix, $prefix) = Text::Balanced::extract_delimited($two);
#       #my ($tok, $suffix, $prefix) = _extract_delimited($two, undef, undef, '+');
#       #print "tok = '$tok'\n";
#       #print "suffix = '$suffix'\n";
#       #print "prefix = '$prefix'\n";
#       $r .= $tok;
#       $s = $suffix;
#       if ($tok eq q{}) {
#           #$Win32::CommandLine::_unbalanced_command_line_quotes = 1;
#           if (($r ne q{} && !$unbalanced_as_seperate_last_arg) || ($r eq q{})) {
#               $r .= $suffix; $s = q{};
#               }
#           #print "r = '$r'\n";
#           #print "s = '$s'\n";
#           #print "last (no tok)\n";
#           last;
#           }
#       #print "r = '$r'\n";
#       #print "s = '$s'\n";
#       if ($s =~ /^\s/) {
#           #print "last (s leading whitespace)\n";
#           last;
#           }
#       }
#   }
#
#my $posadvance = length($p) + length($r);
##print "posadvance = $posadvance\n";
##print "[out] = ('$r', '$s', '$p')\n";
#pos($$textref) = $position + $posadvance;
#return ($r, $s, $p);
#}

1; # Magic true value required at end of module

=for readme continue

=head1 SYNOPSIS

=for author_to_fill_in
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.

    @ARGV = Win32::CommandLine::argv() if eval { require Win32::CommandLine; };

    _or_

    use Win32::CommandLine qw( command_line );
    my $commandline = command_line();
    ...

=for readme stop

=head1 DESCRIPTION

=for author_to_fill_in
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.

This module is used to reparse the Win32 command line, automating better quoting and globbing of the command line.

=for readme continue

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

(On Windows platforms you should use C<nmake> instead.)

Alternatively, using Build.PL (if you have Module::Build installed):

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

PPM installation bundles should also be available in the ActiveState PPM archive.

Note: On ActivePerl installations, './Build install' will do a full installation using C<ppm> (see L<ppm>).

=for readme stop

=head1 INTERFACE

=for author_to_fill_in
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=head1 SUBROUTINES/METHODS

=for author_to_fill_in
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=head2 command_line()

C<command_line()> returns the full Win32 command line as a string.

=head2 argv()

C<argv()> returns the reparsed command line as an array.

=head1 IMPLEMENTATION and INTERNALS

#=h#ead2 wrap_GetCommandLine()
#
#[XS] Use C and Win32 API to get the command line.

=head1 DIAGNOSTICS

=for author_to_fill_in
    List every single error and warning message that the module can
    generate (even the ones that will ''never happen''), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back

=head1 CONFIGURATION AND ENVIRONMENT

=for author_to_fill_in
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

Win32::CommandLine requires no configuration files or environment variables.

=over

=item Optional Environment Variables

$ENV{WIN32_COMMANDLINE_RULE} = "sh" | "bash" (case doesn't matter) => argv will parse in "sh/bash" manner if set to "default"|"undef"
- will warn (not carp) if value unrecognized

=back

=for readme continue

=head1 DEPENDENCIES

=for author_to_fill_in
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.

=for readme stop

=head1 INCOMPATIBILITIES

=for author_to_fill_in
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author_to_fill_in
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Win32-CommandLine@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=for readme continue

=head1 AUTHOR

Roy Ivy III <rivy[at]cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Roy Ivy III <rivy[at]cpan.org>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=for readme stop

=begin IMPLEMENTATION-NOTES

BASH QUOTING
       Quoting is used to remove the special meaning of certain characters or words to the
       shell.  Quoting can be used to disable special treatment for special characters, to
       prevent  reserved  words  from  being  recognized as such, and to prevent parameter
       expansion.

       Each of the metacharacters listed above under DEFINITIONS has  special  meaning  to
       the shell and must be quoted if it is to represent itself.

       When the command history expansion facilities are being used (see HISTORY EXPANSION
       below), the history expansion character, usually !, must be quoted to prevent  his-
       tory expansion.

       There are three quoting mechanisms: the escape character, single quotes, and double
       quotes.

       A non-quoted backslash (\) is the escape character.  It preserves the literal value
       of  the  next character that follows, with the exception of <newline>.  If a \<new-
       line> pair appears, and the backslash is  not  itself  quoted,  the  \<newline>  is
       treated  as  a  line continuation (that is, it is removed from the input stream and
       effectively ignored).

       Enclosing characters in single quotes preserves the literal value of each character
       within  the  quotes.  A single quote may not occur between single quotes, even when
       preceded by a backslash.

       Enclosing characters in double quotes preserves the literal value of all characters
       within  the  quotes,  with the exception of $, `, \, and, when history expansion is
       enabled, !.  The characters $ and ` retain  their  special  meaning  within  double
       quotes.  The backslash retains its special meaning only when followed by one of the
       following characters: $, `, ", \, or <newline>.   A  double  quote  may  be  quoted
       within  double quotes by preceding it with a backslash.  If enabled, history expan-
       sion will be performed unless an !  appearing in double quotes is escaped  using  a
       backslash.  The backslash preceding the !  is not removed.

       The  special  parameters  *  and  @ have special meaning when in double quotes (see
       PARAMETERS below).

       Words of the form $'string' are treated specially.  The  word  expands  to  string,
       with  backslash-escaped  characters  replaced  as specified by the ANSI C standard.
       Backslash escape sequences, if present, are decoded as follows:
              \a     alert (bell)
              \b     backspace
              \e     an escape character
              \f     form feed
              \n     new line
              \r     carriage return
              \t     horizontal tab
              \v     vertical tab
              \\     backslash
              \'     single quote
              \nnn   the eight-bit character whose value is the octal value  nnn  (one  to
                     three digits)
              \xHH   the  eight-bit character whose value is the hexadecimal value HH (one
                     or two hex digits)
              \cx    a control-x character

       The expanded result is single-quoted, as if the dollar sign had not been present.

       A double-quoted string preceded by a dollar sign ($) will cause the  string  to  be
       translated  according  to the current locale.  If the current locale is C or POSIX,
       the dollar sign is ignored.  If the string is translated and replaced, the replace-
       ment is double-quoted.

EXPANSION
       Use "glob" to expand filenames.


SUMMARY
    '...'   => literal (no escapes and no globbing within quotes)
    $'...'  => ANSI C string escapes (\a, \b, \e, \f, \n, \r, \t, \v, \\, \', \n{1,3}, \xh{1,2}, \cx; all other \<x> =>\<x>)
    "..."   => literal (no escapes but allows internal globbing) [differs from bash]
    $"..."  => same as "..."
??? $"..."  => modified bash escapes (for $, ", \ only) and $ expansion (?$() shell escapes), no `` shell escapes, note: \<x> => \<x> unless <x> = {$, ", or <NL>}


=end IMPLEMENTATION-NOTES
