import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '@/config/GameConfig';

type Ctx = CanvasRenderingContext2D;

export class PreloadScene extends Phaser.Scene {
  private progressBar!: Phaser.GameObjects.Graphics;
  private progressBox!: Phaser.GameObjects.Graphics;

  constructor() {
    super({ key: 'PreloadScene' });
  }

  preload(): void {
    this.createLoadingUI();
    // Real art/audio goes here when assets are ready:
    // this.loadRoomBackgrounds();
    // this.loadCharacterSprites();
    // this.loadOfficeAssets();
    // this.loadUIAssets();
    // this.loadAudio();
  }

  create(): void {
    this.progressBar?.destroy();
    this.progressBox?.destroy();
    this.genRoomTextures();
    this.genCharacterTextures();
    this.genOfficeTextures();
    this.genUITextures();
    this.scene.start('MainMenuScene');
  }

  // ── Loading UI ─────────────────────────────────────────────────────────────

  private createLoadingUI(): void {
    const cx = GAME_WIDTH / 2;
    const cy = GAME_HEIGHT / 2;

    this.add.rectangle(cx, cy, GAME_WIDTH, GAME_HEIGHT, 0x000000);

    this.add
      .text(cx, cy - 80, 'CatchMeAtNight', {
        fontSize: '48px',
        color: '#cc0000',
        fontFamily: 'serif',
      })
      .setOrigin(0.5);

    this.add
      .text(cx, cy - 30, 'Loading...', {
        fontSize: '18px',
        color: '#888888',
        fontFamily: 'monospace',
      })
      .setOrigin(0.5);

    this.progressBox = this.add.graphics();
    this.progressBox.fillStyle(0x222222, 0.8);
    this.progressBox.fillRect(cx - 320, cy + 10, 640, 30);

    this.progressBar = this.add.graphics();
  }

  // ── Texture generation helpers ─────────────────────────────────────────────

  private genTex(key: string, w: number, h: number, draw: (ctx: Ctx) => void): void {
    if (this.textures.exists(key)) return;
    const t = this.textures.createCanvas(key, w, h);
    if (!t) return;
    draw(t.getContext() as Ctx);
    t.refresh();
  }

  // ── Room backgrounds (CCTV style) ──────────────────────────────────────────

  private genRoomTextures(): void {
    const W = 800, H = 450;

    const rooms = [
      { key: 'room-stage',     num: 1, name: 'STAGE',      bg: '#12061e', floor: '#1e0e28', accent: '#cc44ff' },
      { key: 'room-leftHall',  num: 2, name: 'LEFT HALL',  bg: '#060e06', floor: '#0a140a', accent: '#44cc44' },
      { key: 'room-rightHall', num: 3, name: 'RIGHT HALL', bg: '#06100e', floor: '#0a1612', accent: '#44ccaa' },
      { key: 'room-backstage', num: 4, name: 'BACKSTAGE',  bg: '#0e0a06', floor: '#160e08', accent: '#cc8844' },
      { key: 'room-bathroom',  num: 5, name: 'BATHROOM',   bg: '#060810', floor: '#080c16', accent: '#4488cc' },
      { key: 'room-eastHall',  num: 6, name: 'EAST HALL',  bg: '#0c0e06', floor: '#121408', accent: '#88cc44' },
      { key: 'room-backVent',  num: 7, name: 'BACK VENT',  bg: '#060606', floor: '#0a0808', accent: '#cc4444' },
      { key: 'room-showFloor', num: 8, name: 'SHOW FLOOR', bg: '#100a0a', floor: '#180e0e', accent: '#ccaaaa' },
    ];

    rooms.forEach((r) => {
      this.genTex(r.key, W, H, (ctx) => {
        ctx.fillStyle = r.bg;
        ctx.fillRect(0, 0, W, H);

        ctx.fillStyle = r.floor;
        ctx.fillRect(0, H * 0.65, W, H * 0.35);

        ctx.strokeStyle = r.accent + '44';
        ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(0, H * 0.65); ctx.lineTo(W, H * 0.65); ctx.stroke();

        this.drawRoomElement(ctx, r.key, W, H, r.accent);

        // Scanlines
        ctx.fillStyle = 'rgba(0,0,0,0.18)';
        for (let y = 0; y < H; y += 4) ctx.fillRect(0, y, W, 2);

        // Vignette
        const vg = ctx.createRadialGradient(W / 2, H / 2, H * 0.25, W / 2, H / 2, H * 0.9);
        vg.addColorStop(0, 'rgba(0,0,0,0)');
        vg.addColorStop(1, 'rgba(0,0,0,0.65)');
        ctx.fillStyle = vg;
        ctx.fillRect(0, 0, W, H);

        // CCTV label
        ctx.fillStyle = r.accent;
        ctx.font = 'bold 15px monospace';
        ctx.fillText(`CAM ${r.num} — ${r.name}`, 12, 26);

        // Recording dot
        ctx.fillStyle = '#44ff44';
        ctx.beginPath(); ctx.arc(W - 18, 16, 5, 0, Math.PI * 2); ctx.fill();
      });

      // Thermal variant (Night 4-5)
      this.genTex(`${r.key}-thermal`, W, H, (ctx) => {
        ctx.fillStyle = '#000800';
        ctx.fillRect(0, 0, W, H);
        ctx.fillStyle = '#001200';
        ctx.fillRect(0, H * 0.65, W, H * 0.35);
        ctx.fillStyle = 'rgba(0,255,68,0.06)';
        ctx.fillRect(0, 0, W, H);
        ctx.fillStyle = 'rgba(0,10,0,0.25)';
        for (let y = 0; y < H; y += 3) ctx.fillRect(0, y, W, 1);
        ctx.fillStyle = '#00ff44';
        ctx.font = 'bold 15px monospace';
        ctx.fillText(`CAM ${r.num} — ${r.name}  [THERMAL]`, 12, 26);
        ctx.fillStyle = '#44ff44';
        ctx.beginPath(); ctx.arc(W - 18, 16, 5, 0, Math.PI * 2); ctx.fill();
      });
    });
  }

  private drawRoomElement(ctx: Ctx, key: string, W: number, H: number, accent: string): void {
    switch (key) {
      case 'room-stage': {
        // Stage platform
        ctx.fillStyle = accent + '22';
        ctx.fillRect(W * 0.2, H * 0.5, W * 0.6, H * 0.15);
        // Curtains
        ctx.fillStyle = '#440022cc';
        ctx.fillRect(0, 0, W * 0.1, H * 0.8);
        ctx.fillRect(W * 0.9, 0, W * 0.1, H * 0.8);
        // Spotlight beams
        ctx.fillStyle = accent + '0e';
        ctx.beginPath(); ctx.moveTo(W * 0.35, 0); ctx.lineTo(W * 0.1, H * 0.65); ctx.lineTo(W * 0.5, H * 0.65); ctx.closePath(); ctx.fill();
        ctx.beginPath(); ctx.moveTo(W * 0.65, 0); ctx.lineTo(W * 0.5, H * 0.65); ctx.lineTo(W * 0.9, H * 0.65); ctx.closePath(); ctx.fill();
        // Microphone stand
        ctx.strokeStyle = accent + '88';
        ctx.lineWidth = 3;
        ctx.beginPath(); ctx.moveTo(W / 2, H * 0.65); ctx.lineTo(W / 2, H * 0.36); ctx.stroke();
        ctx.beginPath(); ctx.arc(W / 2, H * 0.33, 9, 0, Math.PI * 2); ctx.stroke();
        break;
      }
      case 'room-leftHall':
      case 'room-rightHall':
      case 'room-eastHall': {
        // Corridor perspective
        ctx.strokeStyle = accent + '33';
        ctx.lineWidth = 1;
        const vp = { x: W / 2, y: H * 0.32 };
        for (let i = 0; i <= 4; i++) {
          const y = H * 0.08 + i * (H * 0.57 / 4);
          ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(vp.x, vp.y); ctx.stroke();
          ctx.beginPath(); ctx.moveTo(W, y); ctx.lineTo(vp.x, vp.y); ctx.stroke();
        }
        // End door
        ctx.fillStyle = accent + '1a';
        ctx.fillRect(W * 0.42, H * 0.22, W * 0.16, H * 0.43);
        ctx.strokeStyle = accent + '55';
        ctx.lineWidth = 2;
        ctx.strokeRect(W * 0.42, H * 0.22, W * 0.16, H * 0.43);
        break;
      }
      case 'room-backstage': {
        ctx.fillStyle = accent + '22';
        ctx.fillRect(W * 0.08, H * 0.38, W * 0.14, H * 0.27);
        ctx.fillRect(W * 0.28, H * 0.44, W * 0.1, H * 0.21);
        ctx.fillRect(W * 0.68, H * 0.36, W * 0.22, H * 0.29);
        ctx.strokeStyle = accent + '33';
        ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(W * 0.08, H * 0.65); ctx.lineTo(W * 0.65, H * 0.68); ctx.stroke();
        break;
      }
      case 'room-bathroom': {
        ctx.strokeStyle = accent + '22';
        ctx.lineWidth = 1;
        for (let x = 0; x < W; x += 50) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H * 0.65); ctx.stroke(); }
        for (let y = 0; y < H * 0.65; y += 50) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke(); }
        ctx.strokeStyle = accent + '44';
        ctx.lineWidth = 3;
        for (let i = 0; i < 3; i++) ctx.strokeRect(W * 0.6 + i * W * 0.12, H * 0.08, W * 0.1, H * 0.57);
        break;
      }
      case 'room-backVent': {
        ctx.strokeStyle = accent + '55';
        ctx.lineWidth = 4;
        for (let x = 30; x < W; x += 70) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke(); }
        for (let y = 30; y < H; y += 70) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke(); }
        const dg = ctx.createRadialGradient(W / 2, H / 2, 20, W / 2, H / 2, H * 0.5);
        dg.addColorStop(0, 'rgba(0,0,0,0)');
        dg.addColorStop(1, 'rgba(0,0,0,0.92)');
        ctx.fillStyle = dg;
        ctx.fillRect(0, 0, W, H);
        break;
      }
      case 'room-showFloor': {
        for (let row = 0; row < 5; row++) {
          const rowY = H * 0.28 + row * H * 0.08;
          const rowW = W * (0.4 + row * 0.1);
          const rowX = (W - rowW) / 2;
          ctx.fillStyle = accent + '18';
          ctx.fillRect(rowX, rowY, rowW, H * 0.055);
        }
        ctx.fillStyle = '#440022aa';
        ctx.fillRect(W * 0.3, 0, W * 0.4, H * 0.22);
        break;
      }
    }
  }

  // ── Character overlays ──────────────────────────────────────────────────────

  private genCharacterTextures(): void {
    const W = 800, H = 450;
    const chars = [
      { name: 'lilly',  color: '#cc2222', glow: [200, 0,   0]   },
      { name: 'mariam', color: '#2244cc', glow: [0,   50,  200] },
      { name: 'diana',  color: '#8822cc', glow: [100, 0,   180] },
    ];
    const rooms = [
      'stage', 'leftHall', 'rightHall', 'backstage',
      'bathroom', 'eastHall', 'backVent', 'showFloor',
      'officeLeft', 'officeRight', 'officeBack',
    ];

    chars.forEach((c) => {
      const [r, g, b] = c.glow;

      rooms.forEach((room) => {
        this.genTex(`${c.name}-${room}`, W, H, (ctx) => {
          // Tinted overlay
          ctx.fillStyle = `rgba(${r},${g},${b},0.14)`;
          ctx.fillRect(0, 0, W, H);

          // Silhouette body
          const cx = W / 2;
          const cy = H * 0.68;
          ctx.fillStyle = `rgba(${r},${g},${b},0.75)`;
          ctx.fillRect(cx - 28, cy - 110, 56, 110);
          // Head
          ctx.beginPath(); ctx.arc(cx, cy - 125, 32, 0, Math.PI * 2); ctx.fill();
          // White eyes
          ctx.fillStyle = 'rgba(255,255,255,0.95)';
          ctx.beginPath(); ctx.arc(cx - 12, cy - 128, 7, 0, Math.PI * 2); ctx.fill();
          ctx.beginPath(); ctx.arc(cx + 12, cy - 128, 7, 0, Math.PI * 2); ctx.fill();
          // Pupils
          ctx.fillStyle = `rgba(${Math.max(0,r-80)},${Math.max(0,g-20)},${Math.max(0,b-80)},1)`;
          ctx.beginPath(); ctx.arc(cx - 12, cy - 128, 3, 0, Math.PI * 2); ctx.fill();
          ctx.beginPath(); ctx.arc(cx + 12, cy - 128, 3, 0, Math.PI * 2); ctx.fill();
          // Name
          ctx.fillStyle = c.color;
          ctx.font = 'bold 28px monospace';
          ctx.textAlign = 'center';
          ctx.fillText(c.name.toUpperCase(), W / 2, H - 20);
          ctx.textAlign = 'left';
        });
      });

      // Jumpscare face
      this.genTex(`${c.name}-jumpscare`, W, H, (ctx) => {
        ctx.fillStyle = '#000000';
        ctx.fillRect(0, 0, W, H);
        const jcx = W / 2, jcy = H * 0.46;
        // Head glow
        const jg = ctx.createRadialGradient(jcx, jcy, 10, jcx, jcy, 180);
        jg.addColorStop(0, `rgba(${r},${g},${b},0.9)`);
        jg.addColorStop(1, 'rgba(0,0,0,0)');
        ctx.fillStyle = jg;
        ctx.beginPath(); ctx.arc(jcx, jcy, 180, 0, Math.PI * 2); ctx.fill();
        // Eyes
        ctx.fillStyle = 'rgba(255,255,255,1)';
        ctx.beginPath(); ctx.arc(jcx - 55, jcy - 20, 40, 0, Math.PI * 2); ctx.fill();
        ctx.beginPath(); ctx.arc(jcx + 55, jcy - 20, 40, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#000000';
        ctx.beginPath(); ctx.arc(jcx - 55, jcy - 20, 18, 0, Math.PI * 2); ctx.fill();
        ctx.beginPath(); ctx.arc(jcx + 55, jcy - 20, 18, 0, Math.PI * 2); ctx.fill();
        // Smile
        ctx.strokeStyle = c.color;
        ctx.lineWidth = 10;
        ctx.beginPath(); ctx.arc(jcx, jcy + 30, 90, 0.08, Math.PI - 0.08); ctx.stroke();
        // Name
        ctx.fillStyle = c.color;
        ctx.font = 'bold 56px monospace';
        ctx.textAlign = 'center';
        ctx.fillText(c.name.toUpperCase(), W / 2, H - 24);
        ctx.textAlign = 'left';
      });
    });
  }

  // ── Office textures ─────────────────────────────────────────────────────────

  private genOfficeTextures(): void {
    this.genTex('office-bg', GAME_WIDTH, GAME_HEIGHT, (ctx) => {
      // Room background
      ctx.fillStyle = '#0a0608';
      ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);

      // Ceiling strip
      ctx.fillStyle = '#14080c';
      ctx.fillRect(0, 0, GAME_WIDTH, 55);

      // Floor
      ctx.fillStyle = '#12080e';
      ctx.fillRect(0, GAME_HEIGHT * 0.62, GAME_WIDTH, GAME_HEIGHT * 0.38);
      ctx.strokeStyle = '#2a1218';
      ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(0, GAME_HEIGHT * 0.62); ctx.lineTo(GAME_WIDTH, GAME_HEIGHT * 0.62); ctx.stroke();

      // Left door frame
      ctx.strokeStyle = '#3a2822';
      ctx.lineWidth = 10;
      ctx.strokeRect(45, GAME_HEIGHT * 0.14, 125, GAME_HEIGHT * 0.65);
      ctx.fillStyle = '#160e0a';
      ctx.fillRect(50, GAME_HEIGHT * 0.14 + 5, 115, GAME_HEIGHT * 0.65 - 10);
      // Door label
      ctx.fillStyle = '#3a1a10';
      ctx.font = '12px monospace';
      ctx.fillText('LEFT DOOR', 58, GAME_HEIGHT * 0.5);

      // Right side vent
      ctx.strokeStyle = '#3a2822';
      ctx.lineWidth = 5;
      ctx.strokeRect(GAME_WIDTH - 185, GAME_HEIGHT * 0.38, 105, 85);
      ctx.strokeStyle = '#2a1818';
      ctx.lineWidth = 3;
      for (let x = GAME_WIDTH - 180; x < GAME_WIDTH - 90; x += 14) {
        ctx.beginPath(); ctx.moveTo(x, GAME_HEIGHT * 0.38); ctx.lineTo(x, GAME_HEIGHT * 0.38 + 85); ctx.stroke();
      }
      ctx.fillStyle = '#3a1a10';
      ctx.font = '10px monospace';
      ctx.fillText('VENT', GAME_WIDTH - 162, GAME_HEIGHT * 0.38 + 50);

      // Mirror (top right)
      const mx = GAME_WIDTH * 0.72 - 90, my = GAME_HEIGHT * 0.08;
      ctx.fillStyle = '#1a1428';
      ctx.fillRect(mx, my, 180, 230);
      ctx.strokeStyle = '#6655aa';
      ctx.lineWidth = 5;
      ctx.strokeRect(mx, my, 180, 230);
      // Mirror reflection (slight blue tint rectangle)
      ctx.fillStyle = 'rgba(60,50,100,0.2)';
      ctx.fillRect(mx + 5, my + 5, 170, 220);
      ctx.fillStyle = '#4444aa';
      ctx.font = '13px monospace';
      ctx.textAlign = 'center';
      ctx.fillText('MIRROR', mx + 90, my + 125);
      ctx.textAlign = 'left';

      // Security monitors on desk
      ctx.fillStyle = '#1a1008';
      ctx.fillRect(GAME_WIDTH * 0.3, GAME_HEIGHT * 0.46, GAME_WIDTH * 0.3, GAME_HEIGHT * 0.16);
      ctx.fillStyle = '#0a0a0a';
      ctx.fillRect(GAME_WIDTH * 0.32, GAME_HEIGHT * 0.47, 150, 90);
      ctx.fillStyle = '#112211';
      ctx.fillRect(GAME_WIDTH * 0.33, GAME_HEIGHT * 0.475, 130, 78);
      ctx.fillStyle = '#44ff44';
      ctx.font = '10px monospace';
      ctx.fillText('MONITOR', GAME_WIDTH * 0.34, GAME_HEIGHT * 0.52);

      // Desk surface
      ctx.fillStyle = '#221408';
      ctx.fillRect(GAME_WIDTH * 0.18, GAME_HEIGHT * 0.62, GAME_WIDTH * 0.64, 18);

      // Vignette
      const vg = ctx.createRadialGradient(GAME_WIDTH / 2, GAME_HEIGHT / 2, 150, GAME_WIDTH / 2, GAME_HEIGHT / 2, 720);
      vg.addColorStop(0, 'rgba(0,0,0,0)');
      vg.addColorStop(1, 'rgba(0,0,0,0.55)');
      ctx.fillStyle = vg;
      ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
    });

    // Dark version (lights-out nights)
    this.genTex('office-bg-dark', GAME_WIDTH, GAME_HEIGHT, (ctx) => {
      ctx.fillStyle = '#030204';
      ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
      ctx.fillStyle = '#080408';
      ctx.fillRect(0, GAME_HEIGHT * 0.62, GAME_WIDTH, GAME_HEIGHT * 0.38);
      ctx.strokeStyle = '#1a0a08';
      ctx.lineWidth = 6;
      ctx.strokeRect(45, GAME_HEIGHT * 0.14, 125, GAME_HEIGHT * 0.65);
      // Mirror visible in darkness
      ctx.strokeStyle = '#332255';
      ctx.lineWidth = 3;
      ctx.strokeRect(GAME_WIDTH * 0.72 - 90, GAME_HEIGHT * 0.08, 180, 230);
    });

    // Mirror-Diana overlay
    this.genTex('office-mirror-diana', 180, 230, (ctx) => {
      ctx.fillStyle = '#0a0820';
      ctx.fillRect(0, 0, 180, 230);
      ctx.fillStyle = 'rgba(100,0,180,0.55)';
      ctx.beginPath(); ctx.arc(90, 85, 44, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = 'rgba(90,0,160,0.75)';
      ctx.fillRect(60, 118, 60, 85);
      ctx.fillStyle = 'rgba(255,255,255,0.95)';
      ctx.beginPath(); ctx.arc(76, 76, 8, 0, Math.PI * 2); ctx.fill();
      ctx.beginPath(); ctx.arc(104, 76, 8, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#000000';
      ctx.beginPath(); ctx.arc(76, 76, 3, 0, Math.PI * 2); ctx.fill();
      ctx.beginPath(); ctx.arc(104, 76, 3, 0, Math.PI * 2); ctx.fill();
    });
  }

  // ── UI overlays and menu backgrounds ──────────────────────────────────────

  private genUITextures(): void {
    // Scanlines
    this.genTex('overlay-scanlines', 800, 450, (ctx) => {
      for (let y = 0; y < 450; y += 4) {
        ctx.fillStyle = 'rgba(0,0,0,0.3)';
        ctx.fillRect(0, y, 800, 2);
      }
    });

    // Static noise
    this.genTex('overlay-static', 800, 450, (ctx) => {
      const img = ctx.createImageData(800, 450);
      for (let i = 0; i < img.data.length; i += 4) {
        const v = Math.random() > 0.5 ? Math.floor(Math.random() * 255) : 0;
        img.data[i] = v; img.data[i + 1] = v; img.data[i + 2] = v;
        img.data[i + 3] = Math.random() > 0.6 ? 180 : 0;
      }
      ctx.putImageData(img, 0, 0);
    });

    // Main menu background
    this.genTex('menu-bg', GAME_WIDTH, GAME_HEIGHT, (ctx) => {
      ctx.fillStyle = '#030008';
      ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
      ctx.fillStyle = '#0a0012';
      ctx.fillRect(0, GAME_HEIGHT * 0.42, GAME_WIDTH, GAME_HEIGHT * 0.58);
      // Red spotlight from top
      const sg = ctx.createRadialGradient(GAME_WIDTH * 0.5, 0, 0, GAME_WIDTH * 0.5, 0, GAME_HEIGHT * 0.65);
      sg.addColorStop(0, 'rgba(80,0,0,0.35)');
      sg.addColorStop(1, 'rgba(0,0,0,0)');
      ctx.fillStyle = sg;
      ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
      // Stage silhouette at bottom
      ctx.fillStyle = '#0d0010';
      ctx.fillRect(GAME_WIDTH * 0.2, GAME_HEIGHT * 0.78, GAME_WIDTH * 0.6, GAME_HEIGHT * 0.22);
      // Vignette
      const vg = ctx.createRadialGradient(GAME_WIDTH / 2, GAME_HEIGHT / 2, 80, GAME_WIDTH / 2, GAME_HEIGHT / 2, 760);
      vg.addColorStop(0, 'rgba(0,0,0,0)');
      vg.addColorStop(1, 'rgba(0,0,0,0.92)');
      ctx.fillStyle = vg;
      ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
    });

    // Game over background
    this.genTex('gameover-bg', GAME_WIDTH, GAME_HEIGHT, (ctx) => {
      ctx.fillStyle = '#0a0000';
      ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
      const rg = ctx.createRadialGradient(GAME_WIDTH / 2, GAME_HEIGHT / 2, 0, GAME_WIDTH / 2, GAME_HEIGHT / 2, 520);
      rg.addColorStop(0, 'rgba(90,0,0,0.65)');
      rg.addColorStop(1, 'rgba(0,0,0,0)');
      ctx.fillStyle = rg;
      ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
    });

    // Win background
    this.genTex('win-bg', GAME_WIDTH, GAME_HEIGHT, (ctx) => {
      ctx.fillStyle = '#000a08';
      ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
      const wg = ctx.createRadialGradient(GAME_WIDTH / 2, GAME_HEIGHT / 2, 0, GAME_WIDTH / 2, GAME_HEIGHT / 2, 520);
      wg.addColorStop(0, 'rgba(0,70,30,0.55)');
      wg.addColorStop(1, 'rgba(0,0,0,0)');
      ctx.fillStyle = wg;
      ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
    });
  }
}
