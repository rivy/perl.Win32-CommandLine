use Win32;
use Win32::Security::SID;

my %registry;

use Win32::TieRegistry ( TiedHash => \%registry );

my %home_paths = ();

my $node_name   = Win32::NodeName;
my $domain_name = Win32::DomainName;

my $profiles = $registry{'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList\\'};
unless ($profiles) {
	# Windows 98
	$profiles = $registry{'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ProfileList\\'};
	}

foreach my $p (keys %$profiles) {
	#print "p = $p\n";
	if ($p =~ /^(S(?:-\d+)+)\\$/) {
		my $sid_str = $1;
		my $sid = Win32::Security::SID::ConvertStringSidToSid($1);
		my $uid = Win32::Security::SID::ConvertSidToName($sid);
		my $domain = "";
		if ($uid =~ /^(.+)\\(.+)$/) {
			$domain = $1;
			$uid    = $2;
			}
		if ($domain eq $node_name || $domain eq $domain_name) {
			my $path = $profiles->{$p}->{ProfileImagePath};
			$path =~ s/\%(.+)\%/$ENV{$1}/eg;
			#print $uid."\n";
			$home_paths{lc($uid)} = $path;		# remove user case
			}
	}
}

# add All Users / Public

for my $k (keys %home_paths) { print "$k => $home_paths{$k}\n"; }
