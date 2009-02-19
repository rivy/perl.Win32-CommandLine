:: exout.bat :: exout.bat <COMMAND> <ARGS>
:: $Id$
:: 2009-16-02; Roy Ivy III
::
:: EXecute OUTput of <COMMAND> in the current process context
:: ::Processes the STDOUT of <COMMAND> as command(s) to the current shell (i.e., as if typed directly at current command line)
:: ::This is a batch file trick to allow parent process modification from a child process (spiritually similar to bash sourcing of scripts ["source z.sh"] or bash "eval").
:: ::*allows child processes to chdir and set/change parent environment vars for their parent shell
:: DISCUSSION: All batch files run 'in-process' (hence the need for setlocal/endlocal), but other processes (.exe files for example) are run by the shell in a seperate "child" process, disallowing normal modification of parent current working directory or enviroment vars without some trickery (such as this script).
::
:: EXAMPLE: `exout echo chdir ..`					:: chdir to parent directory for current shell
:: EXAMPLE: `exout echo set x=1`					:: set x=1 in current set of shell environment variables
:: EXAMPLE: `exout mybetterchdir.exe ~` 			:: mybetterchdir.exe may interpret '~' and print "chdir <WHATEVER>" to STDIO :: NOTE: use "doskey cd=exout mybetterchdir.exe $*" to replace the usual cd command
:: EXAMPLE: `exout mybettersetx.exe x PI` 			:: mybettersetx.exe may interpret 'PI' and print "set x=3.1415926..." to STDIO
:: EXAMPLE: `exout perl -e "print q{set x=200}"` 	:: perl example
@echo OFF

setlocal

:: under 4NT/TCC, DISABLE nested variable interpretation (prevents overinterpretation of % characters)
if NOT [%_4ver%]==[] ( setdos /x-4 )

:findUniqueTempFile
set _exout_bat="%temp%\exout.script.%RANDOM%.bat"
if EXIST %_exout_bat% ( goto :findUniqueTempFile )

echo @::(exout: TEMP batch script [%_exout_bat%]) > %_exout_bat%
echo @echo OFF >> %_exout_bat%

call %* >> %_exout_bat%
if NOT %errorlevel% == 0 (
	erase %_exout_bat% 1>nul 2>nul
	endlocal & exit /B %errorlevel%
	)

endlocal & call %_exout_bat% & erase %_exout_bat% 1>nul 2>nul
