import Phaser from 'phaser';

export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: 'BootScene' });
  }

  preload(): void {
    // Load only the minimal assets needed to show the loading screen
    this.load.image('logo', 'assets/images/ui/logo.png');
    this.load.image('loading-bar-bg', 'assets/images/ui/loading-bar-bg.png');
    this.load.image('loading-bar-fill', 'assets/images/ui/loading-bar-fill.png');
  }

  create(): void {
    this.scene.start('PreloadScene');
  }
}
