#include "EXTERN.h"
/*
 ##// disable MSVC warning for redefinition of ENOTSOCK [ C:\Perl\lib\CORE\sys/socket.h(32) : warning C4005: 'ENOTSOCK' : macro redefinition ; C:\Program Files\Microsoft Visual Studio 10.0\VC\INCLUDE\errno.h(120) : see previous definition of 'ENOTSOCK' ]
 ##// ToDO: enter this as defect report for MSVC / ActiveState Perl combination
*/
#ifdef _MSC_VER
#pragma warning ( disable : 4005 )
#endif
#include "perl.h"
#include "XSUB.h"

#include "tlhelp32.h"

MODULE = Win32::CommandLine    PACKAGE = Win32::CommandLine

PROTOTYPES: ENABLE

SV *
_wrap_GetCommandLine ()
	CODE:
		RETVAL = newSVpv(GetCommandLine(), 0);
	OUTPUT:
		RETVAL

HANDLE
_wrap_CreateToolhelp32Snapshot ( dwFlags, th32ProcessID )
	DWORD dwFlags
	DWORD th32ProcessID
	CODE:
		RETVAL = CreateToolhelp32Snapshot( dwFlags, th32ProcessID );
	OUTPUT:
		RETVAL

bool
_wrap_Process32First ( hSnapshot, lppe )
	HANDLE hSnapshot
	PROCESSENTRY32 * lppe
	CODE:
		RETVAL = Process32First( hSnapshot, lppe );
	OUTPUT:
		RETVAL

bool
_wrap_Process32Next ( hSnapshot, lppe )
	HANDLE hSnapshot
	PROCESSENTRY32 * lppe
	CODE:
		RETVAL = Process32Next( hSnapshot, lppe );
	OUTPUT:
		RETVAL

bool
_wrap_CloseHandle ( hObject )
	HANDLE hObject
	CODE:
		RETVAL = CloseHandle( hObject );
	OUTPUT:
		RETVAL

 ##// Pass useful CONSTANTS back to perl

int
_const_MAX_PATH ()
	CODE:
		RETVAL = MAX_PATH;
	OUTPUT:
		RETVAL

HANDLE
_const_INVALID_HANDLE_VALUE ()
	CODE:
		RETVAL = INVALID_HANDLE_VALUE;
	OUTPUT:
		RETVAL

DWORD
_const_TH32CS_SNAPPROCESS ()
	CODE:
		RETVAL = TH32CS_SNAPPROCESS;
	OUTPUT:
		RETVAL

 ##// Pass useful sizes back to Perl (for testing) */

unsigned int
_info_SIZEOF_HANDLE ()
	CODE:
		RETVAL = sizeof(HANDLE);
	OUTPUT:
		RETVAL

unsigned int
_info_SIZEOF_DWORD ()
	CODE:
		RETVAL = sizeof(DWORD);
	OUTPUT:
		RETVAL

 #// Pass PROCESSENTRY32 structure info back to Perl

 ## URLref: http://perldoc.perl.org/perlpacktut.html#The-Alignment-Pit [http://www.webcitation.org/5xnxXRZYV @2011-04-08.2046] :: macro technique to develope aligned pack template from C structure
 ## URLref: PROCESSENTRY32 Structure [http://msdn.microsoft.com/en-us/library/ms684839%28VS.85%29.aspx ; http://www.webcitation.org/5xo33lF5p @2011-04-08.2210]
 ## [from "tlhelp32.h"]
 ## typedef struct tagXPROCESSENTRY32 {
 ##     DWORD dwSize;
 ##     DWORD cntUsage;						# no longer used (always set to 0)
 ##     DWORD th32ProcessID;
 ##     ULONG_PTR th32DefaultHeapID;		# no longer used (always set to 0)
 ##     DWORD th32ModuleID;					# no longer used (always set to 0)
 ##     DWORD cntThreads;
 ##     DWORD th32ParentProcessID;
 ##     LONG pcPriClassBase;
 ##     DWORD dwFlags;						# no longer used (always set to 0)
 ##     TCHAR szExeFile[MAX_PATH];
 ## } PROCESSENTRY32;

SV *
_info_PROCESSENTRY32 ()
	INIT:
		AV * results;
		AV * row;
		results = (AV *)sv_2mortal((SV *)newAV());
	CODE:
 		row = (AV *)sv_2mortal((SV *)newAV());
  		av_push(row, newSVpvs( "PROCESSENTRY32" ));
  		av_push(row, newSVnv( sizeof(PROCESSENTRY32) ));
  		av_push(results, newRV((SV *)row));

 		row = (AV *)sv_2mortal((SV *)newAV());
  		av_push(row, newSVpvs( "dwSize" ));
  		av_push(row, newSVpvs( "DWORD" ));
  		av_push(row, newSVnv( offsetof(PROCESSENTRY32, dwSize) ));
  		av_push(row, newSVpvs( "L!" ));
  		av_push(results, newRV((SV *)row));

 		row = (AV *)sv_2mortal((SV *)newAV());
  		av_push(row, newSVpvs( "cntUsage" ));
  		av_push(row, newSVpvs( "DWORD" ));
  		av_push(row, newSVnv( offsetof(PROCESSENTRY32, cntUsage) ));
  		av_push(row, newSVpvs( "L!" ));
  		av_push(results, newRV((SV *)row));

 		row = (AV *)sv_2mortal((SV *)newAV());
  		av_push(row, newSVpvs( "th32ProcessID") );
  		av_push(row, newSVpvs( "DWORD") );
		av_push(row, newSVnv( offsetof(PROCESSENTRY32, th32ProcessID) ));
 		av_push(row, newSVpvs( "L!") );
  		av_push(results, newRV((SV *)row));

 		row = (AV *)sv_2mortal((SV *)newAV());
  		av_push(row, newSVpvs( "th32DefaultHeapID" ));
	  	av_push(row, newSVpvs( "ULONG_PTR" ));
		av_push(row, newSVnv( offsetof(PROCESSENTRY32, th32DefaultHeapID) ));
 		av_push(row, newSVpvs( "P" ));
  		av_push(results, newRV((SV *)row));

 		row = (AV *)sv_2mortal((SV *)newAV());
  		av_push(row, newSVpvs("th32ModuleID" ));
  		av_push(row, newSVpvs( "DWORD" ));
		av_push(row, newSVnv( offsetof(PROCESSENTRY32, th32ModuleID) ));
 		av_push(row, newSVpvs( "L!" ));
  		av_push(results, newRV((SV *)row));

 		row = (AV *)sv_2mortal((SV *)newAV());
  		av_push(row, newSVpvs( "cntThreads" ));
  		av_push(row, newSVpvs( "DWORD" ));
		av_push(row, newSVnv( offsetof(PROCESSENTRY32, cntThreads) ));
 		av_push(row, newSVpvs( "L!" ));
  		av_push(results, newRV((SV *)row));

 		row = (AV *)sv_2mortal((SV *)newAV());
  		av_push(row, newSVpvs( "th32ParentProcessID" ));
  		av_push(row, newSVpvs( "DWORD" ));
		av_push(row, newSVnv( offsetof(PROCESSENTRY32, th32ParentProcessID) ));
 		av_push(row, newSVpvs( "L!" ));
  		av_push(results, newRV((SV *)row));

 		row = (AV *)sv_2mortal((SV *)newAV());
  		av_push(row, newSVpvs( "pcPriClassBase" ));
  		av_push(row, newSVpvs( "LONG" ));
		av_push(row, newSVnv( offsetof(PROCESSENTRY32, pcPriClassBase) ));
 		av_push(row, newSVpvs( "l!" ));
  		av_push(results, newRV((SV *)row));

 		row = (AV *)sv_2mortal((SV *)newAV());
  		av_push(row, newSVpvs( "dwFlags" ));
  		av_push(row, newSVpvs( "DWORD" ));
		av_push(row, newSVnv( offsetof(PROCESSENTRY32, dwFlags) ));
 		av_push(row, newSVpvs( "L!" ));
  		av_push(results, newRV((SV *)row));

 		row = (AV *)sv_2mortal((SV *)newAV());
  		av_push(row, newSVpvs("szExeFile"));
  		av_push(row, newSVpvs( "TCHAR[]" ));
		av_push(row, newSVnv( offsetof(PROCESSENTRY32, szExeFile) ));
 		av_push(row, newSVpvs( "Z" ));
 		av_push(row, newSVnv( MAX_PATH ));
  		av_push(results,  newRV((SV *)row));

		RETVAL = newRV((SV *)results);
	OUTPUT:
		RETVAL
