import { CAMERA_ROOMS, RoomId } from '@/config/RoomGraph';
import { EventBus, EVENTS } from '@/utils/EventBus';

export class CameraSystem {
  private activeCamera: number = 0; // index into CAMERA_ROOMS
  private isOpen: boolean = false;
  private staticTimers: Map<number, number> = new Map(); // camIndex -> ms remaining
  private staticChance: number = 0.004; // per-frame chance of static on any cam
  private lightsOut: boolean;

  constructor(lightsOut: boolean) {
    this.lightsOut = lightsOut;
  }

  update(deltaMs: number): void {
    // Tick down static timers
    for (const [cam, remaining] of this.staticTimers.entries()) {
      const next = remaining - deltaMs;
      if (next <= 0) {
        this.staticTimers.delete(cam);
        EventBus.emit(EVENTS.CAMERA_STATIC, { cam, active: false });
      } else {
        this.staticTimers.set(cam, next);
      }
    }

    // Random static events
    if (Math.random() < this.staticChance) {
      const cam = Math.floor(Math.random() * CAMERA_ROOMS.length);
      const duration = 500 + Math.random() * 1500;
      this.staticTimers.set(cam, duration);
      EventBus.emit(EVENTS.CAMERA_STATIC, { cam, active: true });
    }
  }

  openTablet(): void {
    this.isOpen = true;
  }

  closeTablet(): void {
    this.isOpen = false;
  }

  isTabletOpen(): boolean {
    return this.isOpen;
  }

  switchTo(index: number): void {
    if (index < 0 || index >= CAMERA_ROOMS.length) return;
    if (index === this.activeCamera) return;
    this.activeCamera = index;
    EventBus.emit(EVENTS.CAMERA_SWITCHED, { cam: index, room: CAMERA_ROOMS[index] });
  }

  getActiveCamera(): number {
    return this.activeCamera;
  }

  getActiveRoom(): RoomId {
    return CAMERA_ROOMS[this.activeCamera];
  }

  isStatic(camIndex: number): boolean {
    return this.staticTimers.has(camIndex);
  }

  isLightsOut(): boolean {
    return this.lightsOut;
  }

  /** Call when power goes out — cameras flicker and die */
  onPowerOut(): void {
    // All cameras go to static
    CAMERA_ROOMS.forEach((_, i) => {
      this.staticTimers.set(i, Infinity);
      EventBus.emit(EVENTS.CAMERA_STATIC, { cam: i, active: true });
    });
  }

  getRoomAtCamera(index: number): RoomId {
    return CAMERA_ROOMS[index];
  }

  get cameraCount(): number {
    return CAMERA_ROOMS.length;
  }
}
