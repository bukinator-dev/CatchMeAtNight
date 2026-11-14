import { RoomId, ROOMS } from '@/config/RoomGraph';
import { EventBus, EVENTS } from '@/utils/EventBus';
import { CharacterName } from '@/config/NightConfig';

export interface GirlState {
  currentRoom: RoomId;
  aggression: number;        // 0–20
  moveChance: number;        // 0.0–1.0, recalculated from aggression
  isActive: boolean;
  isAtOffice: boolean;
  blockedByDoor: boolean;
}

/**
 * Base class for all three girls.
 * Subclasses override onAITick() to implement unique behavior.
 */
export abstract class BaseGirl {
  readonly name: CharacterName;
  protected state: GirlState;

  constructor(name: CharacterName, startRoom: RoomId, aggression: number) {
    this.name = name;
    this.state = {
      currentRoom: startRoom,
      aggression,
      moveChance: aggression / 20,
      isActive: aggression > 0,
      isAtOffice: false,
      blockedByDoor: false,
    };
  }

  /** Called every AI tick. Subclasses implement their unique movement logic. */
  abstract onAITick(openDoors: Set<RoomId>): void;

  setAggression(value: number): void {
    this.state.aggression = value;
    this.state.moveChance = value / 20;
    this.state.isActive = value > 0;
  }

  getState(): Readonly<GirlState> {
    return this.state;
  }

  getCurrentRoom(): RoomId {
    return this.state.currentRoom;
  }

  isAtOfficeEntrance(): boolean {
    return this.state.isAtOffice;
  }

  /**
   * Probabilistic move: rolls against moveChance.
   * Returns true if the roll succeeds.
   */
  protected rollMove(): boolean {
    return Math.random() < this.state.moveChance;
  }

  /**
   * Move to a random adjacent room. Returns the new room or null if no move.
   */
  protected moveToAdjacent(preferOffice = true): RoomId | null {
    if (!this.rollMove()) return null;

    const room = ROOMS[this.state.currentRoom];
    const adjacent = room.adjacent.filter((r) => {
      const target = ROOMS[r];
      // Don't double-move into the office proper — the adjacent office rooms
      // are the "pre-attack" position
      return !target.id.startsWith('office') || preferOffice;
    });

    if (adjacent.length === 0) return null;

    // Slight bias toward office rooms
    const officeAdjacent = adjacent.filter((r) => r.startsWith('office'));
    const pool = preferOffice && officeAdjacent.length > 0
      ? [...adjacent, ...officeAdjacent]
      : adjacent;

    const next = pool[Math.floor(Math.random() * pool.length)] as RoomId;
    this.moveTo(next);
    return next;
  }

  protected moveTo(room: RoomId): void {
    const prev = this.state.currentRoom;
    this.state.currentRoom = room;
    this.state.isAtOffice = room.startsWith('office');

    EventBus.emit(EVENTS.GIRL_MOVED, {
      name: this.name,
      from: prev,
      to: room,
    });

    if (this.state.isAtOffice) {
      const isVent = ROOMS[room].isVent;
      if (isVent) {
        EventBus.emit(EVENTS.GIRL_AT_VENT, { name: this.name, room });
      } else {
        EventBus.emit(EVENTS.GIRL_AT_DOOR, { name: this.name, room });
      }
    }
  }

  /** Called when a door/vent closes while the girl is at the entrance. */
  onBlocked(): void {
    this.state.blockedByDoor = true;
    // Push girl back to the previous non-office room
    const room = ROOMS[this.state.currentRoom];
    const retreat = room.adjacent.find((r) => !r.startsWith('office'));
    if (retreat) {
      this.state.currentRoom = retreat;
      this.state.isAtOffice = false;
    }
  }

  /** Reset to starting position (new night). */
  reset(startRoom: RoomId): void {
    this.state.currentRoom = startRoom;
    this.state.isAtOffice = false;
    this.state.blockedByDoor = false;
  }
}
