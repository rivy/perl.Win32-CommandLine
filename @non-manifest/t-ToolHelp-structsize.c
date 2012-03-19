#include <stdio.h>

#include "windows.h"
#include "tlhelp32.h"

/* URLref: http://perldoc.perl.org/perlpacktut.html#The-Alignment-Pit [http://www.webcitation.org/5xnxXRZYV @2011-04-08.2046] :: macro technique to develope aligned pack template from C structure */

#define Pt(struct,field,tchar) \
printf( "@%d%s ", offsetof(struct,field), # tchar );

typedef struct tagXPROCESSENTRY32 {
    DWORD dwSize;
    DWORD cntUsage;
    DWORD th32ProcessID;
    ULONG_PTR th32DefaultHeapID;
    DWORD th32ModuleID;
    DWORD cntThreads;
    DWORD th32ParentProcessID;
    LONG pcPriClassBase;
    DWORD dwFlags;
    TCHAR szExeFile[MAX_PATH];
} XPROCESSENTRY32;

void main()
{

	printf("MAX_PATH = %i\n", MAX_PATH);
	printf("sizeof  PROCESSENTRY32 = %i\n", sizeof( PROCESSENTRY32 ));
	printf("sizeof XPROCESSENTRY32 = %i\n", sizeof( XPROCESSENTRY32 ));

	Pt( XPROCESSENTRY32, dwSize, L! );
	Pt( XPROCESSENTRY32, cntUsage, L! );
	Pt( XPROCESSENTRY32, th32ProcessID, L! );
	Pt( XPROCESSENTRY32, th32DefaultHeapID, P );
	Pt( XPROCESSENTRY32, th32ModuleID, L! );
	Pt( XPROCESSENTRY32, cntThreads, L! );
	Pt( XPROCESSENTRY32, th32ParentProcessID, L! );
	Pt( XPROCESSENTRY32, pcPriClassBase, l! );
	Pt( XPROCESSENTRY32, dwFlags, L! );
	Pt( XPROCESSENTRY32, szExeFile, Z260 );

/*
	Pt( gappy_t, fc1, c );
	Pt( gappy_t, fs, s! );
	Pt( gappy_t, fc2, c );
	Pt( gappy_t, fl, l! );
*/

	printf( "\n" );
}