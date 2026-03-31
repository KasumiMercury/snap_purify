# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

snap_purify is a Qt 6 Quick (QML) desktop application built with CMake. Currently in early stage — a single-window app scaffold.

## Tech Stack

- **C++** with **Qt 6.10+** (QtQuick module)
- **QML** for UI (loaded via `QQmlApplicationEngine::loadFromModule`)
- **CMake 3.16+** build system
- **MinGW 64-bit** toolchain on Windows
- IDE: **Qt Creator**

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

- `CMakeLists.txt` — project definition; executable target `appsnap_purify`, QML module URI `snap_purify`
- `main.cpp` — application entry point; creates `QGuiApplication` and loads QML via `QQmlApplicationEngine`
- `Main.qml` — root QML component (the main window)

New QML files must be registered in `CMakeLists.txt` under `qt_add_qml_module` → `QML_FILES`. New C++ source files go under `qt_add_executable`.
