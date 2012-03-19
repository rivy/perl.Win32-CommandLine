#!perl -w  -- -*- tab-width: 4; mode: perl -*-

# t/00.load.t - check module loading

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;	# DISABLE buffering (enable autoflush) on STDIN, STDOUT, and STDERR (keeps output in order)
}

use Test::More tests => 1;

use lib qw{ blib\arch };		# use build directory XS module { NOTE: must rebuild new .DLL before testing }

use_ok( $ENV{_BUILD_module_name} );

is( Win32::CommandLine::_wrap_MAX_PATH(), 260, "Verify MAX_PATH == 260");

diag("Win32::CommandLine::_wrap_MAX_PATH() = ".Win32::CommandLine::_wrap_MAX_PATH());

use constant TH32CS_SNAPPROCESS =>  0x00000002;
use constant INVALID_HANDLE_VALUE =>  -1;
use constant MAX_PATH =>  260;

# Take a snapshot of all processes in the system.

my $hProcessSnap = Win32::CommandLine::_wrap_CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, 0 );
#die "CreateToolhelp32Snapshot: $!($^E)" if $hProcessSnap == INVALID_HANDLE_VALUE;

diag("hProcessSnap = $hProcessSnap");

is( $hProcessSnap != INVALID_HANDLE_VALUE, "Snapshot handle not invalid" );

return (undef) if $hProcessSnap == INVALID_HANDLE_VALUE;

#	Struct PROCESSENTRY32:
# 	DWORD dwSize;			#  0 for 4
# 	DWORD cntUsage;			#  4 for 4
# 	DWORD th32ProcessID;		#  8 for 4
# 	DWORD th32DefaultHeapID;	# 12 for 4
# 	DWORD th32ModuleID;		# 16 for 4
# 	DWORD cntThreads;		# 20 for 4
# 	DWORD th32ParentProcessID;	# 24 for 4
# 	LONG  pcPriClassBase;		# 28 for 4
# 	DWORD dwFlags;			# 32 for 4
# 	char szExeFile[MAX_PATH];	# 36 for 260

#  typedef struct tagPROCESSENTRY32 {
#    DWORD dwSize;
#    DWORD cntUsage;
#    DWORD th32ProcessID;
#    ULONG_PTR th32DefaultHeapID;
#    DWORD th32ModuleID;
#    DWORD cntThreads;
#    DWORD th32ParentProcessID;
#    LONG pcPriClassBase;
#    DWORD dwFlags;
#    CHAR szExeFile[MAX_PATH];
#  } PROCESSENTRY32;

# Set the size of the structure before using it.

#my $pack_signature = 'I3PI3LIC260';
my $pack_signature = '@0I @4I @8I @16Q @24I @28I @32I @36l @40I @44C260';

my $dwSize = length pack $pack_signature;  								## no critic ( ProhibitMagicNumbers ) # ToDO: revisit/remove

diag ("pack_signature = $pack_signature [length = $dwSize]");

#my $dwSize = MAX_PATH + 36;  								## no critic ( ProhibitMagicNumbers ) # ToDO: revisit/remove
#my $pe32 = pack 'I9C260', $dwSize, 0 x 8, '0' x MAX_PATH;  	## no critic ( ProhibitMagicNumbers ) # ToDO: revisit/remove
my $pe32 = pack $pack_signature, $dwSize, 0 x 2, 0, 0 x 3, 0, 0, '0' x MAX_PATH;  	## no critic ( ProhibitMagicNumbers ) # ToDO: revisit/remove
my $lppe32 = pack 'P', $pe32;
