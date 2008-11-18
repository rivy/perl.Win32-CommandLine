#!perl -w   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

#use File::Glob;
#use File::DosGlob;

use lib qw{ lib blib/arch };
use Win32::CommandLine qw( command_line parse );

use Getopt::Long qw(:config bundling bundling_override gnu_compat no_getopt_compat);

$| = 1;		# autoflush for warnings to be in sequence with regular output

#@ARGV = Win32::CommandLine::argv() if eval { require Win32::CommandLine; };

# getopt
my %ARGV = ();
#GetOptions (\%ARGV, 'filename|f', 'fullpath|F', 'aid|a', 'help|h|?|usage', 'version|v') or pod2usage(2);
GetOptions (\%ARGV, 'filename|f', 'fullpath|F', 'aid|a', 't:s', 's=s', 'd=s%', 'help|h|?|usage', 'man', 'version|ver|v');
Getopt::Long::VersionMessage() if $ARGV{version};
##pod2usage(1) if $ARGV{'help'};
##pod2usage(-verbose => 2) if $ARGV{'man'};
#$ARGV{'aid'} = 'true' if $ARGV{'a'};
#$ARGV{'filename'} = 'true' if $ARGV{'f'};
#$ARGV{'fullpath'} = 'true' if $ARGV{'F'};
#$ARGV{filename} = 'true' unless ($ARGV{'fullpath'} || $ARGV{'aid'});
foreach (sort keys %ARGV)
	{
	print '%ARGV{'.$_.'} =`'. "$ARGV{$_}`\n";
	if (ref($ARGV{$_}) eq 'HASH')
		{
		my $k = $_;
		foreach (sort keys %{$ARGV{$_}})
			{
			print ':%ARGV{'.$k.'}{'.$_.'} =`'. "$ARGV{$k}->{$_}`\n";
			}
		}
	}

print "<nullglob = 0>\n";
@ARGV = parse( command_line(), { nullglob => 0 } );     # get commandline and reparse it returning the new ARGV array
foreach (@ARGV)
	{
	print "`$_`\n";
	}

print "<nullglob = 1>\n";
@ARGV = parse( command_line(), { nullglob => 1 } );     # get commandline and reparse it returning the new ARGV array
foreach (@ARGV)
	{
	print "`$_`\n";
	}
