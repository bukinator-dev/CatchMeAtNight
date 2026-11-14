type EventCallback = (...args: unknown[]) => void;

class EventBusClass {
  private listeners: Map<string, EventCallback[]> = new Map();

  on(event: string, callback: EventCallback): void {
    const existing = this.listeners.get(event) ?? [];
    this.listeners.set(event, [...existing, callback]);
  }

  off(event: string, callback: EventCallback): void {
    const existing = this.listeners.get(event) ?? [];
    this.listeners.set(event, existing.filter((cb) => cb !== callback));
  }

  emit(event: string, ...args: unknown[]): void {
    const callbacks = this.listeners.get(event) ?? [];
    callbacks.forEach((cb) => cb(...args));
  }

  once(event: string, callback: EventCallback): void {
    const wrapper: EventCallback = (...args) => {
      callback(...args);
      this.off(event, wrapper);
    };
    this.on(event, wrapper);
  }

  clear(event?: string): void {
    if (event) {
      this.listeners.delete(event);
    } else {
      this.listeners.clear();
    }
  }
}

export const EventBus = new EventBusClass();

// Game event constants
export const EVENTS = {
  // Power
  POWER_CHANGED: 'power:changed',
  POWER_OUT: 'power:out',

  // Doors / Vents
  DOOR_TOGGLED: 'door:toggled',
  VENT_TOGGLED: 'vent:toggled',

  // Camera
  CAMERA_SWITCHED: 'camera:switched',
  CAMERA_STATIC: 'camera:static',

  // Girls
  GIRL_MOVED: 'girl:moved',
  GIRL_AT_DOOR: 'girl:atDoor',
  GIRL_AT_VENT: 'girl:atVent',

  // Jumpscares
  JUMPSCARE_TRIGGER: 'jumpscare:trigger',
  GAME_OVER: 'game:over',

  // Night
  NIGHT_WIN: 'night:win',
  HOUR_CHANGED: 'hour:changed',

  // Lore
  LORE_FOUND: 'lore:found',

  // Audio lure
  AUDIO_LURE_PLAY: 'audioLure:play',
} as const;
