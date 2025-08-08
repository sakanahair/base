# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

No.0 PILATES - A Pilates studio website with a built-in visual editor for real-time content management. This is a vanilla JavaScript project with component-based architecture and no build dependencies.

## Architecture

### Core System Design

The project uses a **component-loader architecture** where:
- `index.html` serves as the shell that loads components dynamically
- `ComponentLoader.js` manages component initialization and dependency loading
- Each component is self-contained with `.html`, `.css`, `.js`, and `.config.json` files
- No package manager or build tools required - runs directly in browser

### Key JavaScript Systems

1. **Component System** (`js/ComponentLoader.js`)
   - Dynamically loads HTML/CSS/JS for each section
   - Components defined in `components.json`
   - Cache busting via query parameters (`?v=20250126001`)

2. **Visual Editor System**
   - `ElementEditManager.js`: Core element editing logic
   - `UniversalEditor.js`: Unified editing interface
   - `QuickEditMenu.js`: Right-click context menu with AI integration
   - `FloatingControls.js`: Floating UI controls
   - Saves to localStorage and server automatically

3. **AI Integration** (Claude CLI)
   - `AIEditInterface.js`: Connects to Claude CLI sessions
   - `GitHistoryManager.js`: Auto-commits with [QuickEdit] tags
   - Integrates with right-click menu for context-aware editing

4. **Build System** (`js/BuildManager.js`)
   - Creates production builds in `dist/` folder
   - Removes editor-related code from production
   - Triggered via floating menu or API endpoint

### Data Flow

1. **Settings Storage**
   - `element-settings.json`: Persisted element modifications
   - `project-settings.json`: Global project configuration
   - `default-settings.json`: Factory defaults
   - Auto-save to localStorage with 3-second debounce

2. **Image Handling**
   - Large images auto-uploaded to `uploads/images/`
   - Automatic optimization (90% quality)
   - Base64 for small images, server upload for large

## Important Commands

Since this is a vanilla JS project with no build dependencies:

```bash
# Start development (no build needed - open index.html directly)
# Simply serve the directory with any HTTP server

# Create production build
# Use the floating "ビルド" button in the UI
# Or call /api/build endpoint
# Output: dist/ folder

# Reset to defaults
# Use the save menu "デフォルトに戻す" option
```

## Development Workflow

### Adding New Components

1. Create folder in `components/` with component name
2. Add 4 files: `name.html`, `name.css`, `name.js`, `name.config.json`
3. Register in `components.json`
4. Add container div in `index.html`: `<div id="name-component"></div>`

### Modifying Editor Behavior

The editor system centers around:
- **Element selection**: Click detection in `ElementEditManager.js`
- **Edit UI**: Modal rendering in `UniversalEditor.js`
- **Data persistence**: Save logic in `ElementEditManager.saveEdit()`
- **Git tracking**: Auto-commit in `GitHistoryManager.js`

### Working with the AI Editor

1. Right-click any element → "AI" tab
2. Claude CLI session auto-connects to current directory
3. Commands include element context automatically
4. Changes auto-commit with [QuickEdit] tag

## Critical Implementation Details

1. **No Server Required for Development**
   - Can run directly from file:// protocol
   - Server endpoints (`/api/*`) are optional enhancements

2. **Component Loading Order**
   - Components load asynchronously but maintain order
   - Dependencies resolved via `defer` attributes

3. **Editor State Management**
   - All edits stored in `window.editorState`
   - Undo/redo via `window.editHistory`
   - Auto-save triggers on `editorState` changes

4. **Production Build Exclusions**
   - Removes: `js/*Editor*.js`, `js/*Edit*.js`, `js/AI*.js`, `js/Git*.js`
   - Removes: floating controls, quick edit menus
   - Preserves: saved styles and content modifications

## Testing Approach

Manual testing via UI:
1. **Editor**: Click "編集" → select section → modify → save
2. **Build**: Click "ビルド" → verify `dist/` output
3. **AI**: Right-click element → AI tab → test Claude CLI integration
4. **Git**: Check commits with `[QuickEdit]` tag after edits

## Known Constraints

- localStorage limit: ~5-10MB (large images auto-upload to server)
- No hot reload (refresh manually after code changes)
- Git operations require server running
- Claude CLI must be installed for AI features