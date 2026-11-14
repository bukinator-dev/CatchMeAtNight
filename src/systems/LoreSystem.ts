import { EventBus, EVENTS } from '@/utils/EventBus';
import { RoomId } from '@/config/RoomGraph';

export interface LoreEntry {
  id: number;
  room: RoomId;
  camera: number;      // Which camera index it appears on
  title: string;
  imageKey: string;
  audioKey?: string;
  unlockNight: number; // Minimum night to find it
  discovered: boolean;
}

const LORE_ENTRIES: LoreEntry[] = [
  {
    id: 1,
    room: 'backstage',
    camera: 3,
    title: 'Incident Report — 2019',
    imageKey: 'lore-1',
    audioKey: 'lore-audio-1',
    unlockNight: 1,
    discovered: false,
  },
  {
    id: 2,
    room: 'bathroom',
    camera: 4,
    title: 'Missing Person — Lilly M.',
    imageKey: 'lore-2',
    unlockNight: 1,
    discovered: false,
  },
  {
    id: 3,
    room: 'eastHall',
    camera: 5,
    title: 'Maintenance Log',
    imageKey: 'lore-3',
    audioKey: 'lore-audio-2',
    unlockNight: 2,
    discovered: false,
  },
  {
    id: 4,
    room: 'stage',
    camera: 0,
    title: 'Set List — Final Show',
    imageKey: 'lore-4',
    unlockNight: 2,
    discovered: false,
  },
  {
    id: 5,
    room: 'backVent',
    camera: 6,
    title: 'Handwritten Note',
    imageKey: 'lore-5',
    audioKey: 'lore-audio-3',
    unlockNight: 3,
    discovered: false,
  },
  {
    id: 6,
    room: 'leftHall',
    camera: 1,
    title: 'Police Report Fragment',
    imageKey: 'lore-6',
    unlockNight: 3,
    discovered: false,
  },
  {
    id: 7,
    room: 'showFloor',
    camera: 7,
    title: "Mariam's Diary",
    imageKey: 'lore-7',
    audioKey: 'lore-audio-4',
    unlockNight: 4,
    discovered: false,
  },
  {
    id: 8,
    room: 'rightHall',
    camera: 2,
    title: 'Newspaper Clipping',
    imageKey: 'lore-8',
    unlockNight: 4,
    discovered: false,
  },
  {
    id: 9,
    room: 'backstage',
    camera: 3,
    title: "Diana's Mirror",
    imageKey: 'lore-9',
    audioKey: 'lore-audio-5',
    unlockNight: 5,
    discovered: false,
  },
  {
    id: 10,
    room: 'stage',
    camera: 0,
    title: 'The Last Recording',
    imageKey: 'lore-10',
    unlockNight: 5,
    discovered: false,
  },
];

export class LoreSystem {
  private entries: LoreEntry[];
  private currentNight: number;

  constructor(night: number) {
    this.currentNight = night;
    // Load persisted discoveries
    const saved = localStorage.getItem('cmn-lore');
    const discovered: number[] = saved ? JSON.parse(saved) : [];
    this.entries = LORE_ENTRIES.map((e) => ({ ...e, discovered: discovered.includes(e.id) }));
  }

  /** Call when player views a camera — check if lore is discoverable */
  checkDiscovery(cameraIndex: number): LoreEntry | null {
    const entry = this.entries.find(
      (e) =>
        e.camera === cameraIndex &&
        !e.discovered &&
        e.unlockNight <= this.currentNight,
    );

    if (!entry) return null;

    // 2% chance per camera view to discover lore (feels organic)
    if (Math.random() > 0.02) return null;

    entry.discovered = true;
    this.saveDiscoveries();
    EventBus.emit(EVENTS.LORE_FOUND, entry);
    return entry;
  }

  getDiscovered(): LoreEntry[] {
    return this.entries.filter((e) => e.discovered);
  }

  private saveDiscoveries(): void {
    const ids = this.entries.filter((e) => e.discovered).map((e) => e.id);
    localStorage.setItem('cmn-lore', JSON.stringify(ids));
  }
}
