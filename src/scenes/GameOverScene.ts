import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '@/config/GameConfig';
import { gsap } from 'gsap';

export interface GameOverData {
  killer: 'lilly' | 'mariam' | 'diana';
  night: number;
  hour: number;
}

export class GameOverScene extends Phaser.Scene {
  constructor() {
    super({ key: 'GameOverScene' });
  }

  create(data: GameOverData): void {
    // Dark background
    this.add.rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, 0x000000);

    // Static noise overlay
    const staticOverlay = this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'overlay-static')
      .setDisplaySize(GAME_WIDTH, GAME_HEIGHT)
      .setAlpha(0.15);

    this.tweens.add({
      targets: staticOverlay,
      alpha: { from: 0.1, to: 0.25 },
      duration: 150,
      yoyo: true,
      repeat: -1,
    });

    // Killer image fades in
    const killerImg = this.add
      .image(GAME_WIDTH / 2, GAME_HEIGHT / 2 - 40, `${data.killer}-jumpscare`)
      .setDisplaySize(600, 400)
      .setAlpha(0);

    gsap.to(killerImg, { alpha: 0.9, duration: 1.5, delay: 0.3 });

    // "YOU FAILED" text
    const failText = this.add
      .text(GAME_WIDTH / 2, 80, 'YOU FAILED', {
        fontSize: '72px',
        color: '#cc0000',
        fontFamily: 'serif',
        stroke: '#000000',
        strokeThickness: 8,
      })
      .setOrigin(0.5)
      .setAlpha(0);

    gsap.to(failText, { alpha: 1, duration: 0.8, delay: 1.5 });

    // Info text
    const hourLabel = ['12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM', '6 AM'];
    const infoText = this.add
      .text(
        GAME_WIDTH / 2,
        GAME_HEIGHT - 180,
        `Night ${data.night} — Survived until ${hourLabel[data.hour] ?? '??'}`,
        {
          fontSize: '22px',
          color: '#888888',
          fontFamily: 'monospace',
        },
      )
      .setOrigin(0.5)
      .setAlpha(0);

    gsap.to(infoText, { alpha: 1, duration: 1, delay: 2 });

    // Buttons
    this.time.delayedCall(2500, () => this.createButtons(data));
  }

  private createButtons(data: GameOverData): void {
    this.createButton(GAME_WIDTH / 2 - 160, GAME_HEIGHT - 90, 'TRY AGAIN', () => {
      this.scene.start('GameScene', { night: data.night });
    });
    this.createButton(GAME_WIDTH / 2 + 160, GAME_HEIGHT - 90, 'MAIN MENU', () => {
      this.scene.start('MainMenuScene');
    });
  }

  private createButton(x: number, y: number, label: string, onClick: () => void): void {
    const bg = this.add.rectangle(x, y, 260, 44, 0x330000, 0.9).setInteractive({ useHandCursor: true });
    const text = this.add.text(x, y, label, { fontSize: '18px', color: '#dddddd', fontFamily: 'monospace' }).setOrigin(0.5);

    bg.on('pointerover', () => { bg.setFillStyle(0x660000, 1); text.setColor('#ffffff'); });
    bg.on('pointerout', () => { bg.setFillStyle(0x330000, 0.9); text.setColor('#dddddd'); });
    bg.on('pointerdown', onClick);
  }
}
