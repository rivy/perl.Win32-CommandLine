#!perl -w  -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;		# included with perl v5.6.2+

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

my $haveSIGNATURE = (-f 'SIGNATURE');
my $haveNonEmptySIGNATURE = (-s 'SIGNATURE');
my $haveModuleSignature = eval { require Module::Signature; 1 };
my $haveSHA = 0;
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA; 1 }; }
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA1; 1 }; }
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA::PurePerl; 1 }; }
my $haveKeyserverConnectable = eval { require Socket; Socket::inet_aton('pgp.mit.edu') };

my $message = q{};

unless ($message || $haveModuleSignature) { $message = 'Module::Signature required to check distribution SIGNATURE'; }
unless ($message || $haveSHA) { $message = 'Missing any supported SHA modules (Digest::SHA, Digest::SHA1, or Digest::SHA::PurePerl)'; }
unless ($message || $haveKeyserverConnectable) { $message = 'Unable to connect to keyserver (pgp.mit.edu)'; }

#plan skip_all => $message if $message;

unless ($message || $haveSIGNATURE) { $message = 'Missing SIGNATURE file'; }
unless ($message || $haveNonEmptySIGNATURE) { $message = 'Empty SIGNATURE file'; }

plan tests => 2;

# BUGFIX: ExtUtils::Manifest::manifind is File::Find::find() tainted; REPLACE with fixed version
# URLref: [Find::File and taint mode] http://www.varioustopics.com/perl/219724-find-file-and-taint-mode.html
{## no critic ( ProhibitNoWarnings )
{no warnings qw( once redefine );
my $codeRef = \&my_manifind;
*ExtUtils::Manifest::manifind = $codeRef;
}}

is($message, q{}, $message);
is(Module::Signature::verify(), Module::Signature::SIGNATURE_OK(), 'Verify SIGNATURE over distribution');


#### SUBs ---------------------------------------------------------------------------------------##


{## no critic ( ProhibitNoWarnings ProhibitPackageVars )
{no warnings qw( once );  	# avoid multiple "used only once" warnings for ExtUtils::Manifest::manifind() code PATCH
# ExtUtils::Manifest::manifind() has File::Find taint errors
# PATCH over with BUGFIX my_manifind()
# MODIFIED from ExtUtils::Manifest::manifind() v1.58
require File::Find;
require ExtUtils::Manifest;
sub my_manifind {
    my $p = shift || {};
    my $found = {};
    my $wanted = sub {
		my $name = ExtUtils::Manifest::clean_up_filename($File::Find::name);
		warn "Debug: diskfile $name\n" if $ExtUtils::Manifest::Debug;			## no critic ( ProhibitPackageVars )
		return if -d $_;

        if( $ExtUtils::Manifest::Is_VMS_lc ) {  	## no critic ( ProhibitPackageVars )
            $name =~ s#(.*)\.$#\L$1#msx;
            $name = uc($name) if $name =~ /^MANIFEST(\.SKIP)?$/imsx;
        }
		$found->{$name} = q{};
	    };

    # We have to use "$File::Find::dir/$_" in preprocess, because
    # $File::Find::name is unavailable.
    # Also, it's okay to use / here, because MANIFEST files use Unix-style
    # paths.

    # PATCH: add 'no_chdir' to File::Find::find() call [ avoids chdir taint ]
    File::Find::find({wanted => $wanted, no_chdir => 1}, $ExtUtils::Manifest::Is_MacOS ? q{:} : q{.});  	## no critic ( ProhibitPackageVars )

    return $found;
	}
}}
