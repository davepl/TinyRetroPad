@echo off
setlocal

set "INCDIR=C:\masm32\include"
if not exist "%INCDIR%\windows.inc" (
  echo Missing MASM include dir: "%INCDIR%"
  exit /b 1
)

set "MLCMD="
for /f "delims=" %%I in ('where ml 2^>nul') do (
  set "MLCMD=%%I"
  goto :found_ml
)
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
  for /f "delims=" %%I in ('"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find VC\Tools\MSVC\**\bin\Hostx64\x86\ml.exe 2^>nul') do (
    set "MLCMD=%%I"
    goto :found_ml
  )
)
echo Could not find ml.exe
exit /b 1

:found_ml
set "CRINKLER="
for /f "delims=" %%I in ('where crinkler 2^>nul') do (
  set "CRINKLER=%%I"
  goto :found_crinkler
)
if exist "%LOCALAPPDATA%\Tools\Crinkler\crinkler30a\Win32\Crinkler.exe" (
  set "CRINKLER=%LOCALAPPDATA%\Tools\Crinkler\crinkler30a\Win32\Crinkler.exe"
  goto :found_crinkler
)
echo Could not find Crinkler.exe
exit /b 1

:found_crinkler
set "SDKLIB="
for /f "delims=" %%I in ('dir /b /ad /o-n "C:\Program Files (x86)\Windows Kits\10\Lib" 2^>nul') do (
  if exist "C:\Program Files (x86)\Windows Kits\10\Lib\%%I\um\x86\kernel32.lib" (
    set "SDKLIB=C:\Program Files (x86)\Windows Kits\10\Lib\%%I\um\x86"
    goto :found_sdklib
  )
)
echo Could not find Windows SDK x86 libs
exit /b 1

:found_sdklib
"%MLCMD%" /nologo /c /coff /Cp /I"%INCDIR%" /Fotrpad.obj trpad.asm
if errorlevel 1 exit /b 1

"%CRINKLER%" trpad.obj ^
  /OUT:trpad-tiny.exe ^
  /ENTRY:MainEntry ^
  /SUBSYSTEM:WINDOWS ^
  /NOINITIALIZERS ^
  /TINYIMPORT ^
  /TRANSFORM:CALLS ^
  /HASHSIZE:32 ^
  /ORDERTRIES:2000 ^
  /LIBPATH:"%SDKLIB%" ^
  kernel32.lib user32.lib shell32.lib comdlg32.lib gdi32.lib
if errorlevel 1 exit /b 1

del trpad.obj
endlocal
