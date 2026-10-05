# CLAUDE.md: liquid-glass launcher fork and OS-wide glass project

## Owner and environment
- Dell Latitude 5410, CachyOS, KDE Plasma 6.7.5 on Wayland, KWin 6.7.5, Qt 6.11.2, Intel UHD (CometLake-U GT2) iGPU.
- A desktop with an RTX 5060 Ti arrives around Christmas. Everything is built in quality tiers: Lite for the iGPU now, Full for that GPU later.
- Shell is fish. Give multi-line scripts wrapped in bash -c with single quotes outside and NO single quotes inside. Heredocs only inside that bash -c.
- wl-clipboard is installed (wl-copy / wl-paste). Shader compiler: /usr/lib/qt6/bin/qsb (package qt6-shadertools).
- Owner is highly IT-literate, not a programmer, makes product decisions and delegates implementation.

## How to work with the owner
- One single, complete, copy-pasteable command block per step. No inline comments in command blocks. Keep blocks short enough to show their own output.
- Inspect the real files with grep/sed/awk before writing any patch. Never guess code, and never guess names (a wrong repo name already cost a failed run once).
- Every patch script needs anchor-not-found guards, a brace-balance check and automatic rollback to a backup in ~/plasma-watch/backups.
- Give an explicit undo command with each step. Reload the shell with: plasmashell --replace > /dev/null 2>&1 & disown
- Never use the step-by-step interactive card tool. Plain text and code blocks only.
- Direct, practical, no padding. Acknowledge mistakes plainly when the owner points them out.
- Do not assume macOS. The desktop is only themed to look like it.

## What this repo is
Fork of Petexy/Linexin-Launcher (plasmoid org.linexin.launcher v1.2.1, GPL-3.0-or-later) with two bodies of work. Updating the upstream plugin overwrites the installed patches, so reinstall the patched files from this repo with ./install-glass.sh (upstream own install.sh and build-plasmoid.sh are untouched).

### 1. Freeze fix (done)
The allAppsHelper Instantiator in DashboardRepresentation.qml called dashboardModel.reload() once per app, rebuilding the grid hundreds of times and freezing plasmashell for minutes. Fixed with a 150 ms debounce Timer (dashReloadTimer). Other direct reload() calls remain (onRefreshed etc.). Idea not done: lazy reload only when the launcher opens. Rule: never feed layout size back into model sizes (columns and itemsPerPage derive from width).

### 2. Liquid-glass restyle (done)
Look: liquid glass with Material 3 Expressive feel, animated multi-color wash behind clear glass tiles, springy motion, big radii, thin directional rim light, RGB-drift prism fringe, lens refraction at the edges. The owner finds the candy palette slightly girlish but accepted it. The palette lives in the blob PNGs and can be changed.

Files (all under the ui directory):
- DashboardRepresentation.qml: glassWash Item (properties tier, glassOn, animate, blobSize, reshuffle()) holding five Image blobs (glass-pink, cyan, violet, coral, blue .png, generated feathered radial gradients, so no live blur is needed). Blobs jump to random spots when the launcher opens and drift to new random targets every 7 s over 8 s eased moves. washTex is one shared low-res ShaderEffectSource of glassWash (1/10 scale Lite, 1/4 Full). The old tint Rectangle opacity is bgOpacity * 0.12 with glass on and 0.4 with glass off. Dashboard tiles use glassTile (ShaderEffect with glass.frag.qsb) positioned from the grid layout (dashboardGrid.mapToItem plus cell offsets), re-read on a 450 ms settle timer. Search bar, back button and all tab pills use GlassBacking (regex-patched in, original colors kept behind glassWash.glassOn ? transparent : original). Page wheel handler pageWheelArea has a touchpad swipe lock (220 ms quiet timer) so one swipe moves one page.
- GlassBacking.qml: generic glass backing component. Properties rootRef, washSource, glassOn, tier, shown, tintSrc, hover, rad, shader, region. Tracks Flickable ancestors for scroll position and has a 900 ms slow tick.
- glass.frag / glass.frag.qsb: tile shader (square tiles, rounded box r=0.30).
- glass_pill.frag / glass_pill.frag.qsb: pixel-based shader for pills, search bar and all non-dashboard tiles. Uniforms: region, tintV, pxSize, hover, tier, rad.
- ItemGridDelegate.qml: glass plate behind every app tile in All Apps, category views, letter groups and search results (97 percent of the cell for apps, 86 percent for A-Z letter tiles).
- ItemGridView.qml and RecentView.qml: flat selection highlights are made transparent when glass is on; recent file rows get a glass backing when the anchor matched.
- Labels got renderType Text.QtRendering as an unverified guess for pixelated fonts.

Shader rules learned: QML property names must match the uniform block member names exactly. Compile with qsb --qt6. Avoid fwidth and the reserved word half in GLSL. Pass colors as vector4d, not color, to avoid premultiplication surprises.

### Glass switch
tools/glass (installed to ~/.local/bin/glass): glass off | lite | full | status. It edits glassOn and tier in the launcher, writes the mode to ~/.config/liquidglass/mode, runs every executable in ~/.config/liquidglass/hooks.d/ with the mode as argument, then restarts plasmashell. Every OS-wide piece must add a hook there so one command turns the whole look off. Off is required because the iGPU may not cope with the full system.

## Next: the rest of the OS (not started)
Goal: make the whole OS liquid-glass-washed to match the launcher.
- KWin effects run inside the compositor and can freeze the whole desktop. Always test nested first.
- Leftover reference: /home/a/macos-tahoe-liquid-kde/build/kwin-effects/acrylic-glass/ contains only a compiled liquidglass.so, no source. Its options were RgbDriftStrength, RefractionWidth and blur types Gaussian, Box and Lens. Plan is a fresh effect, not a rewrite of the .so.
- Related earlier idea: force compositor blur on XWayland override-redirect popups such as Brave context menus (Brave never requests blur).
- Share one blurred wash texture across consumers instead of blurring per window.
- Estimate GPU cost per piece against the Intel iGPU before building, and give each piece a Lite and a Full path plus a glass hook.
