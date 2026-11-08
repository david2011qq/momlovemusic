#!/bin/bash
cd "$(dirname "$0")"

for cmd in yt-dlp ffmpeg deno; do
  command -v $cmd >/dev/null || { echo "$cmd not found. See README.md"; exit 1; }
done

mkdir -p output

yt-dlp \
  --js-runtimes deno \
  -x --audio-format mp3 \
  --audio-quality 0 \
  -o "output/%(title)s.%(ext)s" \
  -a songs.txt

echo "Done."
