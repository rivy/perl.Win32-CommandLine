#!perl -w   -- -*- tab-width: 4; mode: perl -*-
#$Id$

## TODO: aliases? bash which doesn't see aliases -- make a switch to search aliases as well?

# Script Summary

=head1 NAME

which - Find and print the executable path(s)

=head1 VERSION

This document describes C<which> ($Version$).

=head1 SYNOPSIS

which [B<<option(s)>>] B<<filename(s)>>

=begin HIDDEN-OPTIONS

Options:

		--version       version message
	-?, --help          brief help message

=end HIDDEN-OPTIONS

=head1 OPTIONS

=over

=item --dosify, --dos, -d

"Dosify" output

=item --where, -w, --all, -a

Find and print B<<all>> possible executable paths for the filename(s) given

=item --version

=item --usage

=item --help, -?

=item --man

Print the usual program information

=back

=head1 REQUIRED ARGUMENTS

=over

=item <filename(s)>

FILENAMES...

=back

=head1 DESCRIPTION

B<which> will read each FILENAME, find, and then print the executable path for the FILENAME.

=cut

# VERSION: major.minor.release[.build]]  { minor is ODD => alpha/beta/experimental; minor is EVEN => stable/release }
# generate VERSION from $Version$ SCS tag
# $defaultVERSION 	:: used to make the VERSION code resilient vs missing keyword expansion
# $generate_alphas	:: 0 => generate normal versions; true/non-0 => generate alpha version strings for ODD numbered minor versions
use version qw(); our $VERSION; { my $defaultVERSION = '0.1.0'; my $generate_alphas = 0; $VERSION = ( $defaultVERSION, qw( $Version$ ))[-2]; if ($generate_alphas) { $VERSION =~ /(\d+)\.(\d+)\.(\d+)(?:\.)?(.*)/; $VERSION = $1.'.'.$2.((!$4&&($2%2))?'_':'.').$3.($4?((($2%2)?'_':'.').$4):q{}); $VERSION = version::qv( $VERSION ); }; } ## no critic ( ProhibitCallsToUnexportedSubs ProhibitCaptureWithoutTest ProhibitNoisyQuotes ProhibitMixedCaseVars ProhibitMagicNumbers)

use Pod::Usage;
use Getopt::Long qw(:config bundling bundling_override gnu_compat no_getopt_compat);

#use Carp::Assert;

use strict;
use warnings;
use diagnostics;

#use File::Which;
use File::Spec;

use Env::Path qw(PATH);

#sub dosify;

@ARGV = Win32::CommandLine::argv( {glob => 0} ) if eval { require Win32::CommandLine; };

# getopt
my %ARGV = ();
GetOptions (\%ARGV, 'where|w|all|a', 'help|h|?|usage', 'man', 'version|ver|v', 'dosify|dos|d') or pod2usage(2);
#Getopt::Long::VersionMessage() if $ARGV{'version'};
pod2usage(-verbose => 99, -sections => '', -message => (File::Spec->splitpath($0))[2]." v$::VERSION") if $ARGV{'version'};
pod2usage(1) if $ARGV{'help'};
pod2usage(-verbose => 2) if $ARGV{'man'};

pod2usage(1) if @ARGV < 1;

if ($^O eq "MSWin32") { PATH->Prepend( q{.} ); }

PATH->Uniqify();

foreach (@ARGV)
	{
	#print '#args = '.scalar(@ARGV)."\n";
	##if (@ARGV > 1) { print "$_:\n"; }
#	my @w = ($ARGV{where} ? which( $_ ) : scalar(which( $_ )) );

	# TODO: aliases
	# how to note these? include entire text/options? what about aliases with multiple commands?
	# CMD = 'doskey /macros'
	# perl -e "$o = qx{doskey /macros}; print $o;"
	# [format]
    # cpan=wrap-cpan $*
    # command=cmd $*
    # to-hex=perl -e "printf q{%x},$1"
    # vdiff=winmerge $*
    # bt=b test --test_files $*
    # b=ant+build $*
    # ant="c:/program files/ant/bin/ant" $*
    # oh=handle $*
    # morehelp=hh ntcmds.chm $*
    # cdg=x -S cd $*
    # lag=x msls -lA $*
    # llg=x msls -l $*
    # lsg=x msls $*
    # dirg=x msls $*
    # la=msls -lA $*
    # ll=msls -l $*
    # ls=msls $*
    # dir=msls -l $*
    # args=xx -a $*
    # perl=call xx perl $*
    # pdh=start c:\perl\html\index.html $*
    # pd=perldoc $*
    # fs=findstr /s /i $*
    # ds=dir /s /b $*
    # e=edit $*
    # .....=cd ..\..\..\.. $*
    # ....=cd ..\..\.. $*
    # ...=cd ..\.. $*
    # ..=cd .. $*
    # whois=pwhois -s -S -c -C $*
    # rn=rename $*
    # mv=move $*
    # rm=erase $*
    # cp=copy $*
    # NOTE: trailing $* is optional; $T is a command seperator (multiple commands are possible); $1-$9 batch parameters are possible

	# TCC = 'alias'
	# perl -e "$o = qx{tcc /c alias}; print $o;"
	# [format]
	# cp=copy
	# rm=erase
	# mv=move
	# rn=rename
	# whois=pwhois -s -S -c -C
	# ..=cd ..
	# ...=cd ..\..
	# ....=cd ..\..\..
	# .....=cd ..\..\..\..
	# e=edit
	# ds=dir /s /b
	# fs=findstr /s /i
	# pd=perldoc
	# pdh=start c:\perl\html\index.html
	# perl=call xx perl
	# args=xx -a
	# dir=msls -l
	# ls=msls
	# ll=msls -l
	# la=msls -lA
	# dirg=x msls
	# lsg=x msls
	# llg=x msls -l
	# lag=x msls -lA
	# cdg=x -S cd
	# morehelp=hh ntcmds.chm
	# oh=handle
	# ant="c:/program files/ant/bin/ant"
	# b=*ant+build
	# bt=b test --test_files
	# vdiff=winmerge
	# to-hex=perl -e "printf q{%%x},%1"
	# command=cmd
	# cpan=wrap-cpan

	# bash = 'alias'
	# perl -e "\$o = qx{/bin/bash -ic alias}; print \$o;"
	# NOTE: this only finds aliases defined in .bashrc (not the current shell)
	# [format]
	# alias ant='c:/program\ files/ant/bin/ant'
	# alias b='c:/users/public/documents/\@bin/ant+build.pl'
	# alias bt='b test --test_files'
	# alias df='df -h'
	# alias dir='ls'
	# alias du='du -h'
	# alias la='ls -A'
	# alias ll='ls -l'
	# alias ls='ls --color=auto -hF'
	# alias mc='. /usr/share/mc/bin/mc-wrapper.sh'
	# alias pd='perldoc'
	# NOTE: mc is aliased to a sourced shell script [? return '.', '. /usr/share/mc/bin/mc-wrapper.sh', or '/usr/share/mc/bin/mc-wrapper.sh']

	my @w = PATH->Whence( $_ );
	if (! $ARGV{where} && @w) { @w = $w[0]; }
	my %printed;
#	# output full path for all matches (and no repeats [repeats can happen if the PATH contains multiple references to the same location])
	for (@w) { if ($_) {$_ = File::Spec->rel2abs($_); if (!$printed{$_}) {$printed{$_}=1; print ''.($ARGV{dosify} ? _dosify($_) : $_)."\n"; } } }
	#if (@w) { print join("\n", @w)."\n"; }
	}

sub	_dosify {
	# _dosify( <null>|$|@ ): returns <null>|$|@ ['shortcut' function]
	# dosify string, returning a string which will be interpreted/parsed by DOS/CMD as the input string when input to the command line
	# CMD/DOS quirks: dosify double-quotes:: {\\} => {\\} UNLESS followed by a double-quote mark when {\\} => {\} and {\"} => {"} (and doesn't end the quote)
	#	:: EXAMPLES: {a"b"c d} => {[abc][d]}, {a"\b"c d} => {[a\bc][d]}, {a"\b\"c d} => {[a\b"c d]}, {a"\b\"c" d} => {[a\b"c"][d]}
	#				 {a"\b\\"c d} => {[a\b\c][d]}, {a"\b\\"c" d} => {[a\b\c d]}, {a"\b\\"c d} => {[a\b\c][d]}, {a"\b\\c d} => {[a\b\\c d]}
	@_ = @_ ? @_ : $_ if defined wantarray;		## no critic (ProhibitPostfixControls)	## break aliasing if non-void return context

	# TODO: check these characters for necessity => PIPE characters [<>|] and internal double quotes for sure, [:]?, [*?] glob chars needed?, what about glob character set chars [{}]?
	my $dos_special_chars = '"<>|';
	my $dc = quotemeta( $dos_special_chars );
	for (@_ ? @_ : $_)
		{
		#print "_ = $_\n";
		s:\/:\\:g;								# forward to back slashes
		if ( $_ =~ qr{(\s|[$dc])} )
			{
			#print "in qr\n";
			s:":\\":g;							# CMD: preserve double-quotes with backslash	# TODO: change to $dos_escape	## no critic (ProhibitUnusualDelimiters)
			s:([\\]+)\\":($1 x 2).q{\\"}:eg;	# double backslashes in front of any \" to preserve them when interpreted by DOS/CMD
			$_ = q{"}.$_.q{"};					# quote the final token
			};
		}

	return wantarray ? @_ : "@_";
}
