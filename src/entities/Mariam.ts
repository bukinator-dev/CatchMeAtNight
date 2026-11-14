import { RoomId, ROOMS } from '@/config/RoomGraph';
import { EventBus, EVENTS } from '@/utils/EventBus';
import { BaseGirl } from './BaseGirl';

/**
 * MARIAM — Harmony singer.
 * Behavior: Ambushes through vents. Rapid, twitchy. Targets officeRight or officeBack.
 * No audio warning — only breathing sounds when she's in a vent room.
 * When she's in the right hall or east hall, she can SPRINT (double tick chance).
 */
export class Mariam extends BaseGirl {
  private sprintMode: boolean = false;

  constructor(aggression: number) {
    super('mariam', 'stage', aggression);
  }

  onAITick(openDoors: Set<RoomId>): void {
    if (!this.state.isActive) return;

    if (this.state.isAtOffice) {
      const target = this.state.currentRoom as 'officeRight' | 'officeBack';
      if (openDoors.has(target)) {
        EventBus.emit(EVENTS.JUMPSCARE_TRIGGER, { killer: 'mariam' });
      }
      return;
    }

    // Sprint mode: in vent-adjacent rooms she moves twice
    const currentRoom = ROOMS[this.state.currentRoom];
    this.sprintMode = currentRoom.isVent || this.state.currentRoom === 'rightHall' || this.state.currentRoom === 'eastHall';

    this.moveViaVent();

    if (this.sprintMode && Math.random() < 0.4) {
      // Second move in sprint mode
      this.moveViaVent();
    }
  }

  private moveViaVent(): void {
    if (!this.rollMove()) return;

    const room = ROOMS[this.state.currentRoom];

    // Mariam prefers vent paths. Heavily bias toward vent-adjacent rooms.
    const ventRooms = room.adjacent.filter((r) => ROOMS[r].isVent || r.startsWith('office'));
    const pool = ventRooms.length > 0
      ? [...ventRooms, ...ventRooms, ...room.adjacent] // 2:1 vent bias
      : room.adjacent;

    const next = pool[Math.floor(Math.random() * pool.length)] as RoomId;
    this.moveTo(next);

    // Emit vent breathing if she's in a vent
    if (ROOMS[next].isVent) {
      EventBus.emit('audio:mariam:vent', { room: next });
    }
  }
}
