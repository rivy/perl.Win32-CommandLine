::# $Id$
:: to.bat
:: cd with command line expansion
:: note: removes any initial '~' for convenience
::  * if removal of the initial '~' isn't required, the entire batch file can be compressed to a single alias (cmd.exe: 'doskey to=x -S cd ~$*'; 4nt/tcc/tcmd: 'alias to=x -S cd ~%%$')
@echo off
setlocal

:: gather all arguments
set args=%*
:::: :CMD quirk
::set "args=%*"
:::: :4NT/TCC/TCMD quirk
::if 01 == 1.0 ( set args=%* )

:: <args> == null => to ~
if [%args%]==[] ( set args=~ )
:: remove leading ~ (if it exists)
set prefix_char=%args:~0,1%
set suffix=%args:~1%
if [%prefix_char%]==[~] (
	:: avoid interpretation of set unless the leading character is ~ [arguments surrounded by quotes would otherwise cause a syntax error for %suffix% with only a trailing quote
	set args=%suffix%
	)

::echo prefix_char = %prefix_char%
::echo suffix = %suffix%
::echo args = %args%

:: URLref: http://www.ss64.com/nt/endlocal.html :: combining set with endlocal
endlocal & x -S cd ~%args%

