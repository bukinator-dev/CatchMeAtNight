import { EventBus, EVENTS } from './EventBus';

// 1 real second = 1 in-game minute  =>  1 real minute = 1 in-game hour
// Night runs from hour 0 (midnight) to hour 6 (6 AM)
// Total real time: 6 minutes per night
export const SECONDS_PER_HOUR = 60;
export const TOTAL_HOURS = 6;

export class NightTimer {
  private elapsed: number = 0; // seconds
  private currentHour: number = 0;
  private running: boolean = false;

  update(deltaMs: number): void {
    if (!this.running) return;

    this.elapsed += deltaMs / 1000;
    const newHour = Math.floor(this.elapsed / SECONDS_PER_HOUR);

    if (newHour !== this.currentHour) {
      this.currentHour = newHour;
      EventBus.emit(EVENTS.HOUR_CHANGED, this.currentHour);
    }

    if (this.currentHour >= TOTAL_HOURS) {
      this.running = false;
      EventBus.emit(EVENTS.NIGHT_WIN);
    }
  }

  start(): void {
    this.elapsed = 0;
    this.currentHour = 0;
    this.running = false;
    // Small delay before the night actually starts
    setTimeout(() => {
      this.running = true;
    }, 3000);
  }

  stop(): void {
    this.running = false;
  }

  getHour(): number {
    return this.currentHour;
  }

  /** 0.0 – 1.0 progress within current hour */
  getHourProgress(): number {
    return (this.elapsed % SECONDS_PER_HOUR) / SECONDS_PER_HOUR;
  }

  /** Display label: "12 AM", "1 AM", ... "6 AM" */
  getDisplayTime(): string {
    const labels = ['12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM', '6 AM'];
    return labels[Math.min(this.currentHour, 6)];
  }

  isRunning(): boolean {
    return this.running;
  }
}
