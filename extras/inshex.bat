@:: inshex.bat :: inshex.bat <COMMAND>
@:: $Id$
@::
@:: in current shell execution of <COMMAND> output
@:: ::Processes the STDOUT of <COMMAND> as command(s) to the current shell (i.e., as if typed directly at current command line)
@:: ::This is a batch file trick to allow parent process modification from a child process (spiritually similar to bash sourcing of scripts ["source z.sh"] or bash "eval").
@:: ::*allows child processes to chdir and set/change parent environment vars for their parent shell
@:: DISCUSSION: All batch files run 'in-process' (hence the need for setlocal/endlocal), but other processes (.exe files for example) are run by the shell in a seperate child process, disallowing normal modification of parent current working directory or enviroment vars without some trickery (such as this script).
@::
@:: EXAMPLE: `inshex echo chdir ..					:: chdir to parent directory for current shell
@:: EXAMPLE: `inshex echo set x=1`					:: set x=1 in current shell environment variable set
@:: EXAMPLE: `inshex mybetterchdir.exe ~` 			:: mybetterchdir.exe may interpret '~' and print "chdir <WHATEVER>" to STDIO :: NOTE: use "doskey cd=inshex mybetterchdir.exe $*" to replace the usual cd command
@:: EXAMPLE: `inshex mybettersetx.exe PI` 			:: mybettersetx.exe may interpret 'PI' and print "set x=<WHATEVER>" to STDIO
@:: EXAMPLE: `inshex perl -e "print q{set x=200}"` 	:: perl example
@echo OFF

:: need one global var (check for current use and exit with error if already in use)
if NOT "%_inshex_a9e5f2c1_bat%" == "" (
	echo %0: %%_inshex_a9e5f2c1_bat is already in use. Undefine it or rewrite this script to use a different global var.
	exit /B -1
	)
:findUniqueTempFile
set _inshex_a9e5f2c1_bat=%temp%\inshex.script.%RANDOM%.bat
if EXIST %_inshex_a9e5f2c1_bat% ( goto :findUniqueTempFile )

setlocal
echo @::(inshex: TEMP batch script [%_inshex_a9e5f2c1_bat%]) > %_inshex_a9e5f2c1_bat%
echo @echo OFF >> %_inshex_a9e5f2c1_bat%
:: UNset our global variable first (allows for the <COMMAND> to use set the value of our one global var if necessary [a very unlikely case, but why not allow it since it's possible])
::echo @set "_inshex_a9e5f2c1_bat=" >> %_inshex_a9e5f2c1_bat%
call %* >> %_inshex_a9e5f2c1_bat%
if NOT %errorlevel% == 0 (
	endlocal
	goto :cleanup
	)
endlocal
:: do <COMMAND> instructions in current process
:: NOTE: for CMD => (clean up at the same time [must be done on the same line since we're deleting/redefining our global var within the script]) works, but not for TCC/4NT
::call %_inshex_a9e5f2c1_bat% & erase %_inshex_a9e5f2c1_bat%
call %_inshex_a9e5f2c1_bat%
:cleanup
erase %_inshex_a9e5f2c1_bat% >nul
set "_inshex_a9e5f2c1_bat="
