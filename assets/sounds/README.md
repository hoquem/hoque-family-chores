# Sound Effects

This directory contains sound effects for celebrations and user interactions.

## Required Sound Files

The following audio files should be added in OGG Vorbis format (or MP3):

1. **quest_complete.mp3** (0.8s) - Bright ascending chime (C-E-G notes)
2. **approval_celebrate.mp3** (1.2s) - Victory fanfare with shimmer tail
3. **level_up.mp3** (2.0s) - Epic orchestral hit + rising synth
4. **streak_milestone.mp3** (1.5s) - Warm bell cascade (pentatonic scale)

## Specifications

- Format: OGG Vorbis or MP3
- Sample Rate: 44.1kHz
- Bit Rate: 128kbps
- Channels: Mono
- Size: <100KB each

## Sources

You can obtain these sounds from:
- Royalty-free sound libraries (Freesound.org, AudioJungle)
- AI sound generation (ElevenLabs Sound Effects)
- Custom creation with audio software

## Placeholder Implementation

For development, the app will handle missing sound files gracefully by:
- Skipping sound playback if files are not found
- Logging a warning in development mode
- Continuing with visual and haptic feedback only
