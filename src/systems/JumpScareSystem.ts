import Phaser from 'phaser';
import { EventBus, EVENTS } from '@/utils/EventBus';
import { GAME_WIDTH, GAME_HEIGHT } from '@/config/GameConfig';
import { gsap } from 'gsap';

export type KillerName = 'lilly' | 'mariam' | 'diana';

export class JumpScareSystem {
  private scene: Phaser.Scene;
  private triggered: boolean = false;

  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    EventBus.once(EVENTS.JUMPSCARE_TRIGGER, (payload: unknown) => {
      const { killer } = payload as { killer: KillerName };
      this.trigger(killer);
    });
  }

  private trigger(killer: KillerName): void {
    if (this.triggered) return;
    this.triggered = true;

    // Flash white
    const flash = this.scene.add
      .rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, 0xffffff)
      .setAlpha(0)
      .setDepth(1000);

    // Killer image at full screen
    const img = this.scene.add
      .image(GAME_WIDTH / 2, GAME_HEIGHT / 2, `${killer}-jumpscare`)
      .setDisplaySize(GAME_WIDTH, GAME_HEIGHT)
      .setAlpha(0)
      .setDepth(999);

    // Screen shake
    this.scene.cameras.main.shake(600, 0.04);

    // Flash → reveal killer
    const tl = gsap.timeline({
      onComplete: () => {
        this.scene.time.delayedCall(1200, () => {
          EventBus.emit(EVENTS.GAME_OVER, { killer });
        });
      },
    });

    tl.to(flash, { alpha: 1, duration: 0.05 })
      .to(flash, { alpha: 0, duration: 0.1 })
      .to(img, { alpha: 1, duration: 0.05 }, '<')
      .to(flash, { alpha: 0.3, duration: 0.4 }, '+=0.1');

    // Play stinger
    const stingerKey = `sting-${killer}`;
    if (this.scene.cache.audio.exists(stingerKey)) {
      this.scene.sound.play(stingerKey, { volume: 1 });
    }
  }
}
