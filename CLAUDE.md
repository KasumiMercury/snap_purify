# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

snap_purify is a Qt 6 Quick (QML) desktop image editing application. Users load images via drag-and-drop or clipboard paste, then place rectangular markers for editing operations.

## Tech Stack

- **C++** with **Qt 6.10+** (QtQuick module only — no QtWidgets)
- **QML** for UI (loaded via `QQmlApplicationEngine::loadFromModule`)
- **CMake 3.16+** build system
- **MinGW 64-bit** toolchain on Windows
- IDE: **Qt Creator** (primary), **CLion** (requires manual CMAKE_PREFIX_PATH)

## Build Commands

```bash
# Configure (from project root)
cmake -B build -G "MinGW Makefiles" -DCMAKE_PREFIX_PATH=<Qt install path>

# Build
cmake --build build

# The executable target is named "appsnap_purify"
```

When using Qt Creator, the build directory is `build/Desktop_Qt_6_11_0_MinGW_64_bit-Debug/`.

## Architecture

### C++ ↔ QML boundary

C++ singletons are created in `main.cpp` and registered via `qmlRegisterSingletonInstance` into the `snap_purify` QML module. QML accesses them by name (e.g., `ImageManager`, `MarkerModel`).

### Image pipeline

- **ImageManager** (`imagemanager.h/cpp`) — Holds a `QImage` in memory. Loads from file path or clipboard. Exposes properties (`hasImage`, `revision`, `fileName`, dimensions) to QML. The `revision` counter increments on every image change to bust QML Image caching.
- **ImageProvider** (`imageprovider.h`) — `QQuickImageProvider` subclass. Bridges `ImageManager::currentImage()` to QML via the `image://snapimage/current?rev=N` URI scheme.

### Marker system

- **MarkerModel** (`markermodel.h/cpp`) — `QAbstractListModel` storing rectangles in **image pixel coordinates** (not display coordinates). Roles: `markerX`, `markerY`, `markerWidth`, `markerHeight`. Designed for future multi-marker support but currently used in single-marker mode.

### QML components

- **Main.qml** — Root window. Handles `DropArea` for file drops, `Shortcut` for clipboard paste, and hosts `ImageCanvas`.
- **ImageCanvas.qml** — Image display + marker overlay. Contains coordinate conversion logic between display space and image space (`imageToDisplay*` / `displayToImage*`). Handles marker creation (drag), movement, corner-resize, and deletion. **Important**: MouseArea drag handlers must use `mapToItem(canvas, ...)` to avoid feedback loops when the dragged item itself moves.

### Adding new files

- New QML files → `CMakeLists.txt` under `qt_add_qml_module` → `QML_FILES`
- New C++ source files → `CMakeLists.txt` under `qt_add_executable`
- New C++ singletons → also register in `main.cpp` via `qmlRegisterSingletonInstance`
