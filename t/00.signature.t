#!perl -w  -- -*- tab-width: 4; mode: perl -*-
# [no -T]: Module::Signature::SIGNATURE_OK() is File::Find tainted

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;		# included with perl v5.6.2+

## no critic ( RequireCarping )

{## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select(STDERR); $| = 1; select($fh); $| = 1;	# DISABLE buffering on STDIN and STDERR
}

my $haveSIGNATURE = (-f 'SIGNATURE');
my $haveNonEmptySIGNATURE = (-s 'SIGNATURE');
my $haveSHA = 0;
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA; 1 }; }
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA1; 1 }; }
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA::PurePerl; 1 }; }
	unless ($haveSHA) { $haveSHA = eval { require Digest::SHA1::PurePerl; 1 }; }
my $haveModuleSignature = eval { require Module::Signature; 1 };
my $haveKeyserverConnectable = eval { require Socket; Socket::inet_aton('pgp.mit.edu') };

my $message = q{};

unless ($message || $haveSIGNATURE) { $message = 'Missing SIGNATURE file'; }
unless ($message || $haveNonEmptySIGNATURE) { $message = 'Empty SIGNATURE file'; }
unless ($message || ($ENV{TEST_SIGNATURE} or $ENV{TEST_ALL})) { $message = 'Signature test [to run: set TEST_SIGNATURE]'; }
unless ($message || $haveSHA) { $message = 'Missing any supported SHA modules (Digest::SHA, Digest::SHA1, or Digest::SHA::PurePerl)'; }
unless ($message || $haveModuleSignature) { $message = 'Missing Module::Signature'; }
unless ($message || $haveKeyserverConnectable) { $message = 'Unable to connect to keyserver (pgp.mit.edu)'; }

plan skip_all => $message if $message;

plan tests => 1;

my $DOWARN = 1;
my $notCertified = 0;
my $fingerprint = q{};
# setup warning silence to avoid loud "WARNING: This key is not certified with a trusted signature! Primary key fingerprint: [...]"
# :: change it to a less scary diag()
$SIG{'__WARN__'} = sub { warn $_[0] if $DOWARN; if ($_[0] =~ /^WARNING:(.*)not certified/) { $notCertified = 1 }; if ($notCertified && ($_[0] =~ /^.*fingerprint:\s*(.*?)\s*$/)) { $fingerprint = $1 };  };
$DOWARN = 0;	# silence warnings
my $verify = Module::Signature::verify();
$DOWARN = 1;	# re-enable warnings

if (($verify == Module::Signature::SIGNATURE_OK()) && $fingerprint) { diag('SIGNATURE verified, but NOT certified/trusted'); diag("signature fingerprint: [$fingerprint]"); }

is ($verify, Module::Signature::SIGNATURE_OK(), 'Verify SIGNATURE over distribution');
