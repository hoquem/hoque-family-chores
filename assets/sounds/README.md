# Sound effects

Four short clips, played by `lib/presentation/sound/` (spec:
`docs/superpowers/specs/2026-10-06-sound-effects-design.md`).

All are by Kenney (www.kenney.nl), licensed CC0 1.0 (public domain,
http://creativecommons.org/publicdomain/zero/1.0/), no attribution required.
kenney.nl was unreachable from the build machine, so the files were taken
from GitHub mirrors that ship Kenney's original licence file unchanged:

- Interface Sounds (1.0): https://github.com/Calinou/kenney-interface-sounds
- Music Jingles: https://github.com/ornelabaldini/pedro-y-el-medio-ambiente-
  (folder `kenney_music-jingles/`)

| Asset | Moment | Source | Why |
|---|---|---|---|
| `chore_done.m4a` | chore marked done | Interface Sounds `confirmation_001` | 0.29 s rising four-note chime; bright but small, since no stars are earned yet |
| `stars_awarded.m4a` | stars awarded | Music Jingles `8-Bit jingles/jingles_NES12` | 8-bit run climbing six notes, the video-game "power-up" feel |
| `treat_redeemed.m4a` | treat redeemed | Music Jingles `Pizzicato jingles/jingles_PIZZI02` | plucked strings climbing a scale; playful, and a different instrument from stars |
| `streak_milestone.m4a` | streak milestone | Music Jingles `Steel jingles/jingles_STEEL02` | steel drums climbing nearly an octave; the biggest sound for the rarest moment |

Processing: leading silence trimmed, mono 44.1 kHz AAC 64 kbps. Peaks set
after encoding: tick -8 dBFS (softer than the rest), celebrations about
-3 dBFS, with stars lowered to -7 dBFS so all three celebrations sit
around -15 to -17 LUFS. Total about 40 KB.
