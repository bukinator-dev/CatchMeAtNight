import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '@/config/GameConfig';
import { getNightConfig } from '@/config/NightConfig';
import { AISystem } from '@/systems/AISystem';
import { CameraSystem } from '@/systems/CameraSystem';
import { PowerSystem } from '@/systems/PowerSystem';
import { AudioSystem } from '@/systems/AudioSystem';
import { JumpScareSystem } from '@/systems/JumpScareSystem';
import { LoreSystem } from '@/systems/LoreSystem';
import { NightTimer } from '@/utils/NightTimer';
import { EventBus, EVENTS } from '@/utils/EventBus';
import { HUD } from '@/ui/HUD';
import { CameraTablet } from '@/ui/CameraTablet';
import { DoorButtons } from '@/ui/DoorButtons';
import { RoomId } from '@/config/RoomGraph';

interface GameSceneData {
  night: number;
}

export class GameScene extends Phaser.Scene {
  // Systems
  private ai!: AISystem;
  private cameraSystem!: CameraSystem;
  private powerSystem!: PowerSystem;
  private audioSystem!: AudioSystem;
  private jumpScare!: JumpScareSystem;
  private loreSystem!: LoreSystem;
  private nightTimer!: NightTimer;

  // UI
  private hud!: HUD;
  private tablet!: CameraTablet;
  private doorButtons!: DoorButtons;

  // Scene state
  private night: number = 1;
  private isGameOver: boolean = false;
  private playerLookingAtMirror: boolean = false;

  // Office visuals
  private officeBg!: Phaser.GameObjects.Image;
  private mirrorGlow!: Phaser.GameObjects.Rectangle;
  private dianaInMirror!: Phaser.GameObjects.Image;
  private darknessOverlay!: Phaser.GameObjects.Rectangle;
  private powerOutOverlay!: Phaser.GameObjects.Rectangle;

  constructor() {
    super({ key: 'GameScene' });
  }

  init(data: GameSceneData): void {
    this.night = data.night ?? 1;
    this.isGameOver = false;
  }

  create(): void {
    const config = getNightConfig(this.night);

    // ── Systems ───────────────────────────────────────────────────────────
    this.ai = new AISystem(config);
    this.cameraSystem = new CameraSystem(config.lightsOut);
    this.powerSystem = new PowerSystem(config.startingPower, config.powerDrainMultiplier);
    this.audioSystem = new AudioSystem();
    this.jumpScare = new JumpScareSystem(this);
    this.loreSystem = new LoreSystem(this.night);
    this.nightTimer = new NightTimer();

    // ── Office background ─────────────────────────────────────────────────
    this.officeBg = this.add
      .image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'office-bg')
      .setDisplaySize(GAME_WIDTH, GAME_HEIGHT)
      .setDepth(0);

    // Mirror (clickable — triggers Diana mechanic)
    this.buildMirror();

    // Darkness overlay for lights-out nights
    this.darknessOverlay = this.add
      .rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, 0x000000, 0)
      .setDepth(5);

    if (config.lightsOut) {
      this.tweens.add({
        targets: this.darknessOverlay,
        alpha: 0.75,
        duration: 3000,
      });
      this.officeBg.setTexture('office-bg-dark');
    }

    // Power-out overlay (hidden until power dies)
    this.powerOutOverlay = this.add
      .rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, 0x000000, 0)
      .setDepth(90)
      .setVisible(false);

    // ── UI ────────────────────────────────────────────────────────────────
    this.hud = new HUD(this, this.night);
    this.doorButtons = new DoorButtons(this);
    this.tablet = new CameraTablet(this, this.cameraSystem, this.ai, this.loreSystem);

    // ── Events ────────────────────────────────────────────────────────────
    this.bindGameEvents();

    // ── Start night ───────────────────────────────────────────────────────
    this.nightTimer.start();
    EventBus.emit('audio:start');

    // Intro darkness fade
    this.cameras.main.setAlpha(0);
    this.tweens.add({ targets: this.cameras.main, alpha: 1, duration: 2000 });
  }

  update(_time: number, delta: number): void {
    if (this.isGameOver) return;

    const openDoors = this.doorButtons.getOpenRooms();

    this.nightTimer.update(delta);
    this.ai.update(delta, openDoors);
    this.cameraSystem.update(delta);
    this.powerSystem.update(delta);
    this.tablet.update();

    // Diana mirror gaze tracking
    this.ai.diana.updateMirrorGaze(delta, this.playerLookingAtMirror);

    // Update mirror visuals
    this.updateMirrorVisuals();

    // Camera drain when tablet is open
    if (this.cameraSystem.isTabletOpen()) {
      this.powerSystem.addSource('camera', 'camera');
    } else {
      this.powerSystem.removeSource('camera');
    }

    // Door drain
    const sealed = this.doorButtons.getSealedRooms();
    sealed.forEach((id) => this.powerSystem.addSource(`door-${id}`, 'door'));
    // Remove drain for opened doors
    (['officeLeft', 'officeRight', 'officeBack'] as RoomId[]).forEach((id) => {
      if (!sealed.has(id)) this.powerSystem.removeSource(`door-${id}`);
    });
  }

  // ── Mirror ────────────────────────────────────────────────────────────────

  private buildMirror(): void {
    // The mirror is a hotspot in the office — clicking it makes player "look at it"
    const mirrorHit = this.add
      .rectangle(GAME_WIDTH * 0.72, GAME_HEIGHT * 0.3, 180, 220, 0x000000, 0)
      .setDepth(10)
      .setInteractive({ useHandCursor: false });

    this.mirrorGlow = this.add
      .rectangle(GAME_WIDTH * 0.72, GAME_HEIGHT * 0.3, 180, 220, 0x4444aa, 0)
      .setDepth(9);

    this.dianaInMirror = this.add
      .image(GAME_WIDTH * 0.72, GAME_HEIGHT * 0.3, 'office-mirror-diana')
      .setDisplaySize(180, 220)
      .setAlpha(0)
      .setDepth(10);

    mirrorHit.on('pointerover', () => { this.playerLookingAtMirror = true; });
    mirrorHit.on('pointerout', () => { this.playerLookingAtMirror = false; });
  }

  private updateMirrorVisuals(): void {
    const diana = this.ai.diana;

    if (diana.isMirrorActive()) {
      const progress = diana.getMirrorProgress();
      this.dianaInMirror.setAlpha(0.5 + progress * 0.5);
      this.mirrorGlow.setAlpha(progress * 0.4);
    } else {
      this.dianaInMirror.setAlpha(0);
      this.mirrorGlow.setAlpha(0);
    }
  }

  // ── Game events ────────────────────────────────────────────────────────────

  private bindGameEvents(): void {
    EventBus.once(EVENTS.POWER_OUT, () => this.onPowerOut());
    EventBus.once(EVENTS.NIGHT_WIN, () => this.onNightWin());
    EventBus.once(EVENTS.GAME_OVER, (payload: unknown) => {
      const { killer } = payload as { killer: 'lilly' | 'mariam' | 'diana' };
      this.onGameOver(killer);
    });

    // Bump aggression on each in-game hour
    EventBus.on(EVENTS.HOUR_CHANGED, (payload: unknown) => {
      const hour = payload as number;
      if (hour >= 2) this.ai.bumpAggression();
    });

    // Audio lure button (for Lilly)
    this.input.keyboard?.on('keydown-SPACE', () => {
      this.activateAudioLure();
    });
  }

  private activateAudioLure(): void {
    // Audio lure redirects Lilly to the show floor speaker
    if (!this.powerSystem.isOutOfPower()) {
      this.ai.activateLure('showFloor', 3);
      EventBus.emit(EVENTS.AUDIO_LURE_PLAY, { used: true });
      this.sound.play('sfx-lure', { volume: 0.7 });
    }
  }

  private onPowerOut(): void {
    this.powerOutOverlay.setVisible(true);
    this.cameraSystem.onPowerOut();

    this.tweens.add({
      targets: this.powerOutOverlay,
      alpha: { from: 0, to: 0.6 },
      duration: 1500,
      yoyo: true,
      repeat: 3,
    });

    // After power out, girls become far more aggressive
    this.ai.bumpAggression();
    this.ai.bumpAggression();
    this.ai.bumpAggression();
  }

  private onNightWin(): void {
    if (this.isGameOver) return;
    this.isGameOver = true;
    this.nightTimer.stop();
    this.audioSystem.destroy();

    this.cameras.main.flash(500, 255, 255, 180);
    this.time.delayedCall(1000, () => {
      this.scene.start('WinScene', { night: this.night });
    });
  }

  private onGameOver(killer: 'lilly' | 'mariam' | 'diana'): void {
    if (this.isGameOver) return;
    this.isGameOver = true;
    this.nightTimer.stop();
    this.audioSystem.destroy();

    this.time.delayedCall(2000, () => {
      this.scene.start('GameOverScene', {
        killer,
        night: this.night,
        hour: this.nightTimer.getHour(),
      });
    });
  }

  shutdown(): void {
    EventBus.clear();
    this.audioSystem?.destroy();
  }
}
