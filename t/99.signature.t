#!perl -w   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;		# included with perl

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};

my $haveSIGNATURE = (-f 'SIGNATURE');
my $haveNonEmptySIGNATURE = (-s 'SIGNATURE');
my $haveSHA = 0;
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA; 1 }; }
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA1; 1 }; }
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA::PurePerl; 1 }; }
my $haveModuleSignature = eval { require Module::Signature; 1 };
my $haveKeyserverConnectable = eval { require Socket; Socket::inet_aton('pgp.mit.edu') };

my $message = q{};

unless ($message || $haveSIGNATURE) { $message = 'Missing SIGNATURE file'; }
unless ($message || $haveNonEmptySIGNATURE) { $message = 'Empty SIGNATURE file'; }
unless ($message || $haveSHA) { $message = 'Missing any supported SHA modules (Digest::SHA, Digest::SHA1, or Digest::SHA::PurePerl)'; }
unless ($message || $haveModuleSignature) { $message = 'Missing Module::Signature'; }
unless ($message || $haveKeyserverConnectable) { $message = 'Unable to connect to keyserver (pgp.mit.edu)'; }

#plan skip_all => $message if $message;

plan tests => 2;

is($message, q{}, $message);
is(Module::Signature::verify(), Module::Signature::SIGNATURE_OK(), 'Verify SIGNATURE over distribution');
