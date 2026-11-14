import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '@/config/GameConfig';
import { gsap } from 'gsap';

export interface WinData {
  night: number;
}

export class WinScene extends Phaser.Scene {
  constructor() {
    super({ key: 'WinScene' });
  }

  create(data: WinData): void {
    // Save progress
    const nextNight = Math.min(data.night + 1, 6);
    localStorage.setItem('cmn-progress', String(nextNight));

    this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'win-bg').setDisplaySize(GAME_WIDTH, GAME_HEIGHT);

    // "6 AM" alarm clock feel
    const timeText = this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 - 100, '6:00 AM', {
        fontSize: '96px',
        color: '#ffdd44',
        fontFamily: 'monospace',
        stroke: '#000000',
        strokeThickness: 6,
      })
      .setOrigin(0.5)
      .setAlpha(0);

    const survivedText = this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 20, `You survived Night ${data.night}`, {
        fontSize: '30px',
        color: '#cccccc',
        fontFamily: 'serif',
      })
      .setOrigin(0.5)
      .setAlpha(0);

    const flavorLines: Record<number, string> = {
      1: 'The stage is quiet now... for now.',
      2: 'They learned from last night.',
      3: 'Something is different. Mira smiled at the camera.',
      4: "The lights won't come back on.",
      5: "They're done playing.",
      6: 'You have no business being alive.',
    };

    const flavor = this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 80, flavorLines[data.night] ?? '', {
        fontSize: '20px',
        color: '#886666',
        fontFamily: 'serif',
        fontStyle: 'italic',
      })
      .setOrigin(0.5)
      .setAlpha(0);

    gsap.to(timeText, { alpha: 1, duration: 1.5 });
    gsap.to(survivedText, { alpha: 1, duration: 1.5, delay: 0.8 });
    gsap.to(flavor, { alpha: 1, duration: 2, delay: 1.5 });

    this.time.delayedCall(3000, () => this.createButtons(data, nextNight));
  }

  private createButtons(data: WinData, nextNight: number): void {
    const hasNextNight = data.night < 6;

    if (hasNextNight) {
      this.createButton(GAME_WIDTH / 2 - 160, GAME_HEIGHT - 90, `NIGHT ${nextNight}`, () => {
        this.scene.start('GameScene', { night: nextNight });
      });
    }

    this.createButton(
      hasNextNight ? GAME_WIDTH / 2 + 160 : GAME_WIDTH / 2,
      GAME_HEIGHT - 90,
      'MAIN MENU',
      () => { this.scene.start('MainMenuScene'); },
    );
  }

  private createButton(x: number, y: number, label: string, onClick: () => void): void {
    const bg = this.add.rectangle(x, y, 260, 44, 0x001a00, 0.9).setInteractive({ useHandCursor: true });
    const text = this.add.text(x, y, label, { fontSize: '18px', color: '#dddddd', fontFamily: 'monospace' }).setOrigin(0.5);

    bg.on('pointerover', () => { bg.setFillStyle(0x003300, 1); text.setColor('#ffffff'); });
    bg.on('pointerout', () => { bg.setFillStyle(0x001a00, 0.9); text.setColor('#dddddd'); });
    bg.on('pointerdown', onClick);
  }
}
