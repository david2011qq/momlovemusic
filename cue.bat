@echo off
setlocal

set OUT=%~dp0output
set CUE=%~dp0disc.cue

if not exist "%OUT%\all.wav" (
    echo all.wav not found in output folder
    pause
    exit /b
)

(
echo FILE "all.wav" WAVE
echo   TRACK 01 AUDIO
echo     INDEX 01 00:00:00
) > "%CUE%"

echo disc.cue created
pause