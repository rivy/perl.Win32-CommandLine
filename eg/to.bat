::# $Id$
:: to.bat
:: cd with command line expansion
:: note: removes any initial '~' for convenience
::  * if removal of the initial '~' isn't required, the entire batch file can be compressed to a single alias (cmd.exe: 'doskey to=x -S cd ~$*'; 4nt/tcc/tcmd: 'alias to=x -S cd ~%%$')
:: compatible with CMD, 4NT/TCC/TCMD
:: NOT compatible with COMMAND
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
set tilde=~
set prefix_char=%args:~0,1%
set suffix=%args:~1%

:: ^%prefix_char% is used to escape the character in cases where it might be a quote character
if [^%prefix_char%] == [^%tilde%] (
	:: avoid interpretation of set unless the leading character is ~ [arguments surrounded by quotes would otherwise cause a syntax error for %suffix% with only a trailing quote
	set args=%suffix%
	)
if 01 == 1.0 (
	:: :4NT/TCC/TCMD quirk: "if [^%prefix_char%] == [^%tilde%]" DOESN'T work in 4NT/TCC/TCMD
	:: : used 4NT/TCC/TCMD %@ltrim[] instead
	set args=%@ltrim[~,%args%]
	)

::echo prefix_char = %prefix_char%
::echo suffix = %suffix%
::echo args = %args%

:: URLref: http://www.ss64.com/nt/endlocal.html :: combining set with endlocal
endlocal & xx -s cd ~%args%
