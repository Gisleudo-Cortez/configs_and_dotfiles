# Hyprland Rice Inspiration — Sci-Fi / Cyberpunk / Hacker

Stack: Arch Linux + Hyprland + Kitty + Fish + Neovim + Waybar/Quickshell + Rofi + Mako

---

## Full-Stack Dotfiles

### 1. cybrland — scherrer-txt
**https://github.com/scherrer-txt/cybrland** | ★201

Draws directly from the Cyberpunk 2077 UI design language — a hand-crafted 12-color `cybrcolors` palette (neon on deep black). 12 custom wallpapers, modular (cherry-pick components). Covers Hyprland, Kitty, Fish, Waybar, Rofi, Starship, Neovim, Firefox.

---

### 2. end-4/dots-hyprland — Illogical Impulse
**https://github.com/end-4/dots-hyprland** | ★14,200

The visual ceiling of the ecosystem. Material You dynamic theming: change the wallpaper and the entire UI recolors automatically. Entirely Quickshell-based (QML = 77% of repo) — the smoothest animations in any Hyprland config. AI assistant sidebar, live window previews, integrated media controls. Community reaction: "this looks like a movie prop."

---

### 3. JaKooLit/Hyprland-Dots
**https://github.com/JaKooLit/Hyprland-Dots** | ★3,400

Signature **"Neon Circuit" Waybar style** — the most-referenced cyberpunk Waybar CSS design in the community. Uses **Wallust** for dynamic color generation from wallpaper (neon wallpaper = neon UI, automatically). Also includes a Quickshell Overview panel. Full stack: Hyprland, Waybar, Kitty, Rofi, Neovim, Fish. Wallpaper bank at `JaKooLit/Wallpaper-Bank`.

---

### 4. Matt-FTW/dotfiles — Catppuccin Macchiato
**https://github.com/Matt-FTW/dotfiles** | ★734

Exceptional visual polish. 34% of the repo is CSS — extreme attention to detail. Uses Catppuccin Macchiato (deep purple/pink neon on `#24273a`). Includes GLSL shaders (7.3%), custom browser CSS. Covers full stack. Good reference for *how* to achieve polish, not just what palette to use.

---

### 5. HyDE Project — 63 Themes with Neovim Sync
**https://github.com/HyDE-Project/hyde-gallery** | ★8,500

Meta-project with 63 themes. Standouts for cyberpunk/sci-fi:
- **Edge Runner** — explicit cyberpunk neon
- **Hack the Box** — green-black hacker aesthetic
- **Synth Wave** — retrowave/outrun neon
- **Tokyo Night** — neon city lights, blue/purple on near-black
- **Decay Green** — terminal-hacker green

`hyde.nvim` keeps Neovim in color-sync with the active desktop theme automatically.

---

### 6. Cyber-Arch — CyberAnpu
**https://github.com/CyberAnpu/Cyber-Arch**

Animated wallpapers via **swww** toggle, **cava** audio visualizer themed to match, **cmatrix** terminal Matrix rain effect. All utility scripts styled with consistent cyberpunk color output. Covers Hyprland, Waybar, Kitty, NvChad (Neovim), Fish.

---

### 7. neomikr0n/dotfiles — Yellow Matrix
**https://github.com/neomikr0n/dotfiles**

Yellow-on-black matrix aesthetic (references the red/blue pill philosophy). Uses **mpvpaper** for full video wallpapers, **tmatrix** for live Matrix rain, and GLSL shaders (7.6% of repo) for compositor-level screen effects.

---

### 8. AnanyTanwar/hyprland-dotfiles — 8-Theme Switcher
**https://github.com/AnanyTanwar/hyprland-dotfiles**

Best theme-switcher implementation: 8 themes (Catppuccin Mocha, Tokyo Night, Dracula, Rose Pine, Gruvbox, Nord) with automatic Neovim color sync via JSON palettes. `Super+T` to switch. Good base if you want a multi-theme system.

---

## Neovim Colorschemes

### 9. cyberdream.nvim — scottmckendry
**https://github.com/scottmckendry/cyberdream.nvim** | ★1,300

Best pure cyberpunk Neovim colorscheme. Transparent-background mode designed for Hyprland blur integration — floating neon code on a blurred wallpaper. Kitty and Fish extras for full-stack unification.

Palette:
- Background: `#16181a`
- Cyan: `#5ef1ff`
- Magenta: `#ff5ef1`
- Green: `#5eff6c`
- Blue: `#5ea1ff`

---

### 10. tokyonight.nvim — folke
**https://github.com/folke/tokyonight.nvim**

Most-used dark Neovim theme in the community. The `night` variant (`#1a1b26` base, cyan/green keyword accents) is the reference for "neon city" aesthetics. First-class Kitty and Fish extras. HyDE uses this as its Neovim sync target.

---

## Quickshell / Waybar

### 11. doannc2212/quickshell-config — 206 Themes
**https://github.com/doannc2212/quickshell-config**

Modular Quickshell config with 206 themes (Tokyo Night, Catppuccin, + 187 MonkeyType community themes). Drop-in potential for the existing Quickshell setup. Each module (bar, launcher, notifications, media OSD, wallpaper manager) works independently.

---

## Wallpapers

### 12. tokyonight-backgrounds — czechbol
**https://github.com/czechbol/tokyonight-backgrounds** | ★62

4K/QHD/FHD wallpapers built to pair with the Tokyo Night palette — neon blues and purples that match exactly what Neovim and Kitty render. Programming and sci-fi themed (code art, OS logos, molecular structures). CC0 licensed.

---

## Key Concepts Worth Stealing

| Concept | What it does | Tool |
|---|---|---|
| Dynamic wallpaper theming | Neon wallpaper → neon UI colors everywhere automatically | Wallust / end-4 Material You |
| Animated video wallpapers | Sci-fi loops, Matrix rain, city-at-night as live wallpaper | mpvpaper |
| GLSL compositor shaders | Chromatic aberration, scanlines, screen-space effects | Hyprland `decoration.screen_shader` |
| Transparent terminal + blur | Floating neon code on blurred wallpaper | cyberdream.nvim + Hyprland blur |
| Neon Circuit Waybar | Most-referenced cyberpunk Waybar CSS pattern | JaKooLit |
| Quickshell animations | Fluid motion impossible with CSS Waybar | end-4 / doannc2212 |
| cava as visual element | Audio visualizer themed to match desktop | Cyber-Arch, neomikr0n |
| Full Neovim color sync | Editor syncs with active system theme | HyDE hyde.nvim / AnanyTanwar |

---

## Stack Compatibility Matrix

| Source | Hyprland | Kitty | Fish | Neovim | Waybar | Quickshell | Rofi |
|---|---|---|---|---|---|---|---|
| cybrland | Y | Y | Y | Y | Y | — | Y |
| end-4 dots-hyprland | Y | — | Y | — | — | Y | — |
| JaKooLit Hyprland-Dots | Y | Y | Y | Y | Y | Y | Y |
| Matt-FTW dotfiles | Y | Y | Y | Y | Y | — | Y |
| AnanyTanwar dotfiles | Y | Y | — | Y | Y | — | Y |
| HyDE / hyprdots | Y | Y | — | Y | Y | — | Y |
| Cyber-Arch | Y | Y | Y | NvChad | Y | — | Y |
| cyberdream.nvim | — | Y | Y | Y | — | — | — |
| doannc2212 quickshell | Y | — | — | — | — | Y | Y |

---

## YouTube Showcases

- [MINDBLOWING NEW ARCH LINUX HYPRLAND SETUP 2025](https://www.youtube.com/watch?v=lR7EtbVYWuc)
- [Rice Hyprland in 2 Hours | Full Guide](https://www.youtube.com/watch?v=ftHfRmtqDTU)
- [My Complete October 2025 Hyprland Setup | Full Breakdown](https://www.youtube.com/watch?v=LvV2ImYuWXg)
- [THE REAL MINDBLOWING ARCH LINUX HYPRLAND SETUP 2025 (Ft. ML4W DotFiles)](https://www.youtube.com/watch?v=Nx-Y3I58D58)
