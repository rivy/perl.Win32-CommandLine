#!perl -w   -*- tab-width: 4; mode: perl -*-
#$Id$

## TODO: aliases? bash which doesn't see aliases -- make a switch to search aliases as well?

# Script Summary

=head1 NAME

which - Find and print the executable path

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

B<which> will read each FILENAME, find, and then print the executable path for the filename.

=cut

# VERSION: major.minor.revision[.build]]  { minor is ODD = alpha/beta/experimental; minor is EVEN = release }
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

@ARGV = Win32::CommandLine::argv( {glob => 0} ) if eval { require Win32::CommandLine; };

# getopt
my %ARGV = ();
GetOptions (\%ARGV, 'where|w|all|a', 'help|h|?|usage', 'man', 'version|ver|v') or pod2usage(2);
Getopt::Long::VersionMessage() if $ARGV{'version'};
pod2usage(1) if $ARGV{'help'};
pod2usage(-verbose => 2) if $ARGV{'man'};

pod2usage(1) if @ARGV < 1;

foreach (@ARGV)
	{
	#print '#args = '.scalar(@ARGV)."\n";
	##if (@ARGV > 1) { print "$_:\n"; }
#	my @w = ($ARGV{where} ? which( $_ ) : scalar(which( $_ )) );
	my @w = 	PATH->Whence( $_ );
	if (! $ARGV{where} && @w) { @w = $w[0]; }
	my %printed;
#	# output full path for all matches (and no repeats [repeats can happen if the PATH contains multiple references to the same location])
	for (@w) { if ($_) {$_ = File::Spec->rel2abs($_); if (!$printed{$_}) {$printed{$_}=1; print $_."\n"; } } }
	#if (@w) { print join("\n", @w)."\n"; }
	}
