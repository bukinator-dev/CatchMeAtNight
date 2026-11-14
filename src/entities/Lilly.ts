import { RoomId, ROOMS } from '@/config/RoomGraph';
import { EventBus, EVENTS } from '@/utils/EventBus';
import { BaseGirl } from './BaseGirl';

/**
 * LILLY — Lead vocalist.
 * Behavior: Moves through main halls toward the left door.
 * Tells via audio: distorted singing that grows louder as she approaches.
 * Can be temporarily redirected by the audio lure.
 * Her too-wide smile is visible on the camera when she's near.
 */
export class Lilly extends BaseGirl {
  private luringRoom: RoomId | null = null;
  private lureTicksRemaining: number = 0;

  constructor(aggression: number) {
    super('lilly', 'stage', aggression);
  }

  onAITick(openDoors: Set<RoomId>): void {
    if (!this.state.isActive) return;

    // If being lured, move toward the lure speaker instead
    if (this.luringRoom && this.lureTicksRemaining > 0) {
      this.lureTicksRemaining--;
      this.moveToward(this.luringRoom);
      if (this.lureTicksRemaining === 0) {
        this.luringRoom = null;
        EventBus.emit(EVENTS.AUDIO_LURE_PLAY, { used: false }); // lure expired
      }
      return;
    }

    // Lilly always tries to reach officeLeft (the left door)
    if (this.state.isAtOffice) {
      // She's at the door — if door is open, she attacks
      if (openDoors.has('officeLeft')) {
        EventBus.emit(EVENTS.JUMPSCARE_TRIGGER, { killer: 'lilly' });
      }
      // If door is closed, she waits (might bang the door — handled by AudioSystem)
      return;
    }

    this.moveToward('officeLeft');
    this.emitSingingAudio();
  }

  /**
   * Redirect Lilly to a speaker room for a number of ticks.
   */
  activateLure(speakerRoom: RoomId, durationTicks: number): void {
    this.luringRoom = speakerRoom;
    this.lureTicksRemaining = durationTicks;
  }

  private moveToward(target: RoomId): void {
    if (!this.rollMove()) return;

    const room = ROOMS[this.state.currentRoom];
    // Simple greedy: pick the adjacent room that is "closer" to the target
    // by checking if it's in the target's direction
    const targetPath: RoomId[] = this.greedyPath(this.state.currentRoom, target);
    const nextRoom = targetPath[1] ?? null;

    if (nextRoom) {
      this.moveTo(nextRoom);
    } else {
      // Fall back to random adjacent
      const adj = room.adjacent;
      this.moveTo(adj[Math.floor(Math.random() * adj.length)] as RoomId);
    }
  }

  private greedyPath(from: RoomId, to: RoomId): RoomId[] {
    // BFS to find path
    const queue: RoomId[][] = [[from]];
    const visited = new Set<RoomId>([from]);

    while (queue.length > 0) {
      const path = queue.shift()!;
      const current = path[path.length - 1];

      if (current === to) return path;

      for (const neighbor of ROOMS[current].adjacent) {
        if (!visited.has(neighbor)) {
          visited.add(neighbor);
          queue.push([...path, neighbor]);
        }
      }
    }

    return [from];
  }

  private emitSingingAudio(): void {
    // Proximity-based: how far from the office is she?
    const path = this.greedyPath(this.state.currentRoom, 'officeLeft');
    const distance = path.length - 1;
    // 0 = at door, 4+ = far away
    if (distance <= 2) {
      EventBus.emit('audio:lilly:nearby', { distance });
    }
  }
}
