import { Howl, Howler } from 'howler';
import { EventBus, EVENTS } from '@/utils/EventBus';

interface TrackEntry {
  howl: Howl;
  id?: number;
}

export class AudioSystem {
  private tracks: Map<string, TrackEntry> = new Map();
  private masterVolume: number = 1;
  private ambienceIds: number[] = [];

  constructor() {
    this.bindEvents();
  }

  // ── Phaser scene needs to call this after Phaser loads audio ─────────────
  init(scene: Phaser.Scene): void {
    // Create Howl instances from already-decoded audio in Phaser cache
    // (We use Howler directly with URLs since Phaser and Howler share WebAudio)
    this.createAmbience();
    this.bindEvents();
    void scene; // scene ref unused but kept for future use
  }

  private createAmbience(): void {
    this.createTrack('amb-hum', 'assets/audio/ambient/hum.mp3', true, 0.3);
    this.createTrack('amb-singing-distant', 'assets/audio/ambient/singing-distant.mp3', true, 0);
    this.createTrack('amb-vent-breathing', 'assets/audio/ambient/vent-breathing.mp3', true, 0);
    this.createTrack('amb-static', 'assets/audio/ambient/static.mp3', true, 0);
    this.createTrack('amb-music-box', 'assets/audio/ambient/music-box.mp3', true, 0);
  }

  private createTrack(key: string, src: string, loop: boolean, volume: number): void {
    const howl = new Howl({ src: [src], loop, volume, preload: true });
    this.tracks.set(key, { howl });
  }

  // ── Playback controls ─────────────────────────────────────────────────────

  play(key: string): void {
    const track = this.tracks.get(key);
    if (!track) return;
    if (!track.howl.playing(track.id)) {
      track.id = track.howl.play();
    }
  }

  stop(key: string): void {
    const track = this.tracks.get(key);
    if (!track) return;
    track.howl.stop(track.id);
  }

  fadeIn(key: string, targetVolume: number, durationMs: number): void {
    const track = this.tracks.get(key);
    if (!track) return;
    if (!track.howl.playing(track.id)) {
      track.id = track.howl.play();
    }
    track.howl.fade(0, targetVolume, durationMs, track.id);
  }

  fadeOut(key: string, durationMs: number): void {
    const track = this.tracks.get(key);
    if (!track) return;
    const currentVol = track.howl.volume(track.id) as number;
    track.howl.fade(currentVol, 0, durationMs, track.id);
    setTimeout(() => track.howl.stop(track.id), durationMs);
  }

  setVolume(key: string, volume: number): void {
    const track = this.tracks.get(key);
    if (!track) return;
    track.howl.volume(volume, track.id);
  }

  playOneShot(key: string, volume = 1): void {
    const track = this.tracks.get(key);
    if (!track) return;
    const id = track.howl.play();
    track.howl.volume(volume, id);
  }

  // ── Game event bindings ───────────────────────────────────────────────────

  private bindEvents(): void {
    // Start ambient on boot
    this.on('audio:start', () => {
      this.play('amb-hum');
      this.play('amb-music-box');
    });

    // Lilly proximity singing
    this.on('audio:lilly:nearby', (payload: unknown) => {
      const { distance } = payload as { distance: number };
      const vol = Math.max(0, 1 - distance * 0.3);
      this.setVolume('amb-singing-distant', vol);
      if (vol > 0.1) this.play('amb-singing-distant');
      else this.stop('amb-singing-distant');
    });

    // Mariam vent breathing
    this.on('audio:mariam:vent', () => {
      this.fadeIn('amb-vent-breathing', 0.5, 1000);
    });

    // Camera flip
    this.on(EVENTS.CAMERA_SWITCHED, () => {
      this.playOneShot('sfx-camera-flip', 0.6);
    });

    // Door/vent toggle
    this.on(EVENTS.DOOR_TOGGLED, () => {
      this.playOneShot('sfx-door-close', 0.8);
    });
    this.on(EVENTS.VENT_TOGGLED, () => {
      this.playOneShot('sfx-door-close', 0.5);
    });

    // Power low
    this.on(EVENTS.POWER_CHANGED, (payload: unknown) => {
      const power = payload as number;
      if (power < 15) {
        this.play('sfx-power-low');
        this.fadeIn('amb-static', 0.3, 2000);
      }
    });

    // Power out
    this.on(EVENTS.POWER_OUT, () => {
      this.stop('amb-hum');
      this.stop('amb-music-box');
      this.fadeIn('amb-static', 0.7, 500);
    });

    // 6 AM
    this.on(EVENTS.NIGHT_WIN, () => {
      this.playOneShot('sfx-6am', 1);
      Howler.mute(false);
    });

    // Diana mirror
    this.on('diana:mirror:appear', () => {
      // Subtle reversed audio cue
    });
  }

  private on(event: string, callback: (payload: unknown) => void): void {
    EventBus.on(event, callback as (...args: unknown[]) => void);
  }

  setMasterVolume(vol: number): void {
    this.masterVolume = vol;
    Howler.volume(vol);
  }

  destroy(): void {
    this.tracks.forEach(({ howl }) => howl.unload());
    this.tracks.clear();
  }
}
