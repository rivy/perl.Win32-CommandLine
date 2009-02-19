@echo off
::echo %*
::echo %$
::if [%_4ver]==[%_4ver] ( echo CMD )
::if NOT [%_4ver]==[%_4ver] ( echo TCC )
if 01 == 1.0 echo 4DOS or 4NT or TCC or TCMD
if NOT 01 == 1.0 echo CMD
