:: Serpentine - perform a full build of program
@echo off

::-----------------------------------------------------------------------------------
set "PRG=Serpentine.prg"
set "PRGHDR=prgheader.bin"

:: Compile main program
.\bin\acme.exe -l .\build\symbols -o .\build\main .\main.asm

:: Add the 2 load address bytes for the PRG header (PRG header created using Notepad++ with hex editor plugin)
copy /b .\build\%PRGHDR%+.\build\main ".\prg\%PRG%" >nul

:: Binary file comparison for unexpanded version
fc.exe /b ".\prg\%PRG%" ".\prg\Serpentine original.prg"
echo Done!
