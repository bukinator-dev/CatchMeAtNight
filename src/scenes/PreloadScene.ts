import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '@/config/GameConfig';

export class PreloadScene extends Phaser.Scene {
  private progressBar!: Phaser.GameObjects.Graphics;
  private progressBox!: Phaser.GameObjects.Graphics;

  constructor() {
    super({ key: 'PreloadScene' });
  }

  preload(): void {
    this.createLoadingUI();

    this.load.on('progress', (value: number) => this.onProgress(value));
    this.load.on('complete', () => this.onComplete());

    this.loadRoomBackgrounds();
    this.loadCharacterSprites();
    this.loadOfficeAssets();
    this.loadUIAssets();
    this.loadAudio();
    this.loadFonts();
  }

  private createLoadingUI(): void {
    const cx = GAME_WIDTH / 2;
    const cy = GAME_HEIGHT / 2;

    this.add.rectangle(cx, cy, GAME_WIDTH, GAME_HEIGHT, 0x000000);

    this.add
      .text(cx, cy - 80, 'CatchMeAtNight', {
        fontSize: '48px',
        color: '#cc0000',
        fontFamily: 'serif',
      })
      .setOrigin(0.5);

    this.add
      .text(cx, cy - 30, 'Loading...', {
        fontSize: '18px',
        color: '#888888',
        fontFamily: 'monospace',
      })
      .setOrigin(0.5);

    this.progressBox = this.add.graphics();
    this.progressBox.fillStyle(0x222222, 0.8);
    this.progressBox.fillRect(cx - 320, cy + 10, 640, 30);

    this.progressBar = this.add.graphics();
  }

  private onProgress(value: number): void {
    const cx = GAME_WIDTH / 2;
    const cy = GAME_HEIGHT / 2;

    this.progressBar.clear();
    this.progressBar.fillStyle(0xcc0000, 1);
    this.progressBar.fillRect(cx - 316, cy + 14, 632 * value, 22);
  }

  private onComplete(): void {
    this.progressBar.destroy();
    this.progressBox.destroy();
    this.scene.start('MainMenuScene');
  }

  // ── Asset loading ─────────────────────────────────────────────────────────

  private loadRoomBackgrounds(): void {
    const rooms = [
      'stage', 'leftHall', 'rightHall', 'backstage',
      'bathroom', 'eastHall', 'backVent', 'showFloor',
    ];
    rooms.forEach((room) => {
      this.load.image(`room-${room}`, `assets/images/rooms/${room}.png`);
      this.load.image(`room-${room}-thermal`, `assets/images/rooms/${room}-thermal.png`);
    });
  }

  private loadCharacterSprites(): void {
    const chars = ['lilly', 'mariam', 'diana'];
    const rooms = [
      'stage', 'leftHall', 'rightHall', 'backstage',
      'bathroom', 'eastHall', 'backVent', 'showFloor',
      'officeLeft', 'officeRight', 'officeBack',
    ];

    chars.forEach((char) => {
      rooms.forEach((room) => {
        this.load.image(
          `${char}-${room}`,
          `assets/images/characters/${char}/${room}.png`,
        );
      });
      this.load.image(`${char}-jumpscare`, `assets/images/characters/${char}/jumpscare.png`);
    });
  }

  private loadOfficeAssets(): void {
    this.load.image('office-bg', 'assets/images/office/bg.png');
    this.load.image('office-bg-dark', 'assets/images/office/bg-dark.png');
    this.load.image('office-door-left-open', 'assets/images/office/door-left-open.png');
    this.load.image('office-door-left-closed', 'assets/images/office/door-left-closed.png');
    this.load.image('office-vent-right-open', 'assets/images/office/vent-right-open.png');
    this.load.image('office-vent-right-closed', 'assets/images/office/vent-right-closed.png');
    this.load.image('office-vent-back-open', 'assets/images/office/vent-back-open.png');
    this.load.image('office-vent-back-closed', 'assets/images/office/vent-back-closed.png');
    this.load.image('office-mirror', 'assets/images/office/mirror.png');
    this.load.image('office-mirror-diana', 'assets/images/office/mirror-diana.png');
  }

  private loadUIAssets(): void {
    this.load.image('tablet-frame', 'assets/images/ui/tablet-frame.png');
    this.load.image('tablet-static', 'assets/images/ui/tablet-static.png');
    this.load.image('power-bar', 'assets/images/ui/power-bar.png');
    this.load.image('power-bar-fill', 'assets/images/ui/power-bar-fill.png');
    this.load.image('btn-door', 'assets/images/ui/btn-door.png');
    this.load.image('btn-door-active', 'assets/images/ui/btn-door-active.png');
    this.load.image('btn-camera', 'assets/images/ui/btn-camera.png');
    this.load.image('btn-camera-active', 'assets/images/ui/btn-camera-active.png');
    this.load.image('overlay-static', 'assets/images/ui/overlay-static.png');
    this.load.image('overlay-scanlines', 'assets/images/ui/overlay-scanlines.png');
    this.load.image('menu-bg', 'assets/images/ui/menu-bg.png');
    this.load.image('gameover-bg', 'assets/images/ui/gameover-bg.png');
    this.load.image('win-bg', 'assets/images/ui/win-bg.png');
    // Lore documents
    for (let i = 1; i <= 10; i++) {
      this.load.image(`lore-${i}`, `assets/images/lore/note-${i}.png`);
    }
  }

  private loadAudio(): void {
    // Ambient loops
    this.load.audio('amb-hum', 'assets/audio/ambient/hum.mp3');
    this.load.audio('amb-singing-distant', 'assets/audio/ambient/singing-distant.mp3');
    this.load.audio('amb-vent-breathing', 'assets/audio/ambient/vent-breathing.mp3');
    this.load.audio('amb-footsteps', 'assets/audio/ambient/footsteps.mp3');
    this.load.audio('amb-music-box', 'assets/audio/ambient/music-box.mp3');
    this.load.audio('amb-static', 'assets/audio/ambient/static.mp3');
    this.load.audio('amb-power-out', 'assets/audio/ambient/power-out.mp3');
    // Stingers
    this.load.audio('sting-lilly', 'assets/audio/stingers/lilly.mp3');
    this.load.audio('sting-mariam', 'assets/audio/stingers/mariam.mp3');
    this.load.audio('sting-diana', 'assets/audio/stingers/diana.mp3');
    // UI
    this.load.audio('sfx-camera-flip', 'assets/audio/sfx/camera-flip.mp3');
    this.load.audio('sfx-door-close', 'assets/audio/sfx/door-close.mp3');
    this.load.audio('sfx-door-open', 'assets/audio/sfx/door-open.mp3');
    this.load.audio('sfx-power-low', 'assets/audio/sfx/power-low.mp3');
    this.load.audio('sfx-6am', 'assets/audio/sfx/6am.mp3');
    this.load.audio('sfx-lure', 'assets/audio/sfx/lure.mp3');
    // Lore
    for (let i = 1; i <= 5; i++) {
      this.load.audio(`lore-audio-${i}`, `assets/audio/lore/log-${i}.mp3`);
    }
  }

  private loadFonts(): void {
    // Fonts are loaded via CSS @font-face in index.html — just preload the images
  }
}
