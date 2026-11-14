import { RoomId } from '@/config/RoomGraph';
import { EventBus, EVENTS } from '@/utils/EventBus';
import { BaseGirl } from './BaseGirl';

/**
 * DIANA — Backup singer. The silent one.
 * Behavior: Does NOT walk room to room — she TELEPORTS between cameras.
 *           No audio warning whatsoever.
 *           Special mechanic: She appears in the office mirror.
 *           If the player looks at the mirror while she's in the mirror pool,
 *           and doesn't look away within 2 seconds — game over.
 *
 * Diana's presence in the mirror is NOT tied to her room position.
 * She's effectively omnipresent and uses a separate "mirror timer" mechanic.
 */
export class Diana extends BaseGirl {
  /** When true, Diana is currently visible in the office mirror */
  private isInMirror: boolean = false;
  private mirrorTimer: number = 0;
  private mirrorHoldLimit: number = 2000; // ms player can look at mirror
  private playerLookingAtMirror: boolean = false;

  // All rooms Diana can teleport to (all camera rooms)
  private readonly teleportPool: RoomId[] = [
    'stage', 'leftHall', 'rightHall', 'backstage',
    'bathroom', 'eastHall', 'backVent', 'showFloor',
    'officeLeft', 'officeRight', 'officeBack',
  ];

  constructor(aggression: number) {
    super('diana', 'stage', aggression);
  }

  onAITick(openDoors: Set<RoomId>): void {
    if (!this.state.isActive) return;

    if (this.state.isAtOffice) {
      const target = this.state.currentRoom as RoomId;
      const isVent = target === 'officeRight' || target === 'officeBack';
      if (!isVent || openDoors.has(target)) {
        if (openDoors.has(target)) {
          EventBus.emit(EVENTS.JUMPSCARE_TRIGGER, { killer: 'diana' });
          return;
        }
      }
    }

    // Diana teleports — she doesn't walk
    if (!this.rollMove()) return;

    const nextRoom = this.teleportPool[
      Math.floor(Math.random() * this.teleportPool.length)
    ] as RoomId;

    // Teleport (skip normal movement events — she just appears)
    this.state.currentRoom = nextRoom;
    this.state.isAtOffice = nextRoom.startsWith('office');

    EventBus.emit(EVENTS.GIRL_MOVED, {
      name: this.name,
      from: null, // She teleports — no "from"
      to: nextRoom,
      isTeleport: true,
    });

    if (this.state.isAtOffice) {
      EventBus.emit(EVENTS.GIRL_AT_DOOR, { name: this.name, room: nextRoom });
    }

    // Activate mirror at higher aggression
    if (this.state.aggression >= 5 && Math.random() < this.state.aggression / 25) {
      this.activateMirror();
    }
  }

  // ── Mirror mechanic ───────────────────────────────────────────────────────

  activateMirror(): void {
    if (this.isInMirror) return;
    this.isInMirror = true;
    this.mirrorTimer = 0;
    EventBus.emit('diana:mirror:appear');
  }

  deactivateMirror(): void {
    this.isInMirror = false;
    this.mirrorTimer = 0;
    EventBus.emit('diana:mirror:disappear');
  }

  /**
   * Called every frame by GameScene.
   * Tracks how long the player has been staring at the mirror.
   */
  updateMirrorGaze(deltaMs: number, playerLooking: boolean): void {
    if (!this.isInMirror) return;

    this.playerLookingAtMirror = playerLooking;

    if (playerLooking) {
      this.mirrorTimer += deltaMs;
      if (this.mirrorTimer >= this.mirrorHoldLimit) {
        // Player stared too long — Diana attacks
        EventBus.emit(EVENTS.JUMPSCARE_TRIGGER, { killer: 'diana' });
        this.deactivateMirror();
      }
    } else {
      // Player looked away — reset timer, Diana disappears
      if (this.mirrorTimer > 0) {
        this.deactivateMirror();
      }
    }
  }

  isMirrorActive(): boolean {
    return this.isInMirror;
  }

  getMirrorProgress(): number {
    return this.mirrorTimer / this.mirrorHoldLimit;
  }
}
