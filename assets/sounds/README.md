# Sound effects

Four short clips, played by `lib/presentation/sound/` (spec:
`docs/superpowers/specs/2026-10-06-sound-effects-design.md`).

Source: Kenney "Interface Sounds", https://kenney.nl/assets/interface-sounds
Licence: CC0 1.0 (public domain), no attribution required.

| Asset | Moment | Source file | Limits |
|---|---|---|---|
| `chore_done.m4a` | chore marked done | _to fill in_ | ≤ 0.3 s, softer than the rest |
| `stars_awarded.m4a` | stars awarded | _to fill in_ | ≤ 1.5 s |
| `treat_redeemed.m4a` | treat redeemed | _to fill in_ | ≤ 1.5 s |
| `streak_milestone.m4a` | streak milestone | _to fill in_ | ≤ 1.5 s |

All four together must stay under 100 KB. Convert from the pack's `.ogg`:

    ffmpeg -i <src>.ogg -af "silenceremove=1:0:-50dB,volume=-6dB" -t 0.3 -c:a aac -b:a 64k chore_done.m4a
    ffmpeg -i <src>.ogg -af "silenceremove=1:0:-50dB" -t 1.5 -c:a aac -b:a 64k stars_awarded.m4a
