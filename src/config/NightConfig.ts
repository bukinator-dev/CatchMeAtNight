export type CharacterName = 'lilly' | 'mariam' | 'diana';

export interface NightConfig {
  night: number;
  /** Aggression level 0–20 per character. 0 = inactive. */
  aggression: Record<CharacterName, number>;
  /** How often (seconds) the AI tick fires for each character */
  aiTickSeconds: number;
  /** Power drain multiplier (1.0 = normal) */
  powerDrainMultiplier: number;
  /** Lights-out mode: cameras use thermal overlay */
  lightsOut: boolean;
  /** Starting power percentage */
  startingPower: number;
}

export const NIGHT_CONFIGS: NightConfig[] = [
  {
    night: 1,
    aggression: { lilly: 2, mariam: 0, diana: 1 },
    aiTickSeconds: 5,
    powerDrainMultiplier: 0.8,
    lightsOut: false,
    startingPower: 100,
  },
  {
    night: 2,
    aggression: { lilly: 4, mariam: 2, diana: 2 },
    aiTickSeconds: 4.5,
    powerDrainMultiplier: 0.9,
    lightsOut: false,
    startingPower: 100,
  },
  {
    night: 3,
    aggression: { lilly: 6, mariam: 5, diana: 4 },
    aiTickSeconds: 4,
    powerDrainMultiplier: 1.0,
    lightsOut: false,
    startingPower: 100,
  },
  {
    night: 4,
    aggression: { lilly: 10, mariam: 8, diana: 7 },
    aiTickSeconds: 3.5,
    powerDrainMultiplier: 1.1,
    lightsOut: true,  // Lights out! Thermal cameras only
    startingPower: 90,
  },
  {
    night: 5,
    aggression: { lilly: 15, mariam: 14, diana: 14 },
    aiTickSeconds: 3,
    powerDrainMultiplier: 1.25,
    lightsOut: true,
    startingPower: 85,
  },
  {
    // Hidden night — unlocked after completing Night 5
    night: 6,
    aggression: { lilly: 20, mariam: 20, diana: 20 },
    aiTickSeconds: 2,
    powerDrainMultiplier: 2.0,
    lightsOut: true,
    startingPower: 70,
  },
];

export function getNightConfig(night: number): NightConfig {
  return NIGHT_CONFIGS[Math.min(night - 1, NIGHT_CONFIGS.length - 1)];
}
