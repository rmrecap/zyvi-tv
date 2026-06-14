# Zyvi TV - Visual Layout Prompt Specification

## 1. Color Palette & Global Theme
- **Theme Mode:** Ultra Dark Cinematic (Strict)
- **Background Color:** Hex `#0A0E1A` to `#020408` (Deep dark blue-black gradient canvas layer)
- **Primary Accent Color:** Gradient from `#7F00FF` (Neon Purple) to `#E100FF` (Bright Pink)
- **Container Surfaces:** Hex `#121829` with a subtle interior border outline of Hex `#1F2C4C`
- **Text Hierarchy:** Pure White (`#FFFFFF`) for headers, Light Slate Muted Muted Blue (`#8A99AD`) for subtitles, dynamic Neon Green (`#00FFCC`) for explicit "LIVE" tags.

## 2. Critical UI Component Layouts
### A. Interactive Horizontal Filter Bar
- Top-level sticky navigation headers switching between: `LIVE NOW`, `TODAY'S`, `UPCOMING`, `HIGHLIGHTS`.
- Selected tabs must draw a glowing pill-shaped neon background or high-visibility bottom indicator without stuttering during transitions.

### B. Dual-Column Stream Cards
- Left-aligned brand logo or asset image displaying sports type or team vs team flags.
- Real-time active status banner attached indicating how many concurrent active redundant servers are hosted online for that specific feed (e.g., "17 Servers").

### C. Multi-Stream Bottom Selection Drawer
- When clicked, immediately show an overlay sliding smoothly from the bottom containing individual rows for each streaming link route alternative. 
- Individual rows must display structural attributes clearly: `[Server Name]` + `[Quality Badge (4K / FHD / HD)]`.

## 3. Navigation Optimization Rules
- Do not utilize destructive global routing rebuilds when moving from screens.
- Persist state on the parent layout shell using IndexedStack to eliminate blank screen re-rendering intervals.