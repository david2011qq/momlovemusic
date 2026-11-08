@echo off
setlocal enabledelayedexpansion

set "YTDLP=%~dp0yt-dlp.exe"
set "FFMPEG=%~dp0ffmpeg\bin\ffmpeg.exe"
set "INPUT=%~dp0songs.txt"
set "OUT=%~dp0output"

if not exist "%OUT%" mkdir "%OUT%"

echo Downloading MP3 (320kbps)...

"%YTDLP%" ^
-x --audio-format mp3 ^
--audio-quality 0 ^
--ffmpeg-location "%FFMPEG%" ^
-o "%OUT%\%%(title)s.%%(ext)s" ^
-a "%INPUT%"

echo Done.
pause