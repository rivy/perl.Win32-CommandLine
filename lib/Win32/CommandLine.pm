#-*- tab-width: 4; mode: perl -*-
package Win32::CommandLine;
#$Id$

## Perl::Critic policy exceptions
## no critic ( CodeLayout::ProhibitHardTabs CodeLayout::ProhibitParensWithBuiltins ProhibitPostfixControls RequirePodAtEnd )
## ---- policies to REVISIT later
## no critic ( RequireArgUnpacking RequireDotMatchAnything RequireExtendedFormatting RequireLineBoundaryMatching )

# TODO: make "\\sethra\c$\"* work (currently, have to "\\\\sethra\c$"\* or use forward slashes "//sethra/c$/"* ; two current problems ... \\ => \ (looks like it happens in the glob) and no globbing if the last backslash is inside the quotes)

use strict;
use warnings;
#use diagnostics;	# invoke blabbermouth warning mode
#use 5.006;

# VERSION: x.y[.date[.build]]  { y is odd = beta/experimental; y is even = release }
# NOTE: maximum build number = <unsigned int max (usually 32-bit) = 4,294,967,295> { as seconds => approx 49710 days or > 136 years }
use version qw(); our $VERSION = version::qv(qw( default-v 0.1 $Version$ )[-2]);	## no critic ( ProhibitCallsToUnexportedSubs ) ## [NOTE: "default-v 0.1" makes the code resilient vs missing keyword expansion]

# Module Summary

=head1 NAME

Win32::CommandLine - Retrieve and reparse the Win32 command line

=head1 VERSION

This document describes C<Win32::CommandLine> ($Version$).

=cut

# Module base/ISA and Exports

use base qw( DynaLoader Exporter );

#our @EXPORT = qw( );	# no default exported symbols
our %EXPORT_TAGS = (
	'ALL'		=> [ (grep { /^(?!bootstrap|dl_load_flags|isa|qv|bsd_glob|glob)[^_][a-zA-Z_]*[a-z]+[a-zA-Z_]*$/s } keys %Win32::CommandLine::) ],  ## no critic ( ProhibitComplexRegexes ) ## all non-internal symbols [Note: internal symbols are ALL_CAPS or start with a leading '_']
#	'INTERNAL'	=> [ (grep { /^(?!bootstrap|dl_load_flags|isa|qv|bsd_glob|glob)[_][a-zA-Z_]*[a-z]+[a-zA-Z_]*$/s } keys %Win32::CommandLine::) ],   ## no critic ( ProhibitComplexRegexes ) ## all internal functions [Note: internal functions start with a leading '_']
	);
our @EXPORT_OK = ( map { @{$_} } values %EXPORT_TAGS );

# Module Interface

sub command_line;	# return Win32 command line string
sub parse;			# parse string as a "bash-like" command line (globbing is done, but no other expansions or substitions)
sub argv;			# get commandline and reparse it, returning a new ARGV array

####

# Module Implementation

bootstrap Win32::CommandLine $VERSION;

sub command_line{
	# command_line(): returns $
	return _wrap_GetCommandLine();
}

sub argv{
	# argv(): returns @
	return parse( command_line() ); 	# get commandline and reparse it returning the new ARGV array
}

sub parse{
	# parse( $ [,\%] ): returns @
	# parse scalar as a command line string (bash-like parsing of quoted strings with globbing of resultant tokens, but no other expansions or substitutions are performed)
#	# [%]: an optional hash_ref containing function options as named parameters
#	#	nullglob = true/false [default = true] # if true, patterns which match no files are expanded to a null string, rather than the pattern itself
#	#TODO: ?rename (? parse_bash, ...)
#	 my %opt = (
##		'nullglob' => 1,
#		);
#
#	# read/expand optional named parameters
#	 my $me = (caller(0))[3];
#	 my $opt_ref;
#	 $opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));  # pop trailing argument only if it's a HASH reference (assumed to be options for our function)
#	 if ($opt_ref) { for (keys %{$opt_ref}) { if (defined $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown option '$_' to for function ".$me; } } }
#
#	my $s = shift @_;
#	return _argv( $s, { %opt } );
	return _argv( @_ );
}

use	Carp qw();
use	Carp::Assert qw();
#use Regexp::Autoflags;
#use Readonly;
#use Getopt::Clade;
#use Getopt::Euclid;
#use Class::Std;

use	File::Spec qw();
use	File::Which qw();

use	Data::Dumper::Simple;

my %_G = ( # package globals
	 q					=> q{'},					# '
	qq					=> q{"},					# "
	single_q			=> q{'},					# '
	double_q			=> q{"},					# "
	quote				=> q{'"},					# ' and "
	quote_meta			=> quotemeta q{'"},			# quotemeta ' and "
	escape_char			=> q{\\},					# escape character (\)
	glob_char			=> '?*[]{}',				# glob signal characters (no '~' for Win32)
	unbalanced_quotes	=> 0,
	);

{
sub _decode; # _decode( <null>|$|@ ): returns <null>|$|@ ['shortcut' function]
my %table;
###
#Escape Sequences
#\\	- 0x5c - Backslash
#\'	- 0x27 - Single Quote (not sure if it is hex 27 ???)
#\"	- 0x22 - Double Quote (not sure if it is hex 22 ???)
#\?	- 0x3f - Question Mark
#\0	- 0x00 - null
#\a	- 0x07 - Alert = Produces an audible or visible alert.
#\b	- 0x08 - Backspace = Moves the cursor back one position (non-destructive).
#\f	- 0x0c - Form Feed = Moves the cursor to the first position of the next page.
#\n	- 0x0a - New Line = Moves the cursor to the first position of the next line.
#\r	- 0x0d - Carriage Return = Moves the cursor to the first position of the current line.
#\t	- 0x09 - Horizontal Tab = Moves the cursor to the next horizontal tabular position.
#\v	- 0x0b- Vertical Tab = Moves the cursor to the next vertical tabular position.
#
#Numeric Escape Sequences
#\nnn - n = octal digit, 8 bit
#\xnn - n = hexadecimal digit, 8 bit
#\Xnn - n = hexadecimal digit, 8 bit
#\unnnn - n = hexadecimal digit, 16 bit
#\Unnnnnnnn - n = hexadecimal digit, 32 bit###
#			   \a	  alert (bell)
#			   \b	  backspace
#			   \e	  an escape character
#			   \f	  form feed
#			   \n	  new line
#			   \r	  carriage return
#			   \t	  horizontal tab
#			   \v	  vertical tab
#			   \\	  backslash
#			   \'	  single quote
#			   \nnn	  the eight-bit character whose value is the octal value  nnn  (one  to
#					  three digits)
#			   \xHH	  the  eight-bit character whose value is the hexadecimal value HH (one
#					  or two hex digits)
#			   \XHH	  the  eight-bit character whose value is the hexadecimal value HH (one
#					  or two hex digits)
#			   \cx	  a control-x character
#
# Not implemented (not used in bash):
#\unnnn - n = hexadecimal digit, 16 bit
#\Unnnnnnnn - n = hexadecimal digit, 32 bit
## n#o critic ( ProhibitMagicNumbers )

$table{'0'}	= chr(0x00);	## no critic ( ProhibitMagicNumbers ) 	# NUL (REMOVE: implemented with octal section)
$table{'a'}	= "\a";													# BEL
$table{'b'}	= "\b";													# BS
$table{'e'}	= "\e";													# ESC
$table{'f'}	= "\f";													# FF
$table{'n'}	= "\n";													# NL
$table{'r'}	= "\r";													# CR
$table{'t'}	= "\t";													# TAB/HT
$table{'v'}	= chr(0x0b);	## no critic ( ProhibitMagicNumbers ) 	# VT

$table{$_G{'single_q'}}	= $_G{single_q};			# single-quote
$table{$_G{'double_q'}}	= $_G{double_q};			# double-quote
$table{$_G{'escape_char'}} = $_G{escape_char};		# backslash-escape

#octal
#	for (my $i = 0; $i < oct('1000'); $i++) { $table{sprintf("%3o",$i)} = chr($i); }
for my $i (0..oct('777')) { $table{sprintf('%3o',$i)} = chr($i); }

#hex
#	for (my $i = 0; $i < 0x10; $i++) { $table{"x".sprintf("%1x",$i)} = chr($i); $table{"X".sprintf("%1x",$i)} = chr($i); $table{"x".sprintf("%2x",$i)} = chr($i); $table{"X".sprintf("%2x",$i)} = chr($i); }
#	for (my $i = 0x10; $i < 0x100; $i++) { $table{"x".sprintf("%2x",$i)} = chr($i); $table{"X".sprintf("%2x",$i)} = chr($i); }
for my $i (0..0xf) { $table{'x'.sprintf('%1x',$i)} = chr($i); $table{'X'.sprintf('%1x',$i)} = chr($i); $table{'x'.sprintf('%2x',$i)} = chr($i); $table{'X'.sprintf('%2x',$i)} = chr($i); }		## no critic ( ProhibitMagicNumbers ) ##
for my $i (0x10..0xff) { $table{'x'.sprintf('%2x',$i)} = chr($i); $table{'X'.sprintf('%2x',$i)} = chr($i); }																					## no critic ( ProhibitMagicNumbers ) ##

#control characters
#	for (my $i = 0; $i < 0x20; $i++) { $table{"c".chr(ord('@')+$i)} = chr($i); }
my $base_char = ord(q{@});
for my $i (0..(0x20 - 1)) { $table{'c'.chr($base_char+$i)} = chr($i); }		## no critic ( ProhibitMagicNumbers ) ##
$table{'c?'} = chr(0x7f);													## no critic ( ProhibitMagicNumbers ) ##

sub	_decode {
	# _decode( <null>|$|@ ): returns <null>|$|@ ['shortcut' function]
	# decode ANSI C string
	@_ = @_ ? @_ : $_ if defined wantarray;		## no critic (ProhibitPostfixControls)	## break aliasing if non-void return context

	my $c = '0abefnrtv'.$_G{'escape_char'}.$_G{single_q}.$_G{double_q};
	for (@_ ? @_ : $_) { s/\\([$c]|[0-7]{1,3}|x[0-9a-fA-F]{2}|X[0-9a-fA-F]{2}|c.)/$table{$1}/g }

	return wantarray ? @_ : "@_";
	}
}

sub	_is_const { my $is_const = !eval { ($_[0]) = $_[0]; 1; }; return $is_const; }

sub	_ltrim {
	# _ltrim( $|@ [,\%] ): returns $|@ ['shortcut' function] (with optional hash_ref containing function options)
	# trim leading characters (defaults to whitespace)
	# NOTE: not able to currently determine the difference between a function call with a zero arg list {"f(());"} and a function call with no arguments {"f();"}
	#		so, by the Principle of Least Surprise, f() in void context is disallowed instead of being an alias of "f($_)" so that f(@array) doesn't silently perform f($_) when @array has zero elements
	#		use "f($_)" instead of "f()" when needed
	#		carp on both
	# NOTE: alternatively, could use _ltrim( <null>|$|\@[,\%] ), carping onaamore than one argument
	# NOTE: alternatively, could use _ltrim( <null>|$|@|\@[,\%] ), carping on more than one argument
	# NOTE: after thinking and reading PBP (specifically Dollar-Underscore (p85) and Interator Variables (p105)), I think disallowing zero arguments is for the best.
	#		making operation on $_ require explicit coding breeds more maintainable code with little extra effort
	# so:
	#	$foo = _ltrim($bar);
	#	@foo = _ltrim(@bar) if @bar;
	#	$foo = _ltrim(@bar) if @bar;
	#	_ltrim($bar);
	#	_ltrim(@bar) if @bar;
	#	$foo = _ltrim($_);
	#	_ltrim($_);
	#	@bar = (); $xxx = ltrim(@bar);	## ERROR
	#	$xxx = ltrim();					## ERROR
	#	ltrim();						## ERROR
	my %opt	= (
		trim_re => '\s+',
		);

	my $me = (caller(0))[3];	## no critic ( ProhibitMagicNumbers )	## caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
	my $opt_ref;
	$opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));	## no critic (ProhibitPostfixControls)	## pop last argument only if it's a HASH reference (assumed to be options for our function)
	if ($opt_ref) { for (keys %{$opt_ref}) { if (exists $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown option '$_' for function ".$me; return; } } }
	if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me."($_) instead?)"; return; }
	if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

	my $t = $opt{trim_re};

	my $arg_ref;
	$arg_ref = \@_;
	$arg_ref = [ @_ ] if defined wantarray;		## no critic (ProhibitPostfixControls)	## break aliasing if non-void return context

	for	my $arg ( @{$arg_ref} ) {
		if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
		$arg =~ s/\A$t//;
		}

	return wantarray ? @{$arg_ref} : "@{$arg_ref}";
	}

sub	_gen_delimeted_regexp {
	# _gen_delimeted_regexp ( $delimiters, $escapes ): returns $
	# from "Mastering Regular Expressions, 2e; p. 281" and modified from Text::Balanced::gen_delimited_pat($;$) [v1.95]
	# $DOUBLE = qr{"[^"\\]+(?:\\.[^"\\]+)+"};
	# $SINGLE = qr{'[^'\\]+(?:\\.[^'\\]+)+'};
	## no critic (ControlStructures::ProhibitCStyleForLoops)
	my ($dels, $escs) = @_;
	return q{} unless $dels =~ /^\S+$/;		## no critic (ProhibitPostfixControls)
	$escs =	q{}	unless $escs;				## no critic (ProhibitPostfixControls)

	#print "dels = $dels\n";
	#print "escs = $escs\n";

	my @pat	= ();
	for	(my	$i=0; $i<length	$dels; $i++)
		{
			my $d =	quotemeta substr($dels,$i,1);
			if ($escs)
				{
				for	(my	$j=0; $j < length $escs; $j++)
					{
					my $e =	quotemeta substr($escs,$j,1);
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
			else { push	@pat, "$d(?:[^$d]*)$d";	}
		}
	my $pat	= join q{|}, @pat;

	return "(?:$pat)";
	}

sub	_dequote{
	# _dequote(	<null>|$|@ [,\%] ):	returns	<null>|$|@ ['shortcut' function] (with optional	hash_ref containing	function options)
	# trim balanced	outer quotes
	# $opt{'surround_re'} =	'whitespace' surround which	is removed	[default = '\s*']
	# $opt{'allowed_quotes_re'}	= balanced 'quote' delimeters which	are	removed	[default = q{['"]} ]

	my %opt	= (
		surround_re			=> '\s*',
		allowed_quotes_re	=> '['.$_G{quote_meta}.']',
		_return_quote		=>	0,							# true/false [ default = false ], if true, return quote as first character in returned array
		);

	my $me = (caller(0))[3];	## no critic ( ProhibitMagicNumbers )	## caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
	my $opt_ref;
	$opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));	## no critic (ProhibitPostfixControls)	## pop last	argument only if it's a	HASH reference (assumed	to be options for our function)
	if ($opt_ref) {	for	(keys %{$opt_ref}) { if	(exists	$opt{$_}) {	$opt{$_} = $opt_ref->{$_}; } else {	Carp::carp "Unknown	option '$_'	to for function	".$me; } } }

	my $w =	$opt{surround_re};
	my $q =	$opt{allowed_quotes_re};
	my $quoter = q{};

	@_ = @_	? @_ : $_ if defined wantarray;		## no critic (ProhibitPostfixControls)	## break aliasing if non-void return context

	for	(@_	? @_ : $_)
		{
		s/^$w($q)(.*)\1$w$/$2/;
		if (defined($1)) { $quoter = $1; }
		#print "_ = $_\n";
		}

	if ( $opt{_return_quote} )
		{
		unshift @_, $quoter;
		#print "quoter = $quoter\n";
		#print "_ = @_\n";
		}

	return wantarray ? @_ :	"@_";
	}

sub	_zero_position {
	use	English	qw(	-no_match_vars ) ;	# '-no_match_vars' avoids regex	performance	penalty
	my $q =	shift @_;
	my @args = @_;
	my $pos;
	# find $0 in the ARGV array
	#print "0 =	$0\n";
	#win32 - filenames are case-preserving but case-insensitive	[so, case doesn't matter]
	my $zero = $PROGRAM_NAME;	   ## no critic	(Variables::ProhibitPunctuationVars)
	my $zero_lc	= lc($zero);
	my $zero_dq	= _dequote($zero_lc);  # dequoted $0

	#print "zero = $zero\n";
	#print "zero_lc	= $zero_lc\n";
	#print "zero_dq	= $zero_dq\n";

#	while (my $arg = shift @a) {
	for	($pos=0; $pos<$#args; $pos++) {		## no critic (ProhibitCStyleForLoops)
		my $arg	= $args[$pos];
#	 for my	$arg (@a) {
		#print "arg	= $arg\n";
		if ($zero_lc eq	lc($arg))
			{ #	direct match
			#print "\tMATCH	(direct)\n";
			last;
			}
		$arg =~	s/([$q])(.*)\1/$2/;
		#print "arg	= $arg\n";
		if ($zero_lc eq	lc($arg))
			{ #	dequoted match
			#print "\tMATCH	(dequoted)\n";
			last;
			}
		#print 'rel2abs(arg) = '.File::Spec->rel2abs($arg)."\n";
		if (-e $arg	&& (lc(File::Spec->rel2abs(	$zero_dq ))	eq lc(File::Spec->rel2abs( $arg	))))
			{ #	rel2abs	match
			#print "\tMATCH	(rel2abs)\n";
			last;
			}
		if (!-e	$arg)
			{ #	find file on PATH with File::Which (needed for compiled	perl executables)
			my ($fn, $r);
			my ($split_1, $split_2);
			($split_1, $split_2, $fn) =	File::Spec->splitpath( $arg	);
			#print "split_1	= $split_1\n";
			#print "split_2	= $split_2\n";
			#print "fn = $fn\n";
			$r = File::Which::which($fn);
			if (defined	$r)	{ $r = File::Spec->rel2abs(	$r ); }
			#print $arg."\t\t=(find	with which)> ".((defined $r) ? $r :	"undef");
			if (lc($r) eq lc(File::Spec->rel2abs($zero)))
				{# which found
				#print "\tMATCH	(which)\n";
				last;
				}
			}
		#print "\n";
		}

	return $pos;
}

sub	_argv_parse{}
sub	_argv_do_glob{}
sub	_zero_position_NEW{}
sub	_argv_NEW{
	# _argv( $ [,\%] ):	returns	@
	# parse	scalar as a	command	line string	(bash-like parsing of quoted strings with globbing of resultant	tokens,	but	no other expansions	or substitutions are performed)
	# [%]: an optional hash_ref	containing function	options	as named parameters
	#	nullglob = true/false [default = true]	# if true, patterns	which match	no files are expanded to a null	string,	rather than	the	pattern	itself
	my %opt	= (
		'nullglob' => 0,
		);

	# read/expand optional named parameters
	my $me = (caller(0))[3];	## no critic ( ProhibitMagicNumbers )	## caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
	my $opt_ref;
	$opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));	# pop trailing argument	only if	it's a HASH	reference (assumed to be options for our function)
	if ($opt_ref) {	for	(keys %{$opt_ref}) { if	(defined $opt{$_}) { $opt{$_} =	$opt_ref->{$_};	} else { Carp::carp	"Unknown option	'$_' to	for	function ".$me;	} }	}

	my $command_line = shift @_;

	# parse	tokens from	the	$command_line string
	my %argv2 =	_argv_parse( $command_line );

	# remove $0	(and any prior entries)	from ARGV array	(and the matching glob_ok signal array)
	my $p =	_zero_position_NEW(	\%argv2	);
	#print "p =	$p\n";
	my $n =	scalar($argv2{'argv'});
	#print "n =	$n\n";
  ##$argv2{'argv'} = $argv2{'argv'}[ $p+1..$n ];
  ##$argv2{'glob_ok'} =	$argv2{'glob_ok'}[ $p+1..$n	];

	# check	for	unbalanced quotes and croak	if so...
	if ($_G{'unbalanced_quotes'}) {	Carp::croak	'Unbalanced	command	line quotes	(at	token `'.$argv2{'argv'}[-1].'`)'; }

	# do globbing
	my @argv2_g	= _argv_do_glob( \%argv2 );

	return @argv2_g;
}

sub	_quote_gc_meta{
	my $s =	shift @_;
#	my $gc = $_G{glob_char};

	my $gc = quotemeta(	'?*[]{}~'.q{\\} );
#	my $dgc	= quotemeta	( '?*' );

#	$s =~ s/\\/\//g;						# replace all backslashes with forward slashes
#	$s =~ s/([$gc])/\\$1/g;					# backslash quote all metacharacters (note: there should be no backslashes to quote)

#	$s =~ s/([$gc])/\\$1/g;					# backslash quote all metacharacters (backslashes are ignored)
	$s =~ s/([$gc])/\\$1/g;					# backslash quote all glob metacharacters (backslashes as well)

#	$s =~ s/([$dgc])/\\\\\\\\\\$1/g;		# see Dos::Glob	notes for literally	quoting	'*'	or '?'	## doesn't work	for	Win32 (? only MacOS)

	return $s;
}

sub	_argv{	## no critic ( Subroutines::ProhibitExcessComplexity )
	# _argv( $command_line )

	# [seperated for testing]
	# '...'		=> literal (no escapes and no globbing within quotes)
	# $'...'	=> ANSI	C string escapes (\a, \b, \e, \f, \n, \r, \t, \v, \\, \', \n{1,3}, \xh{1,2}, \cx; all other	\<x> =>\<x>), no globbing within quotes
	##NOT# "..." =>	literal	(no	escapes	but	allows internal	globbing) [differs from	bash]
	# "..."	  => literal (no escapes and no	globbing within	quotes)
	# $"..."  => same as "..."
	# globbing is only done	for	non-quoted glob	characters

	# TODO:	Change semantics so	that "..." has no internal globbing	(? unless has at least one non-quoted glob character, vs what to do	with combination quoted	and	non-quoted glob	characters)
	#		only glob bare (non-quoted)	characters

	# _argv( $ [,\%] ):	returns	@
	# parse	scalar as a	command	line string	(bash-like parsing of quoted strings with globbing of resultant	tokens,	but	no other expansions	or substitutions are performed)
	# [%]: an optional hash_ref	containing function	options	as named parameters
	my %opt	= (
		nullglob => 0,				# = true/false [default = false]	# if true, patterns	which match	no files are expanded to a null	string (no token), rather than	the	pattern	itself
		_glob_within_qq => 0,		# = true/false [default = false]	# <private> if true, globbing within double quotes is performed, rather than only for "bare"/unquoted glob characters
		_carp_unbalanced => 1,		# = true/false [default = true]		# <private> if true, carp for unbalanced command line quotes
		);

	# read/expand optional named parameters
	my $me = (caller(0))[3];	## no critic ( ProhibitMagicNumbers )	## caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);

	my $opt_ref;
	$opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));	# pop trailing argument	only if	it's a HASH	reference (assumed to be options for our function)
	if ($opt_ref) {	for	(keys %{$opt_ref}) { if	(defined $opt{$_}) { $opt{$_} =	$opt_ref->{$_};	} else { Carp::carp	"Unknown option	'$_' to	for	function ".$me;	} }	}

	my @argv2;
	my @argv2_globok;			# glob signal per argv2	entry

	my @argv_3;					# [] of	[](token =>	<token_portion>, glob => glob_this)

	my $sq = $_G{single_q};			   # single	quote (')
	my $dq = $_G{double_q};			   # double	quote (")
	my $quotes = $sq.$dq;					# quote	chars ('")
	my $q =	quotemeta $quotes;

	my $gc = quotemeta ( $_G{glob_char} );  #	glob signal	characters

	my $escape = $_G{escape_char};

	my $_unbalanced_command_line_quotes	= 0;

	my $re_q_escok = _gen_delimeted_regexp(	$sq, $escape );	# regexp for single	quoted string with internal	escaped	characters allowed
	my $re_q	= _gen_delimeted_regexp( $sq );				# regexp for single	quoted string (no internal escaped characters)
	my $re_qq	= _gen_delimeted_regexp( $dq );				# regexp for double	quoted string (no internal escaped characters)
	my $re_qqq	= _gen_delimeted_regexp($quotes);			# regexp for any-quoted	string (no internal	escaped	characters)

	#print "re_esc = $re_q_escok\n";
	#print "re_qq =	$re_qq\n";
	#print "re_q = $re_q\n";
	#print "re_qqq = $re_qqq\n";

	#my	$re_superescape	= _gen_delimeted_regexp($quotes, "\\#");
	#print "re_superescape = $re_superescape\n";

	my $command_line = shift @_;	# "extract_..."	is destructive of the original string
	my $s =	$command_line;
	my $glob_this_token	= 1;
	while ($s ne q{})
		{
		# $s ==	string being parsed
		# $t ==	partial	or full	token

		my $t =	q{};

		#print "s =	`$s`\n";

		_ltrim($s);	# remove leading whitespace
		$glob_this_token = 1;
		my $i =	scalar(@argv_3);

		if ($s =~ /^([^\s$q]+)(\s.*$|$)/)
			{# simple leading full token with no quote delimeter characters
			# $1 = non-whitespace/non-quote	token
			# $2 = rest	of string (with	leading	whitespace)	[if	exists]
			#print "1-push `$1`	(g_ok =	$glob_this_token)\n";
			$t = $1;
			#push @argv2, $1;
			#push @argv2_globok, $glob_this_token;
			#print "1-push (simple:token): token => $1, glob => 1\n";
			push @{	$argv_3[ scalar(@argv_3) ] }, {	token => $1, glob => 1,	id => 'simple:token' };
			$s = defined($2) ? $2 : q{};
			#_ltrim($s);
			#next;
			}
		else
			{
			# complex token	containing quote delimeters
			Carp::Assert::assert( $s =~	/[$q]/ );
			#my	$t = q{};
			while ($s =~ /^[^\s]/)
				{# parse full token	containing quote delimeters
				# $s contains non-whitespace characters	and	starts with	non-whitespace
				if ($s =~ /^((?:[^\s$q\$]|\$[^$q])*)((?:(\$([$q]))|[$q])?(.*))$/)
					{
					# initial non-quotes now seperated
					# $1 = initial non-quote/non-whitespace	characters (excepting any '$<quote-char>')
					# $2 = rest	of string after	non-quote characters (including	possible $<quote-char><...>)
					# $3 = $<quote-char> [if exists]
					# $4 = <quote-char>	(of	'$<quote-char>') [if exists]
					# $5 = rest	of quoted string (and any extra	following characters)
					#print "1.1	= `$1`\n" if defined($1);
					#print "1.2	= `$2`\n" if defined($2);
					#print "1.3	= `$3`\n" if defined($3);
					#print "1.4	= `$4`\n" if defined($4);
					#print "1.5	= `$5`\n" if defined($5);
					if ( defined($1) && length($1) > 0 )	{
						$t .= $1;
						#print "1-push (complex:leading non-quoted+whitespace): token => $1, glob => 1\n";
						push @{	$argv_3[ $i	] }, { token =>	$1,	glob =>	1, id => 'complex:leading non-quoted+whitespace' };
						}
					$s = defined($2) ? $2 : q{};
					#_ltrim($s);
					if ( $s	=~ /^[\s]/ || _ltrim($s) eq	q{}	) {	last; }
					#if	($2) { $s =	$2;	} else {$s = q{}; last;	}
					if ( defined($3) )
						{# $'<...> or $"<...>
						## no critic ( ProhibitDeepNests )
						$s = $4.$5;
						if ($s =~ /^($re_q_escok)(.*)$/)
							{# $'...'
							my $d_one =	_decode($1);
							my $two	= $2;
							#print "d_one =	$d_one\n";
							#if	($d_one	=~ /[$gc]/)	{ $glob_this_token = 0;	}
							$glob_this_token = 0 if	($d_one	=~ /[$gc]/);		## no critic (ProhibitPostfixControls)
							$t .= _dequote($d_one);
							$s = $two;
							#print "1-push (complex:re_q_escok): token => $1, glob => 1\n";
							push @{	$argv_3[ $i	] }, { token =>	_dequote($d_one), glob => 0, id	=> 'complex:re_q_escok'	};
							next;
							}
						if ($s =~ /^($re_qq)(.*)$/)
							{# $"..."
							#my	$one = $1;
							#my	$two = $2;
							#if	($one =~ /[$gc]/) {	$glob_this_token = 0; }	# globbing within ""'s is ok
							#$t	.= $one;
							#$s	= $two;
							$t .= $1;
							$s = $2;
							#print "1-push (complex:re_qq): token => $1, glob => $opt{_glob_within_qq}\n";
							push @{	$argv_3[ $i	] }, { token =>	$1,	glob =>	$opt{_glob_within_qq}, id => 'complex:re_qq' };
							next;
							}
						$t .= q{$}.$s;
						$_unbalanced_command_line_quotes = 1;
						$s = q{};
						last;
						}
					if ($s =~ /^(?:($re_qqq)(.*))|(.*)$/)
						{
						## no critic ( ProhibitDeepNests )
						#print "2.1	= `$1`\n" if $1;
						#print "2.2	= `$2`\n" if $2;
						#print "2.3	= `$3`\n" if $3;
						#print	"2.4 = `$4`\n" if $4;
						#$t	.= $1;
						my $one	= defined($1) ? $1 : q{};
						my $two	= defined($2) ? $2 : q{};
						my $three =	defined($3) ? $3 : q{};
						if ($one)
							{
							my $quote;
							my $dequoted_token;
							my $glob_this_token = 0;
							#print "one	= $one\n";
							#if	($one =~ /^\'.*[$gc]+.*/) {	$glob_this_token = 0; }
							#$glob_this_token = 0 if	($one =~ /^\'.*[$gc]+.*/);		## no critic (ProhibitPostfixControls)
							( $quote, $dequoted_token ) = _dequote($one, {_return_quote => 1});
							#$dequoted_token = _dequote($one);
							$glob_this_token = $opt{_glob_within_qq} && ($quote eq $_G{qq});
							$t .= $dequoted_token;
							$s = $two;
							#print "1-push (complex:noescapes): token => $one{dequoted}, glob => $glob_this_token\n";
							push @{	$argv_3[ $i ] }, { token => _dequote($one), glob =>	$glob_this_token, id => 'complex:noescapes' };
							}
						else {
							$t .= $three; $_unbalanced_command_line_quotes = 1; $s = q{};
							#print "1-push (complex:NON-quoted/unbalanced): token => $three, glob => 1\n";
							push @{	$argv_3[ $i	] }, { token => $three, glob => 1, id => 'complex:NON-quoted/unbalanced' };
							last;
							}
						#else { $t .= $4; $s = q{}; $_unbalanced_command_line_quotes = 1; last; }
						}
					}
				else { Carp::croak q{no	match: shouldn't get here...}; };
				}
			}

		_ltrim($s);
		if ( defined($t) )
			{
			#print "2-push `$t`	(g_ok =	$glob_this_token)\n";
			push @argv2, $t;
			push @argv2_globok, $glob_this_token;
			#push @{ $argv_3[ $i ] }, { token => $t, glob => 1, id => '$t' };
			next;
			}

		# no prior token match
		Carp::croak q{shouldn't	get	here...};
		#print "*-push `$s`	(g_ok =	$glob_this_token)\n";
		push @argv2, $s;
		push @argv2_globok,	$glob_this_token;
		push @{ $argv_3[ scalar(@argv_3) ] }, { token => $s, glob => 1,	id => 'WRONG:$s (shouldn\'t get here)' };		## no critic (RequireInterpolationOfMetachars)
		$s = q{};
		}

	#@argv2	= Text::Balanced::extract_multiple($command_line, [	qr/\s*([^\s'"]+)\s/, sub { _mytokens($_[0]) }, qr/\S+/ ], undef, 1);

	#print "" . Dumper( @argv_3 )."\n";

	# remove $0 (and any prior entries) from ARGV array (and the matching glob signal array)
	my $n = _zero_position(	$q,	@argv2 );
	#print "n = $n\n";
	@argv2 = @argv2[$n+1..$#argv2];
	@argv2_globok =	@argv2_globok[$n+1..$#argv2_globok];

	# check	for	unbalanced quotes and croak	if so...
	if ($opt{_carp_unbalanced} && $_unbalanced_command_line_quotes) { Carp::croak 'Unbalanced command line quotes (at token `'.$argv2[-1].'`)'; }

	# do globbing
#META CHARACTERS
#
#  \       Quote the next metacharacter
#  []      Character class
#  {}      Multiple pattern
#  *       Match any string of characters
#  ?       Match any single character
#  ~       User name home directory
#
#The metanotation a{b,c,d}e is a shorthand for abe ace ade. Left to right order is preserved, with results of matches being sorted separately at a low level to preserve this order. As a special case {, }, and {} are passed undisturbed.
#
#POSIX FLAGS
#
#The POSIX defined flags for bsd_glob() are:
#
#GLOB_ERR
#
#    Force bsd_glob() to return an error when it encounters a directory it cannot open or read. Ordinarily bsd_glob() continues to find matches.
#GLOB_LIMIT
#
#    Make bsd_glob() return an error (GLOB_NOSPACE) when the pattern expands to a size bigger than the system constant ARG_MAX (usually found in limits.h). If your system does not define this constant, bsd_glob() uses sysconf(_SC_ARG_MAX) or _POSIX_ARG_MAX where available (in that order). You can inspect these values using the standard POSIX extension.
#GLOB_MARK
#
#    Each pathname that is a directory that matches the pattern has a slash appended.
#GLOB_NOCASE
#
#    By default, file names are assumed to be case sensitive; this flag makes bsd_glob() treat case differences as not significant.
#GLOB_NOCHECK
#
#    If the pattern does not match any pathname, then bsd_glob() returns a list consisting of only the pattern. If GLOB_QUOTE is set, its effect is present in the pattern returned.
#GLOB_NOSORT
#
#    By default, the pathnames are sorted in ascending ASCII order; this flag prevents that sorting (speeding up bsd_glob()).
#
#The FreeBSD extensions to the POSIX standard are the following flags:
#
#GLOB_BRACE
#
#    Pre-process the string to expand {pat,pat,...} strings like csh(1). The pattern '{}' is left unexpanded for historical reasons (and csh(1) does the same thing to ease typing of find(1) patterns).
#GLOB_NOMAGIC
#
#    Same as GLOB_NOCHECK but it only returns the pattern if it does not contain any of the special characters "*", "?" or "[". NOMAGIC is provided to simplify implementing the historic csh(1) globbing behaviour and should probably not be used anywhere else.
#GLOB_QUOTE
#
#    Use the backslash ('\') character for quoting: every occurrence of a backslash followed by a character in the pattern is replaced by that character, avoiding any special interpretation of the character. (But see below for exceptions on DOSISH systems).
#GLOB_TILDE
#
#    Expand patterns that start with '~' to user name home directories.
#GLOB_CSH
#
#    For convenience, GLOB_CSH is a synonym for GLOB_BRACE | GLOB_NOMAGIC | GLOB_QUOTE | GLOB_TILDE | GLOB_ALPHASORT.
#
#The POSIX provided GLOB_APPEND, GLOB_DOOFFS, and the FreeBSD extensions GLOB_ALTDIRFUNC, and GLOB_MAGCHAR flags have not been implemented in the Perl version because they involve more complex interaction with the underlying C structures.
#
#The following flag has been added in the Perl implementation for csh compatibility:
#
#GLOB_ALPHASORT
#
#    If GLOB_NOSORT is not in effect, sort filenames is alphabetical order (case does not matter) rather than in ASCII order.
#
#DIAGNOSTICS
#
#bsd_glob() returns a list of matching paths, possibly zero length. If an error occurred, &File::Glob::GLOB_ERROR will be non-zero and $! will be set. &File::Glob::GLOB_ERROR is guaranteed to be zero if no error occurred, or one of the following values otherwise:
#
#GLOB_NOSPACE
#
#    An attempt to allocate memory failed.
#GLOB_ABEND
#
#    The glob was stopped because an error was encountered.
#
#In the case where bsd_glob() has found some matching paths, but is interrupted by an error, it will return a list of filenames and set &File::Glob::ERROR.
#
#Note that bsd_glob() deviates from POSIX and FreeBSD glob(3) behaviour by not considering ENOENT and ENOTDIR as errors - bsd_glob() will continue processing despite those errors, unless the GLOB_ERR flag is set.
#
#Be aware that all filenames returned from File::Glob are tainted.
#
#
#NOTES
#
#    *
#
#      If you want to use multiple patterns, e.g. bsd_glob("a* b*"), you should probably throw them in a set as in bsd_glob("{a*,b*}"). This is because the argument to bsd_glob() isn't subjected to parsing by the C shell. Remember that you can use a backslash to escape things.
#    *
#
#      On DOSISH systems, backslash is a valid directory separator character. In this case, use of backslash as a quoting character (via GLOB_QUOTE) interferes with the use of backslash as a directory separator. The best (simplest, most portable) solution is to use forward slashes for directory separators, and backslashes for quoting. However, this does not match "normal practice" on these systems. As a concession to user expectation, therefore, backslashes (under GLOB_QUOTE) only quote the glob metacharacters '[', ']', '{', '}', '-', '~', and backslash itself. All other backslashes are passed through unchanged.
#    *
#
#      Win32 users should use the real slash. If you really want to use backslashes, consider using Sarathy's File::DosGlob, which comes with the standard Perl distribution.
#    *
#
#      Mac OS (Classic) users should note a few differences. Since Mac OS is not Unix, when the glob code encounters a tilde glob (e.g. ~user) and the GLOB_TILDE flag is used, it simply returns that pattern without doing any expansion.
#
#      Glob on Mac OS is case-insensitive by default (if you don't use any flags). If you specify any flags at all and still want glob to be case-insensitive, you must include GLOB_NOCASE in the flags.
#
#      The path separator is ':' (aka colon), not '/' (aka slash). Mac OS users should be careful about specifying relative pathnames. While a full path always begins with a volume name, a relative pathname should always begin with a ':'. If specifying a volume name only, a trailing ':' is required.
#
#      The specification of pathnames in glob patterns adheres to the usual Mac OS conventions: The path separator is a colon ':', not a slash '/'. A full path always begins with a volume name. A relative pathname on Mac OS must always begin with a ':', except when specifying a file or directory name in the current working directory, where the leading colon is optional. If specifying a volume name only, a trailing ':' is required. Due to these rules, a glob like <*:> will find all mounted volumes, while a glob like <*> or <:*> will find all files and directories in the current directory.
#
#      Note that updirs in the glob pattern are resolved before the matching begins, i.e. a pattern like "*HD:t?p::a*" will be matched as "*HD:a*". Note also, that a single trailing ':' in the pattern is ignored (unless it's a volume name pattern like "*HD:"), i.e. a glob like <:*:> will find both directories and files (and not, as one might expect, only directories). You can, however, use the GLOB_MARK flag to distinguish (without a file test) directory names from file names.
#
#      If the GLOB_MARK flag is set, all directory paths will have a ':' appended. Since a directory like 'lib:' is not a valid relative path on Mac OS, both a leading and a trailing colon will be added, when the directory name in question doesn't contain any colons (e.g. 'lib' becomes ':lib:').
#
#
	my @argv2_g;
	my $glob_this;
	for	(my $i=0; $i<=$#argv2; $i++)		## no critic (ProhibitCStyleForLoops)
		{
		use	File::Glob qw( :glob );
		my @g =	();
		#print "argv2[$i] =	$argv2[$i] (globok = $argv2_globok[$i])\n";
		my $pat;
		#$pat =	$argv2[$i];
		#$pat =~ s/\\/\//g;		# change '\' to '/' within	path for correct globbing [Win32 only (? assert	Win32)]

		$pat = q{};
		$s = q{};
		$glob_this = 0;
		# must meta-quote to allow glob metacharacters to correctly match within quotes
		foreach my $r_h ( @{ $argv_3[$n+$i+1] } )
			{
			my $t = $r_h->{token};
			$s .= $t;
			if ($r_h->{glob})
				{
				$glob_this = 1;
				$t =~ s/\\/\//g;
				}
			else
				{ $t = _quote_gc_meta($t); }
			$pat .= $t;
			#print "r_h(token) = `$r_h->{token}`\n";
			#print "r_h(glob) = $r_h->{glob}\n";
			#print "r_h(id) = `$r_h->{id}`\n";
			#print "t = `$t`\n";
			#print "s = `$s`\n";
			#print "glob_this = $glob_this\n";
			#print "pat = `$pat`\n";
			}
		#print "s =	'$s'\n";
		#$pat =	$s;

		#if	($pat =~ /\s/) { $pat =	$_G{'single_q'}.$pat.$_G{q}; }		# quote	if contains	white space	to avoid splitting pattern	(NOT needed	for	bsd_glob())

		#print "pat = '$pat'\n";
		#if ($argv2_globok[$i]) { @g = File::DosGlob::glob(	$pat ) if $pat =~ /[$gc]/; }
		# TODO: Figure out how to quote glob meta characters in the string corresponding _only_ to quoted sections of the token (? and glob all tokens)
##		  if ($argv2_globok[$i]) { @g =	glob( $pat ) if	$pat =~	/[$gc]/; }		## no critic (ProhibitPostfixControls)
##		  @g = File::Glob::glob( $pat )	if ( $pat =~ /[$gc]/ );		## no critic (ProhibitPostfixControls)		## only	glob if	glob characters	are	in string


# NOT!: bash-like globbing EXCEPT no backslash quoting within the glob; this makes "\\" => "\\" instead of "\" so that "\\machine\dir" works
# instead: backslashes have already been replaced with forward slashes (by _quote_gc_meta())
# must do the slash changes for user expectations ( "\\machine\dir\"* should work as expected on Win32 machines )
# TODO: note differences this causes between bash and Win32::CommandLine::argv() globbing

		my $glob_flags = GLOB_NOCASE | GLOB_ALPHASORT |	GLOB_BRACE | GLOB_QUOTE;
#		my $glob_flags = GLOB_NOCASE | GLOB_ALPHASORT |	GLOB_BRACE;

		if ( $opt{nullglob} )
			{
			$glob_flags	|= GLOB_NOMAGIC;
			}
		else
			{
			$glob_flags	|= GLOB_NOCHECK;
			}

		if ( $glob_this )
			{
			$pat =~ s#\\\\#\/#g;		## no critic ( ProhibitUnusualDelimiters )	## replace all backslashes (assumed to be backslash quoted already) with forward slashes
			if ( $pat =~ /\\[?*]/ )
				{ ## '?' and '*' are not allowed in	filenames in Win32,	and	Win32 DosISH globbing doesn't correctly	escape them	when backslash quoted, so skip globbing for any tokens containing these characters
				@g = ( $s );
				}
			else
				{
				@g = bsd_glob( $pat, $glob_flags );
				}
			}
		else
			{
			@g = ( $s );
			}
		#print "glob_this = $glob_this\n";
		#print "s	= `$s`\n";
		#print "pat	= `$pat`\n";
		#print "#g = @g\n";

		push @argv2_g, @g;
		}

	return @argv2_g;
}

1; # Magic true	value required at end of module	(for require)

####

#sub _mytokens
#{#	parse tokens with one or more quotes (balanced or not)
## bash-like tokens	($'...'	and	$"...")
## ToDO: Rename	=> extract_quotedToken?	remove_semiquoted? ...
## ToDO?: make more	general	specifying quote character set#my $textref = defined $_[0] ? \$_[0]	: \$_;
#my	$wantarray = wantarray;
#my	$position =	pos	$$textref || 0;
#
##--- config
#my	$unbalanced_as_seperate_last_arg = 0;		# if unbalanced	quote exists, make it a	last seperate argument (even if	not	seperated from last	argument by	whitespace)
##---
#
#my	$r = q{};
#my	$s = q{};
#my	$p = q{};
#
#my	$q = qq{\'\"};		# quote	characters
#my	$e = q$_G{'escape_char'};		 # quoted string escape	character
#
#print "[in@($position)] = :$$textref: => :".substr($$textref, $position).":\n";
#if	($$textref =~ /\G(\s*)([\S]*['"]+.*)/g)
#	{# at least	one	quote character	exists in the next token of	the	string;	$1 = leading whitespace, $2	= string
#	$p = defined $1	? $1 : q{};
#	$s = $2;
#	#print "prefix = '$p'\n";
#	#print "start =	'$s'\n";
#	while ($s =~ m/^([^\s'"]*)(.*)$/)
#		{# $1 =	non-whitespace prefix, $2 =	quote +	following characters
#		#print "1 =	'$1'\n";
#		#print "2 =	'$2'\n";
#		my $one	= $1;
#		my $two	= $2;
#		$r .= $one;
#		$s = $two;
#		if ($two =~	/^[^'"]/) {
#			#print "last (no starting quote)\n";
#			# shouldn't	happen
#			last;
#			}
#		my ($tok, $suffix, $prefix)	= Text::Balanced::extract_delimited($two);
#		#my	($tok, $suffix,	$prefix) = _extract_delimited($two,	undef, undef, '+');
#		#print "tok	= '$tok'\n";
#		#print "suffix = '$suffix'\n";
#		#print "prefix = '$prefix'\n";
#		$r .= $tok;
#		$s = $suffix;
#		if ($tok eq	q{}) {
#			#$Win32::CommandLine::_unbalanced_command_line_quotes =	1;
#			if (($r	ne q{} && !$unbalanced_as_seperate_last_arg) ||	($r	eq q{})) {
#				$r .= $suffix; $s =	q{};
#				}
#			#print "r =	'$r'\n";
#			#print "s =	'$s'\n";
#			#print "last (no tok)\n";
#			last;
#			}
#		#print "r =	'$r'\n";
#		#print "s =	'$s'\n";
#		if ($s =~ /^\s/) {
#			#print "last (s	leading	whitespace)\n";
#			last;
#			}
#		}
#	}
#
#my	$posadvance	= length($p) + length($r);
##print	"posadvance	= $posadvance\n";
##print	"[out] = ('$r',	'$s', '$p')\n";
#pos($$textref)	= $position	+ $posadvance;
#return	($r, $s, $p);
#}

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

	perl Build.PL
	./Build
	./Build test
	./Build install

Alternatively, using the standard make idiom (if you do not have Module::Build installed):

	perl Makefile.PL
	make
	make test
	make install

(On Windows platforms you should use C<nmake> instead.)

PPM installation bundles should also be available in the standard PPM repositories (i.e. ActiveState, trouchelle.com [http://trouchelle.com/ppm/package.xml]).

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

=head2 command_line( )

C<command_line()> returns the full Win32 command line as a string.

=head2 argv( )

C<argv()> returns the reparsed command line as an array.

=head2 parse( $ )

C<parse()> returns the parsed argument string as an array.

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

[???] $ENV{NULLGLOB} = 0/1 => override default 'nullglob' setting

[???] $ENV{WIN32_COMMANDLINE_RULE} = "sh" | "bash" (case doesn't matter) => argv will parse in "sh/bash" manner if set to "default"|"undef"
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

Brackets ('{' and '}') and braces ('[' and ']') must be quoted to be matched literally. This may be a gotcha for some users, although if the filename has internal spaces, the standard Win32 shell (cmd.exe) will automatically surround the entire path with spaces (which corrects the issue).

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
    prevent reserved  words  from  being  recognized as such, and to prevent parameter
    expansion.

    Each of the metacharacters listed above under DEFINITIONS has  special  meaning to
    the shell and must be quoted if it is to represent itself.

    When the command history expansion facilities are being used (see HISTORY EXPANSION
    below), the history expansion character, usually !, must be quoted to prevent  his-
    tory expansion.

    There are three quoting mechanisms: the escape character, single quotes, and double
    quotes.

    A non-quoted backslash (\) is the escape character. It preserves the literal value
    of  the next character that follows, with the exception of <newline>.  If a \<new-
    line> pair appears, and the backslash is  not  itself  quoted,  the \<newline> is
    treated as a  line continuation (that is, it is removed from the input stream and
    effectively ignored).

    Enclosing characters in single quotes preserves the literal value of each character
    within  the quotes.  A single quote may not occur between single quotes, even when
    preceded by a backslash.

    Enclosing characters in double quotes preserves the literal value of all characters
    within  the quotes,  with the exception of $, `, \, and, when history expansion is
    enabled, !. The characters $ and ` retain  their  special  meaning within double
    quotes. The backslash retains its special meaning only when followed by one of the
    following characters: $, `, ", \, or <newline>.  A double quote  may be quoted
    within  double quotes by preceding it with a backslash. If enabled, history expan-
    sion will be performed unless an !  appearing in double quotes is escaped  using  a
    backslash.  The backslash preceding the !  is not removed.

    The special  parameters  * and  @ have special meaning when in double quotes (see
    PARAMETERS below).

    Words of the form $'string' are treated specially.  The word  expands  to  string,
    with  backslash-escaped characters replaced  as specified by the ANSI C standard.
    Backslash escape sequences, if present, are decoded as follows:
     \a  alert (bell)
     \b  backspace
     \e  an escape character
     \f  form feed
     \n  new line
     \r  carriage return
     \t  horizontal tab
     \v  vertical tab
     \\  backslash
     \'  single quote
     \nnn  the eight-bit character whose value is the octal value  nnn  (one to
      three digits)
     \xHH  the  eight-bit character whose value is the hexadecimal value HH (one
      or two hex digits)
     \cx  a control-x character

    The expanded result is single-quoted, as if the dollar sign had not been present.

    A double-quoted string preceded by a dollar sign ($) will cause the string to be
    translated  according  to the current locale.  If the current locale is C or POSIX,
    the dollar sign is ignored. If the string is translated and replaced, the replace-
    ment is double-quoted.

EXPANSION
    Use "glob" to expand filenames.


SUMMARY
 '...' => literal (no escapes and no globbing within quotes)
 $'...' => ANSI C string escapes (\a, \b, \e, \f, \n, \r, \t, \v, \\, \', \n{1,3}, \xh{1,2}, \cx; all other \<x> =>\<x>)
 "..." => literal (no escapes but allows internal globbing) [differs from bash]
 $"..." => same as "..."
??? $"..." => modified bash escapes (for $, ", \ only) and $ expansion (?$() shell escapes), no `` shell escapes, note: \<x> => \<x> unless <x> = {$, ", or <NL>}


=end IMPLEMENTATION-NOTES

=cut
