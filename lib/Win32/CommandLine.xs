#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

SV * _wrap_GetCommandLine() {
     return newSVpv(GetCommandLine(), 0);
}

MODULE = Win32::CommandLine    PACKAGE = Win32::CommandLine    

PROTOTYPES: DISABLE

SV *
_wrap_GetCommandLine ()
