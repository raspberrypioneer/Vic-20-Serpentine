:: Serpentine - perform a full build of program
@echo off

::-----------------------------------------------------------------------------------
set "PRG=Serpentine.prg"
set "PRGHDR=prgheader.bin"

:: Compile main program
.\bin\acme.exe -l .\build\symbols -o .\build\main .\main.asm && (
    powershell write-host -back Green Compiled ok
) || (
    powershell write-host -back Red Compiled with errors
)

:: Add the 2 load address bytes for the PRG header (PRG header created using Notepad++ with hex editor plugin)
copy /b .\build\%PRGHDR%+.\build\main ".\prg\%PRG%" >nul

:: Binary file comparison for unexpanded version
fc.exe /b ".\prg\%PRG%" ".\prg\Serpentine original.prg" && (
    powershell write-host -back Green Programs match
) || (
    powershell write-host -back Red Programs do not match
)
