import Phaser from 'phaser';
import { EventBus, EVENTS } from '@/utils/EventBus';
import { GAME_WIDTH, GAME_HEIGHT } from '@/config/GameConfig';
import { RoomId } from '@/config/RoomGraph';

export type DoorId = 'officeLeft' | 'officeRight' | 'officeBack';

export interface DoorState {
  id: DoorId;
  closed: boolean;
}

export class DoorButtons {
  private scene: Phaser.Scene;
  private doors: Map<DoorId, DoorState> = new Map();
  private buttons: Map<DoorId, { bg: Phaser.GameObjects.Rectangle; label: Phaser.GameObjects.Text }> = new Map();

  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    this.initDoors();
    this.buildButtons();
  }

  private initDoors(): void {
    const doorIds: DoorId[] = ['officeLeft', 'officeRight', 'officeBack'];
    doorIds.forEach((id) => {
      this.doors.set(id, { id, closed: false });
    });
  }

  private buildButtons(): void {
    const depth = 55;
    const btnH = 56;
    const btnW = 100;

    // Left door — bottom left
    this.createButton('officeLeft', 60, GAME_HEIGHT - 100, 'DOOR\nLEFT', depth, btnW, btnH);

    // Right vent — bottom right
    this.createButton('officeRight', GAME_WIDTH - 60, GAME_HEIGHT - 100, 'VENT\nRIGHT', depth, btnW, btnH);

    // Back vent — bottom center-right
    this.createButton('officeBack', GAME_WIDTH - 60, GAME_HEIGHT - 180, 'VENT\nBACK', depth, btnW, btnH);
  }

  private createButton(id: DoorId, x: number, y: number, label: string, depth: number, w: number, h: number): void {
    const bg = this.scene.add
      .rectangle(x, y, w, h, 0x222222, 0.85)
      .setDepth(depth)
      .setInteractive({ useHandCursor: true });

    const text = this.scene.add
      .text(x, y, label, {
        fontSize: '13px',
        color: '#cccccc',
        fontFamily: 'monospace',
        align: 'center',
      })
      .setOrigin(0.5)
      .setDepth(depth + 1);

    bg.on('pointerover', () => bg.setAlpha(1));
    bg.on('pointerout', () => bg.setAlpha(0.85));
    bg.on('pointerdown', () => this.toggle(id));

    this.buttons.set(id, { bg, label: text });
  }

  toggle(id: DoorId): void {
    const door = this.doors.get(id);
    if (!door) return;

    door.closed = !door.closed;
    this.updateVisual(id);

    const event = this.isDoorId(id) ? EVENTS.DOOR_TOGGLED : EVENTS.VENT_TOGGLED;
    EventBus.emit(event, { id, closed: door.closed });
  }

  private isDoorId(id: DoorId): boolean {
    return id === 'officeLeft';
  }

  private updateVisual(id: DoorId): void {
    const door = this.doors.get(id);
    const btn = this.buttons.get(id);
    if (!door || !btn) return;

    if (door.closed) {
      btn.bg.setFillStyle(0xaa0000, 1);
      btn.label.setColor('#ffffff');
    } else {
      btn.bg.setFillStyle(0x222222, 0.85);
      btn.label.setColor('#cccccc');
    }
  }

  isClosed(id: DoorId): boolean {
    return this.doors.get(id)?.closed ?? false;
  }

  /** Returns set of room IDs that are currently SEALED (closed) */
  getOpenRooms(): Set<RoomId> {
    const open = new Set<RoomId>();
    for (const [id, state] of this.doors.entries()) {
      if (!state.closed) open.add(id as RoomId);
    }
    return open;
  }

  /** All sealed rooms — used by AI to know what's blocked */
  getSealedRooms(): Set<RoomId> {
    const sealed = new Set<RoomId>();
    for (const [id, state] of this.doors.entries()) {
      if (state.closed) sealed.add(id as RoomId);
    }
    return sealed;
  }
}
