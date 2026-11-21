# CatchMeAtNight — Game Design & Development Plan

## Concept

A browser-first horror survival game inspired by Five Nights at Freddy's.
Three singing girls perform on a stage — but come alive at night.
The player is a night security guard. Survive from midnight to 6 AM.
Target audience: **adults**. Maximum scare factor.

---

## Tech Stack

| Layer | Technology | Reason |
|---|---|---|
| Game engine | Phaser 3 | 2D HTML5, scene graph, input, rendering |
| Language | TypeScript | Type safety, IDE support |
| Build tool | Vite | Fast dev server, HMR, optimized builds |
| Audio | Howler.js | Web Audio API, spatial sound, looping — critical for horror |
| Animations / FX | GSAP | Jumpscares, screen shake, UI transitions |
| Mobile bridge | Capacitor | Wraps web app as native iOS / Android |
| State / events | Custom EventBus | No Redux overhead, game-loop friendly |

**Run locally:**
```bash
npm install
npm run dev        # http://localhost:3000
npm run build      # production build in /dist
npx cap sync       # sync to iOS / Android
```

---

## Characters

### Lilly — Lead Vocalist
- Too-wide smile, moves through **halls**
- Audio-telegraphed: faint singing heard before she appears
- Can be redirected with the **audio lure** mechanic
- Targets the **left office door**
- AI style: slow and methodical, but accelerates if ignored

### Mariam — Harmony Singer
- Twitchy, erratic movement
- Attacks through **vents** (right vent / back vent)
- **No audio warning** — she is silent
- Sprints inside vent rooms, slow in open areas
- Targets **office right vent** and **office back vent**
- AI style: random bursts of activity

### Diana — Backup Singer
- Silent, expressionless
- **Teleports** between cameras — does not walk
- Mirror mechanic: appears in the **office mirror**
- Staring at the mirror for more than 2 seconds = **instant death**
- AI style: patience-testing, punishes inattention

---

## Camera System

8 cameras to monitor via a tablet UI:

| Camera | Location |
|---|---|
| CAM 1 | Stage (all three girls start here) |
| CAM 2 | Left Hall |
| CAM 3 | Right Hall |
| CAM 4 | Backstage |
| CAM 5 | Bathroom |
| CAM 6 | East Hall |
| CAM 7 | Back Vent |
| CAM 8 | Show Floor (wide angle) |

---

## Room Graph (movement paths)

```
Stage ──► Left Hall ──► Office (Left Door)
Stage ──► Right Hall ──► Office (Right Vent)
Stage ──► Backstage ──► Back Vent ──► Office (Back Vent)
Stage ──► Bathroom ──► East Hall ──► Show Floor
```

---

## Core Mechanics

| Mechanic | Description |
|---|---|
| Power / battery | Finite per night. Doors, vents, cameras all drain it |
| Left door | Blocks Lilly. High power cost |
| Right vent seal | Blocks Mariam from right vent |
| Back vent seal | Blocks Mariam from back vent |
| Audio lure | Redirect Lilly to a decoy speaker (single use per hour) |
| Office mirror | Diana appears here — do NOT look for more than 2 seconds |
| Camera static | Cameras degrade / glitch as night progresses |
| AI aggression | Each girl has level 1–20. Increases every night |

---

## Night Progression

| Night | Difficulty | Special |
|---|---|---|
| Night 1 | Tutorial — girls barely move | Learn the layout |
| Night 2 | Lilly + Mariam active | Audio lure introduced |
| Night 3 | All three active | Diana mirror mechanic introduced |
| Night 4 | Power reduced 20% | Partial lights-out events |
| Night 5 | Lights out + thermal camera mode | Full darkness, thermal vision only |
| Night 6+ | Hidden / bonus nights | Max aggression, surprise behaviours |

---

## AI Aggression System

Each girl has an independent aggression value (1–20):
- Determines move frequency (timer ticks)
- Increases each night and can spike on random events
- Night config in `src/config/NightConfig.ts`

---

## Project Structure

```
src/
  main.ts                     Entry point
  config/
    GameConfig.ts             Phaser game config
    NightConfig.ts            Aggression values per night
    RoomGraph.ts              Room adjacency map
  scenes/
    BootScene.ts              Asset loading splash
    PreloadScene.ts           Preload all assets
    MainMenuScene.ts          Title screen
    GameScene.ts              Main gameplay loop
    GameOverScene.ts          Jumpscare + death screen
    WinScene.ts               6 AM survived screen
  entities/
    BaseGirl.ts               Shared AI base class
    Lilly.ts                  Hall wanderer
    Mariam.ts                 Vent ambusher
    Diana.ts                  Teleporter + mirror
  systems/
    AISystem.ts               Tick-based movement logic
    CameraSystem.ts           Camera switching, static FX
    PowerSystem.ts            Battery drain, depletion events
    AudioSystem.ts            Howler.js wrapper, spatial audio
    JumpScareSystem.ts        Jumpscare trigger + animation
    LoreSystem.ts             Hidden lore collectibles
  ui/
    HUD.ts                    Clock, power bar, alert indicators
    CameraTablet.ts           Camera grid UI
    DoorButtons.ts            Door / vent seal buttons
  utils/
    EventBus.ts               Global event emitter
    NightTimer.ts             In-game clock (1 night = ~8 min real time)

public/assets/
  images/
    rooms/                    Camera room backgrounds
    characters/               Girl sprites / animation frames
    office/                   Office background, doors, vents, mirror
    ui/                       Tablet frame, buttons, icons
  audio/
    ambient/                  Background hum, HVAC, distant music
    stingers/                 Jump scare hits, tension stingers
    lore/                     Lore audio logs
```

---

## Development Phases

### Phase 1 — Foundation
- Vite + Phaser 3 + TypeScript scaffold
- Scene architecture (Boot → Preload → Menu → Game → GameOver → Win)
- Office UI with placeholder art
- Camera tablet UI
- HUD (clock, power)

### Phase 2 — Core Gameplay
- Room graph + AI movement system
- Lilly hall movement
- Mariam vent movement
- Door / vent seal mechanics
- Power drain system
- Win / lose conditions
- Night 1 playable end-to-end

### Phase 3 — Horror Polish
- Howler.js audio integration (ambient loops, stingers)
- Lilly audio telegraph (distant singing)
- Diana mirror mechanic
- Jumpscare system (GSAP screen flash + character image)
- Camera static / glitch effects (Phaser shaders or canvas filters)
- Screen shake on close calls

### Phase 4 — Content
- Nights 2–5 with scaling aggression
- Audio lure mechanic
- Thermal camera mode (Night 4–5)
- Lore collectibles / hidden notes
- Multiple endings
- Hidden Night 6

### Phase 5 — Mobile
- Responsive layout (portrait + landscape tablet)
- Touch controls for all interactions
- Capacitor integration (iOS + Android)
- Haptic feedback on scares
- PWA manifest for install-to-homescreen

---

## Asset Requirements (provided by user)

- Character reference photos + descriptions for Lilly, Mariam, Diana
- Room / venue photos or concept descriptions
- Audio assets (ambient, music, stingers)

Assets go in `public/assets/` following the folder structure above.
