#!/bin/bash
cd "$(dirname "$0")"

if [ ! -f output/all.wav ]; then
  echo "all.wav not found in output folder. See README.md"
  exit 1
fi

cat > output/disc.cue <<'EOF'
FILE "all.wav" WAVE
  TRACK 01 AUDIO
    INDEX 01 00:00:00
EOF

echo "Created output/disc.cue"
