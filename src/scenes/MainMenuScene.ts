import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '@/config/GameConfig';
import { gsap } from 'gsap';

export class MainMenuScene extends Phaser.Scene {
  private currentNight: number = 1;

  constructor() {
    super({ key: 'MainMenuScene' });
  }

  create(): void {
    this.currentNight = this.loadProgress();

    this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'menu-bg').setDisplaySize(GAME_WIDTH, GAME_HEIGHT);

    // Title
    const title = this.add
      .text(GAME_WIDTH / 2, 160, 'CATCH ME AT NIGHT', {
        fontSize: '56px',
        color: '#cc0000',
        fontFamily: 'serif',
        stroke: '#000000',
        strokeThickness: 6,
        shadow: { offsetX: 4, offsetY: 4, color: '#660000', blur: 8, fill: true },
      })
      .setOrigin(0.5)
      .setAlpha(0);

    const subtitle = this.add
      .text(GAME_WIDTH / 2, 230, '— The Velvet Stage —', {
        fontSize: '20px',
        color: '#888888',
        fontFamily: 'serif',
        fontStyle: 'italic',
      })
      .setOrigin(0.5)
      .setAlpha(0);

    // Animate title in
    gsap.to(title, { alpha: 1, duration: 2, delay: 0.5 });
    gsap.to(subtitle, { alpha: 1, duration: 2, delay: 1 });

    this.createMenuButtons();
    this.addAmbientFlicker();
  }

  private createMenuButtons(): void {
    const cx = GAME_WIDTH / 2;
    const nightLabel = this.currentNight > 5 ? 'Night 6 ★' : `Night ${this.currentNight}`;

    this.createButton(cx, 360, `START — ${nightLabel}`, () => this.startGame(this.currentNight));

    if (this.currentNight > 1) {
      this.createButton(cx, 440, 'NIGHT 1', () => this.startGame(1));
    }

    this.createButton(cx, this.currentNight > 1 ? 520 : 440, 'CUSTOM NIGHT', () => this.openCustomNight());
    this.createButton(cx, this.currentNight > 1 ? 600 : 520, 'LORE', () => this.openLore());
  }

  private createButton(x: number, y: number, label: string, onClick: () => void): void {
    const bg = this.add.rectangle(x, y, 340, 46, 0x1a0000, 0.85).setInteractive({ useHandCursor: true });
    const text = this.add
      .text(x, y, label, {
        fontSize: '20px',
        color: '#dddddd',
        fontFamily: 'monospace',
      })
      .setOrigin(0.5);

    bg.on('pointerover', () => {
      bg.setFillStyle(0x550000, 0.95);
      text.setColor('#ffffff');
    });
    bg.on('pointerout', () => {
      bg.setFillStyle(0x1a0000, 0.85);
      text.setColor('#dddddd');
    });
    bg.on('pointerdown', () => {
      this.cameras.main.flash(200, 0, 0, 0);
      this.time.delayedCall(200, onClick);
    });
  }

  private addAmbientFlicker(): void {
    // Subtle darkness flicker to sell the horror atmosphere on the menu
    this.time.addEvent({
      delay: Phaser.Math.Between(3000, 8000),
      loop: true,
      callback: () => {
        const overlay = this.add.rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, 0x000000, 0);
        this.tweens.add({
          targets: overlay,
          alpha: { from: 0, to: 0.6 },
          duration: 50,
          yoyo: true,
          repeat: Phaser.Math.Between(0, 2),
          onComplete: () => overlay.destroy(),
        });
      },
    });
  }

  private startGame(night: number): void {
    this.scene.start('GameScene', { night });
  }

  private openCustomNight(): void {
    // TODO: custom night selector scene
    console.log('Custom Night — coming soon');
  }

  private openLore(): void {
    // TODO: lore viewer scene
    console.log('Lore — coming soon');
  }

  private loadProgress(): number {
    const saved = localStorage.getItem('cmn-progress');
    return saved ? parseInt(saved, 10) : 1;
  }
}
