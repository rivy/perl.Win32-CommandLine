#require ExtUtils::Manifest;
use ExtUtils::Manifest qw( manicheck skipcheck filecheck fullcheck mkmanifest );

use Sub::Override;

my $codeRef = \&my_maniskip;
my $override = Sub::Override->new( 'ExtUtils::Manifest::maniskip' => $codeRef );

## FROM: ExtUtils::Manifest (v1.54)
sub my_maniskip_CHECK { return ExtUtils::Manifest::maniskip( @_ ); }
sub my_maniskip {
	#print "HERE in my_maniskip()\n";
	my @skip ;
	my $mfile = shift || "$ExtUtils::Manifest::MANIFEST.SKIP";
	ExtUtils::Manifest::_check_mskip_directives($mfile) if -f $mfile;
	local(*M, $_);
	open M, "< $mfile" or open M, "< $ExtUtils::Manifest::DEFAULT_MSKIP" or return sub {0};
	while (<M>){
	chomp;
	s/\r//;
	next if /^#/;
	next if /^\s*$/;
		s/^'//;
		s/'$//;
	push @skip, ExtUtils::Manifest::_macify($_);
	}
	close M;
	#print 'skip['.scalar(@skip)."]\n";
	return sub {0} unless (scalar @skip > 0);

	# extinguish only used once warnings
	my $dummy; $dummy = $ExtUtils::Manifest::Is_VMS; $dummy = $ExtUtils::Manifest::MANIFEST; $dummy = $ExtUtils::Manifest::DEFAULT_MSKIP;

	my $opts = $ExtUtils::Manifest::Is_VMS ? '(?i)' : '';

	# Make sure each entry is isolated in its own parentheses, in case
	# any of them contain alternations
	my $regex = join '|', map "(?:$_)", @skip;

	return sub {
		my $f = File::Spec->rel2abs($_[0]);
		if ($^O eq 'MSWin32') {$f =~ s:\\:/:g;};
		print "[$_[0]=>$f]\n";
		return ($f =~ qr{$opts$regex});
		};
	#return sub { return (File::Spec->rel2abs($_[0]) =~ qr{$opts$regex}); };
	#return sub { $_[0] =~ qr{$opts$regex} };
  }


#my $found    = manifind();

#my $manifest = maniread();

#manicopy($read,$target);

#maniadd({$file => $comment, ...});

#my @missing_files    = manicheck;
#my @skipped          = skipcheck;
#my @extra_files      = filecheck;
#my($missing, $extra) = fullcheck;

mkmanifest();

