# momlovemusic
momlovemusic
=======
# yt-cd

Download YouTube audio as MP3 on Windows (yt-dlp + ffmpeg).

## Setup

Download these tools (not included in the repo):

1. **yt-dlp**: get `yt-dlp.exe` from https://github.com/yt-dlp/yt-dlp/releases/latest and put it next to `run.bat`.
2. **ffmpeg**: download the "release essentials" zip from https://www.gyan.dev/ffmpeg/builds/, extract it, and rename the folder to `ffmpeg` so `ffmpeg\bin\ffmpeg.exe` exists.
3. **Deno** (needed for YouTube): run `winget install DenoLand.Deno`, then reopen PowerShell.

## Usage

1. Put one YouTube URL per line in `songs.txt`.
2. Double-click `run.bat`.
3. MP3s appear in `output\`.

## Optional: CUE file

If you place a combined `all.wav` in `output\`, double-click `cue.bat` to create `output\disc.cue`.

## Troubleshooting

- **HTTP 403**: update with `.\yt-dlp.exe -U` and make sure Deno is installed.
- **Still 403**: add `--cookies-from-browser chrome` to the command in `run.bat`.