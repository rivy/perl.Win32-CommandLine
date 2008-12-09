#!perl -w   -*- tab-width: 4; mode: perl -*-

# check for CPAN/PAUSE parsable VERSIONs ( URLref: http://cpan.org/modules/04pause.html )

use strict;
use warnings;

use Test::More;

my $haveExtUtilsMakeMaker = eval { require ExtUtils::MakeMaker; 1; };
use ExtUtils::MakeMaker;

my @files = ( '.\lib\Win32\CommandLine.pm' );

#my @all_files = all_perl_files( '.' );
#my @files = @all_files;
#
#my @skip_re = ( '(^/)inc/.*' );
#for (@all_files)
#	{
#
#	}

#print @files;

#print cwd();

plan skip_all => '(ExtUtils::MakeMaker) Author tests, not required for installation [To run test(s): set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

plan skip_all => 'ExtUtils::MakeMaker required to check code versioning' if !$haveExtUtilsMakeMaker;

plan tests => scalar( @files + 1 );

isnt( (scalar(@files) > 0), 0, "Found ".scalar(@files)." files to check");
isnt( MM->parse_version($_), 'undef', "'$_' has ExtUtils::MakeMaker parsable version") for @files;

#-----------------------------------------------------------------------------

## from Perl::Critic::Utils

#Readonly::Array my @skip_dir => qw( CVS RCS .svn _darcs {arch} .bzr _build blib );
#Readonly::Hash my %skip_dir => hashify( @skip_dir );
my @skip_dir = qw( CVS RCS .svn _darcs {arch} .bzr _build blib );
my %skip_dir = hashify( @skip_dir );

sub hashify {  ## no critic (ArgUnpacking)
    return map { $_ => 1 } @_;
}

sub all_perl_files
{#

    # Recursively searches a list of directories and returns the paths
    # to files that seem to be Perl source code.  This subroutine was
    # poached from Test::Perl::Critic.

    my @queue      = @_;
    my @code_files = ();

    while (@queue) {
        my $file = shift @queue;
        if ( -d $file ) {
            opendir my ($dh), $file or next;
            my @newfiles = sort readdir $dh;
            closedir $dh;

            @newfiles = File::Spec->no_upwards(@newfiles);
            @newfiles = grep { !$skip_dir{$_} } @newfiles;
            push @queue, map { File::Spec->catfile($file, $_) } @newfiles;
        }

        if ( (-f $file) && ! _is_backup($file) && _is_perl($file) ) {
            push @code_files, $file;
        }
    }
    return @code_files;
}

#-----------------------------------------------------------------------------
# Decide if it's some sort of backup file

sub _is_backup {
    my ($file) = @_;
    return 1 if $file =~ m{ [.] swp \z}xms;
    return 1 if $file =~ m{ [.] bak \z}xms;
    return 1 if $file =~ m{  ~ \z}xms;
    return 1 if $file =~ m{ \A [#] .+ [#] \z}xms;
    return;
}

#-----------------------------------------------------------------------------
# Returns true if the argument ends with a perl-ish file
# extension, or if it has a shebang-line containing 'perl' This
# subroutine was also poached from Test::Perl::Critic

use Perl::Critic::Exception::Fatal::Generic qw{ throw_generic };

sub _is_perl {
    my ($file) = @_;

    #Check filename extensions
    return 1 if $file =~ m{ [.] PL    \z}xms;
    return 1 if $file =~ m{ [.] p[lm] \z}xms;
    return 1 if $file =~ m{ [.] t     \z}xms;

    #Check for shebang
    open my $fh, '<', $file or return;
    my $first = <$fh>;
    close $fh or throw_generic "unable to close $file: $!";

    return 1 if defined $first && ( $first =~ m{ \A [#]!.*perl }xms );
    return;
}

#-----------------------------------------------------------------------------

sub shebang_line {
    my $doc = shift;
    my $first_element = $doc->first_element();
    return if not $first_element;
    return if not $first_element->isa('PPI::Token::Comment');
    my $location = $first_element->location();
    return if !$location;
    # The shebang must be the first two characters in the file, according to
    # http://en.wikipedia.org/wiki/Shebang_(Unix)
    return if $location->[0] != 1; # line number
    return if $location->[1] != 1; # column number
    my $shebang = $first_element->content;
    return if $shebang !~ m{ \A [#]! }xms;
    return $shebang;
}

#-----------------------------------------------------------------------------

