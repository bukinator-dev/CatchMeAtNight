import Phaser from 'phaser';
import { CAMERA_ROOMS, RoomId } from '@/config/RoomGraph';
import { CameraSystem } from '@/systems/CameraSystem';
import { AISystem } from '@/systems/AISystem';
import { LoreSystem } from '@/systems/LoreSystem';
import { EventBus, EVENTS } from '@/utils/EventBus';
import { GAME_WIDTH, GAME_HEIGHT } from '@/config/GameConfig';

const TABLET_W = GAME_WIDTH * 0.72;
const TABLET_H = GAME_HEIGHT * 0.72;
const TABLET_X = GAME_WIDTH / 2;
const TABLET_Y = GAME_HEIGHT / 2 - 20;

const CAM_LABELS = ['CAM 1\nStage', 'CAM 2\nL. Hall', 'CAM 3\nR. Hall', 'CAM 4\nBackstage',
  'CAM 5\nBathroom', 'CAM 6\nE. Hall', 'CAM 7\nBack Vent', 'CAM 8\nShow Floor'];

export class CameraTablet {
  private scene: Phaser.Scene;
  private camSystem: CameraSystem;
  private aiSystem: AISystem;
  private loreSystem: LoreSystem;

  private container!: Phaser.GameObjects.Container;
  private feedImage!: Phaser.GameObjects.Image;
  private staticOverlay!: Phaser.GameObjects.Image;
  private characterOverlay!: Phaser.GameObjects.Image;
  private roomLabel!: Phaser.GameObjects.Text;
  private camButtons: Phaser.GameObjects.Container[] = [];
  private toggleButton!: Phaser.GameObjects.Text;
  private isVisible: boolean = false;

  constructor(
    scene: Phaser.Scene,
    camSystem: CameraSystem,
    aiSystem: AISystem,
    loreSystem: LoreSystem,
  ) {
    this.scene = scene;
    this.camSystem = camSystem;
    this.aiSystem = aiSystem;
    this.loreSystem = loreSystem;
    this.build();
    this.bindEvents();
  }

  private build(): void {
    const depth = 60;
    this.container = this.scene.add.container(0, 0).setDepth(depth).setVisible(false);

    // Dark backdrop
    const backdrop = this.scene.add.rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, 0x000000, 0.75);
    this.container.add(backdrop);

    // Tablet frame
    const frame = this.scene.add.rectangle(TABLET_X, TABLET_Y, TABLET_W + 24, TABLET_H + 56, 0x1a1a1a);
    this.container.add(frame);

    // Camera feed area
    this.feedImage = this.scene.add
      .image(TABLET_X, TABLET_Y, 'room-stage')
      .setDisplaySize(TABLET_W, TABLET_H);
    this.container.add(this.feedImage);

    // Character overlay (shows character sprite when present in room)
    this.characterOverlay = this.scene.add
      .image(TABLET_X, TABLET_Y, 'room-stage')
      .setDisplaySize(TABLET_W, TABLET_H)
      .setAlpha(0)
      .setVisible(false);
    this.container.add(this.characterOverlay);

    // Static overlay
    this.staticOverlay = this.scene.add
      .image(TABLET_X, TABLET_Y, 'overlay-static')
      .setDisplaySize(TABLET_W, TABLET_H)
      .setAlpha(0);
    this.container.add(this.staticOverlay);

    // Scanline overlay
    const scanlines = this.scene.add
      .image(TABLET_X, TABLET_Y, 'overlay-scanlines')
      .setDisplaySize(TABLET_W, TABLET_H)
      .setAlpha(0.12);
    this.container.add(scanlines);

    // Room label
    this.roomLabel = this.scene.add
      .text(TABLET_X, TABLET_Y + TABLET_H / 2 + 18, 'CAM 1 — Stage', {
        fontSize: '14px',
        color: '#44ff44',
        fontFamily: 'monospace',
      })
      .setOrigin(0.5, 0);
    this.container.add(this.roomLabel);

    // Camera selector buttons
    this.buildCamButtons();

    // Toggle button (bottom center of office view)
    this.toggleButton = this.scene.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT - 24, '[ CAMERAS ]', {
        fontSize: '16px',
        color: '#44ff44',
        fontFamily: 'monospace',
      })
      .setOrigin(0.5)
      .setDepth(depth - 5)
      .setInteractive({ useHandCursor: true });

    this.toggleButton.on('pointerover', () => this.toggleButton.setColor('#88ff88'));
    this.toggleButton.on('pointerout', () => this.toggleButton.setColor('#44ff44'));
    this.toggleButton.on('pointerdown', () => this.toggle());
  }

  private buildCamButtons(): void {
    const startX = TABLET_X - TABLET_W / 2;
    const startY = TABLET_Y + TABLET_H / 2 + 48;
    const btnW = TABLET_W / 8 - 4;

    for (let i = 0; i < CAMERA_ROOMS.length; i++) {
      const bx = startX + i * (btnW + 4) + btnW / 2;
      const bg = this.scene.add
        .rectangle(bx, startY + 16, btnW, 32, 0x333333)
        .setInteractive({ useHandCursor: true });

      const label = this.scene.add
        .text(bx, startY + 16, `C${i + 1}`, {
          fontSize: '11px',
          color: '#aaaaaa',
          fontFamily: 'monospace',
          align: 'center',
        })
        .setOrigin(0.5);

      const btn = this.scene.add.container(0, 0, [bg, label]);
      this.container.add(btn);
      this.camButtons.push(btn);

      const idx = i;
      bg.on('pointerdown', () => {
        this.camSystem.switchTo(idx);
        this.refreshFeed();
      });
      bg.on('pointerover', () => bg.setFillStyle(0x555555));
      bg.on('pointerout', () => bg.setFillStyle(i === this.camSystem.getActiveCamera() ? 0x224422 : 0x333333));
    }
  }

  toggle(): void {
    this.isVisible = !this.isVisible;
    this.container.setVisible(this.isVisible);

    if (this.isVisible) {
      this.camSystem.openTablet();
      this.refreshFeed();
    } else {
      this.camSystem.closeTablet();
    }
  }

  update(): void {
    if (!this.isVisible) return;

    const camIdx = this.camSystem.getActiveCamera();

    // Static effect
    if (this.camSystem.isStatic(camIdx)) {
      this.staticOverlay.setAlpha(0.6 + Math.random() * 0.3);
    } else {
      this.staticOverlay.setAlpha(0);
    }

    // Check for characters in current room
    this.refreshCharacterOverlay();

    // Check lore discovery
    this.loreSystem.checkDiscovery(camIdx);
  }

  private refreshFeed(): void {
    const camIdx = this.camSystem.getActiveCamera();
    const room = CAMERA_ROOMS[camIdx];
    const isLightsOut = this.camSystem.isLightsOut();
    const bgKey = isLightsOut ? `room-${room}-thermal` : `room-${room}`;

    if (this.scene.textures.exists(bgKey)) {
      this.feedImage.setTexture(bgKey);
    }

    this.roomLabel.setText(`CAM ${camIdx + 1} — ${CAM_LABELS[camIdx].replace('\n', ' ')}`);
  }

  private refreshCharacterOverlay(): void {
    const room = this.camSystem.getActiveRoom();
    const chars = [this.aiSystem.lilly, this.aiSystem.mariam, this.aiSystem.diana];

    // Find the most "frightening" character to show (Diana if present, then others)
    const present = chars.find((c) => c.getCurrentRoom() === room);

    if (present) {
      const spriteKey = `${present.name}-${room}`;
      if (this.scene.textures.exists(spriteKey)) {
        this.characterOverlay.setTexture(spriteKey).setVisible(true).setAlpha(1);
      }
    } else {
      this.characterOverlay.setVisible(false).setAlpha(0);
    }
  }

  private bindEvents(): void {
    EventBus.on(EVENTS.CAMERA_SWITCHED, () => {
      if (this.isVisible) this.refreshFeed();
    });

    EventBus.on(EVENTS.CAMERA_STATIC, (payload: unknown) => {
      const { cam, active } = payload as { cam: number; active: boolean };
      void cam; void active; // Visual handled in update()
    });
  }

  isOpen(): boolean {
    return this.isVisible;
  }

  destroy(): void {
    this.container.destroy();
    this.toggleButton.destroy();
  }
}
