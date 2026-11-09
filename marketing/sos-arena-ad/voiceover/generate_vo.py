"""Generate the ad voiceover with Kokoro (open-source neural TTS, runs locally).

Usage:
  pip install kokoro-onnx soundfile
  # model files: https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0
  python generate_vo.py <kokoro-v1.0.onnx> <voices-v1.0.bin> [voice]

Writes public/vo/<id>.wav and public/vo/durations.json (seconds per line).
Line ids must match VO_LINES in src/SosAd.tsx.
"""
import json
import sys
from pathlib import Path

import soundfile as sf
from kokoro_onnx import Kokoro

LINES = {
    "hook": ("Three letters. Endless rivalry!", 1.12),
    "gameplay": ("Place an S, or an O. Make S.O.S... and steal the lead!", 1.08),
    "versus": ("Challenge your partner. Loser picks the movie!", 1.12),
    "audiences": ("Date night. Gamers. Your squad. Or solo, against the A.I.", 1.05),
    "features": ("Trash talk with emotes, unlock themes and magic spells, and rise to S.O.S. Legend!", 1.1),
    "victory": ("Victory never felt this good!", 1.0),
    "cta": ("S.O.S. Arena. Play free, now!", 0.95),
}

model, voices = sys.argv[1], sys.argv[2]
voice = sys.argv[3] if len(sys.argv) > 3 else "af_heart"
out = Path(__file__).resolve().parent.parent / "public" / "vo"
out.mkdir(parents=True, exist_ok=True)

kokoro = Kokoro(model, voices)
durations = {}
for key, (text, speed) in LINES.items():
    samples, sr = kokoro.create(text, voice=voice, speed=speed, lang="en-us")
    sf.write(out / f"{key}.wav", samples, sr)
    durations[key] = round(len(samples) / sr, 3)
    print(f"{key:10s} {durations[key]:5.2f}s  {text}")
(out / "durations.json").write_text(json.dumps(durations, indent=2))
