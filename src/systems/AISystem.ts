import { Lilly } from '@/entities/Lilly';
import { Mariam } from '@/entities/Mariam';
import { Diana } from '@/entities/Diana';
import { NightConfig } from '@/config/NightConfig';
import { RoomId } from '@/config/RoomGraph';

export class AISystem {
  readonly lilly: Lilly;
  readonly mariam: Mariam;
  readonly diana: Diana;

  private tickAccumulator: number = 0;
  private tickInterval: number; // ms

  constructor(config: NightConfig) {
    this.lilly = new Lilly(config.aggression.lilly);
    this.mariam = new Mariam(config.aggression.mariam);
    this.diana = new Diana(config.aggression.diana);
    this.tickInterval = config.aiTickSeconds * 1000;
  }

  update(deltaMs: number, openDoors: Set<RoomId>): void {
    this.tickAccumulator += deltaMs;

    if (this.tickAccumulator >= this.tickInterval) {
      this.tickAccumulator -= this.tickInterval;
      this.tick(openDoors);
    }
  }

  private tick(openDoors: Set<RoomId>): void {
    this.lilly.onAITick(openDoors);
    this.mariam.onAITick(openDoors);
    this.diana.onAITick(openDoors);
  }

  /** Scale aggression mid-night (optional: used for escalation events) */
  bumpAggression(): void {
    const l = this.lilly.getState().aggression;
    const m = this.mariam.getState().aggression;
    const d = this.diana.getState().aggression;
    this.lilly.setAggression(Math.min(20, l + 1));
    this.mariam.setAggression(Math.min(20, m + 1));
    this.diana.setAggression(Math.min(20, d + 1));
  }

  notifyDoorClosed(room: RoomId): void {
    if (this.lilly.getCurrentRoom() === room) this.lilly.onBlocked();
    if (this.mariam.getCurrentRoom() === room) this.mariam.onBlocked();
    if (this.diana.getCurrentRoom() === room) this.diana.onBlocked();
  }

  activateLure(speakerRoom: RoomId, durationTicks: number): void {
    this.lilly.activateLure(speakerRoom, durationTicks);
  }
}
