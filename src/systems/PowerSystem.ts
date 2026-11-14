import { EventBus, EVENTS } from '@/utils/EventBus';

export type DrainSource = 'idle' | 'door' | 'vent' | 'camera';

const BASE_DRAIN_PER_SECOND: Record<DrainSource, number> = {
  idle: 0.5,      // Always draining
  door: 1.5,      // Per closed door
  vent: 1.0,      // Per sealed vent
  camera: 0.3,    // Camera tablet open
};

export class PowerSystem {
  private power: number;
  private drainMultiplier: number;
  private activeSources: Map<string, DrainSource> = new Map();
  private isOut: boolean = false;

  constructor(startingPower: number, drainMultiplier: number) {
    this.power = startingPower;
    this.drainMultiplier = drainMultiplier;
    this.activeSources.set('idle', 'idle');
  }

  update(deltaMs: number): void {
    if (this.isOut) return;

    let totalDrain = 0;
    for (const source of this.activeSources.values()) {
      totalDrain += BASE_DRAIN_PER_SECOND[source];
    }

    this.power -= (totalDrain * this.drainMultiplier * deltaMs) / 1000;

    if (this.power <= 0) {
      this.power = 0;
      this.isOut = true;
      EventBus.emit(EVENTS.POWER_OUT);
    }

    EventBus.emit(EVENTS.POWER_CHANGED, this.power);
  }

  addSource(id: string, source: DrainSource): void {
    this.activeSources.set(id, source);
  }

  removeSource(id: string): void {
    this.activeSources.delete(id);
  }

  getPower(): number {
    return this.power;
  }

  getPowerPercent(): number {
    return Math.max(0, Math.min(100, this.power));
  }

  isOutOfPower(): boolean {
    return this.isOut;
  }
}
