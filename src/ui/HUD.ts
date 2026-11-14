import Phaser from 'phaser';
import { EventBus, EVENTS } from '@/utils/EventBus';
import { GAME_WIDTH, GAME_HEIGHT } from '@/config/GameConfig';

export class HUD {
  private scene: Phaser.Scene;
  private clockText!: Phaser.GameObjects.Text;
  private nightText!: Phaser.GameObjects.Text;
  private powerBarBg!: Phaser.GameObjects.Rectangle;
  private powerBarFill!: Phaser.GameObjects.Rectangle;
  private powerText!: Phaser.GameObjects.Text;
  private container!: Phaser.GameObjects.Container;

  constructor(scene: Phaser.Scene, night: number) {
    this.scene = scene;
    this.build(night);
    this.bindEvents();
  }

  private build(night: number): void {
    const depth = 50;

    // ── Clock (top center) ────────────────────────────────────────────────
    this.clockText = this.scene.add
      .text(GAME_WIDTH / 2, 18, '12 AM', {
        fontSize: '28px',
        color: '#dddddd',
        fontFamily: 'monospace',
        stroke: '#000000',
        strokeThickness: 4,
      })
      .setOrigin(0.5, 0)
      .setDepth(depth);

    // Night indicator
    this.nightText = this.scene.add
      .text(GAME_WIDTH / 2, 50, `Night ${night}`, {
        fontSize: '14px',
        color: '#886666',
        fontFamily: 'monospace',
      })
      .setOrigin(0.5, 0)
      .setDepth(depth);

    // ── Power bar (bottom left) ───────────────────────────────────────────
    const barX = 24;
    const barY = GAME_HEIGHT - 48;
    const barW = 220;
    const barH = 20;

    this.scene.add
      .text(barX, barY - 22, 'POWER', {
        fontSize: '12px',
        color: '#888888',
        fontFamily: 'monospace',
      })
      .setDepth(depth);

    this.powerBarBg = this.scene.add
      .rectangle(barX + barW / 2, barY + barH / 2, barW, barH, 0x222222)
      .setDepth(depth);

    this.powerBarFill = this.scene.add
      .rectangle(barX + barW / 2, barY + barH / 2, barW, barH, 0x44cc44)
      .setDepth(depth);

    this.powerText = this.scene.add
      .text(barX + barW + 10, barY, '100%', {
        fontSize: '14px',
        color: '#dddddd',
        fontFamily: 'monospace',
      })
      .setDepth(depth);

    this.container = this.scene.add.container(0, 0).setDepth(depth);
  }

  private bindEvents(): void {
    EventBus.on(EVENTS.POWER_CHANGED, (payload: unknown) => {
      const power = payload as number;
      this.updatePower(power);
    });

    EventBus.on(EVENTS.HOUR_CHANGED, (payload: unknown) => {
      const hour = payload as number;
      this.updateClock(hour);
    });

    EventBus.on(EVENTS.POWER_OUT, () => {
      this.onPowerOut();
    });
  }

  private updatePower(power: number): void {
    const pct = Math.max(0, Math.min(100, power));
    const barW = 220;
    const fillW = (pct / 100) * barW;

    this.powerBarFill.setDisplaySize(fillW, 20);
    // Offset fill left-align within the bg
    this.powerBarFill.setX(24 + fillW / 2);
    this.powerText.setText(`${Math.ceil(pct)}%`);

    // Color: green → yellow → red
    if (pct > 50) {
      this.powerBarFill.setFillStyle(0x44cc44);
    } else if (pct > 20) {
      this.powerBarFill.setFillStyle(0xddaa00);
    } else {
      this.powerBarFill.setFillStyle(0xcc2200);
      this.powerText.setColor('#ff4444');
      // Flicker effect at critical power
      if (pct < 10) {
        this.scene.tweens.add({
          targets: this.powerText,
          alpha: { from: 1, to: 0.3 },
          duration: 150,
          yoyo: true,
        });
      }
    }
  }

  private updateClock(hour: number): void {
    const labels = ['12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM', '6 AM'];
    this.clockText.setText(labels[Math.min(hour, 6)]);

    // Flash the clock on hour change
    this.scene.tweens.add({
      targets: this.clockText,
      alpha: { from: 0.3, to: 1 },
      duration: 400,
    });
  }

  private onPowerOut(): void {
    this.powerBarFill.setVisible(false);
    this.powerText.setText('0%').setColor('#ff0000');
    this.clockText.setColor('#ff0000');
  }

  destroy(): void {
    EventBus.clear(EVENTS.POWER_CHANGED);
    EventBus.clear(EVENTS.HOUR_CHANGED);
    EventBus.clear(EVENTS.POWER_OUT);
    this.container.destroy();
  }
}
