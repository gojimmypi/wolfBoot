# VS Code Configuration (.vscode) Directory

This directory contains essential files for [Microsoft Visual Studio Code](https://code.visualstudio.com/) "VSCode".

For specifics on using wolfBoot with VSCode, see the [IDE/VSCode/README.md](../IDE/VSCode/README.md).

For specifics on using wolfBoot with [Visual Studio](https://visualstudio.microsoft.com/), see the [IDE/VisualStudio/README.md](../IDE/VisualStudio/README.md).


## Configuration

This directory contains shared Visual Studio Code project configuration for the `wolfBoot` repository.
These files define workspace behavior for builds, debugging, and editor defaults.
They are intentionally version-controlled so every developer or CI environment gets consistent settings.

For more information, see [VS Code User and workspace settings docs](https://code.visualstudio.com/docs/configure/settings).

> VS Code stores workspace settings at the root of the project in a .vscode folder. This makes it easy to share settings with others in a version-controlled (for example, Git) project.

---

## Files

| File | Purpose | Should Be Committed? |
|------|---------|----------------------|
| settings.json | Defines project-wide VS Code settings (e.g., UTF-8 encoding, CMake integration, default build directories). | Yes |
| tasks.json    | Contains reusable build, clean, and flash tasks for wolfBoot (e.g., OpenOCD flashing, CMake build). | Yes |
| launch.json   | Defines debug configurations (e.g., Cortex-Debug with OpenOCD and SVD mapping). | Yes |

You can safely commit these files — they are environment-agnostic and reproducible across machines.

---

## Relation to Workspace File

The main VS Code workspace for this project lives in:

```
IDE/VSCode/wolfBoot.code-workspace
```

That workspace file defines how VS Code should open the project when launched from the `IDE/VSCode/` directory:
- It points to the real source directory at `../..` (the root of the repo).
- It tells VS Code and CMake Tools where to find `CMakePresets.json`.
- It ensures all build and debug tasks still work as if the project were opened directly in `WOLFBOOT_ROOT`.

Why this split exists:
- `.vscode/` → project-wide configuration (applies to everyone, portable).
- `IDE/VSCode/*.code-workspace` → local entry point for developers launching from within the IDE folder.

---

## Changing Paths or Behavior

If you fork or relocate the repo:
- Update the path in the workspace file to point to your actual root:

```jsonc
// in IDE/VSCode/wolfBoot.code-workspace
"folders": [
  {
    "name": "wolfBoot",
    "path": "../.."        // change if your directory depth differs
  }
],
"settings": {
  "cmake.sourceDirectory": "${env:WOLFBOOT_ROOT}",
  "cmake.buildDirectory": "${env:WOLFBOOT_ROOT}/build-vsc-${buildPresetName}"
}
```

Note: VS Code does not currently expand `${env:...}` in the `folders.path` field,
so the relative `../..` form is required for multi-root workspaces.

---

## Files to Ignore

The following should not be committed:

- `.vs/` (Visual Studio caches)
- Any `build*/`, `out*/`, or `CMakeBuild*/` directories
- `CMakeUserPresets.json`
- User-specific config files generated under `.vscode/` (e.g., `c_cpp_properties.json` if created automatically)

Add these to your `.gitignore` at the repo root if not already excluded.

---

## Summary

- `.vscode/` → shared project configuration (commit to repo)
- `IDE/VSCode/wolfBoot.code-workspace` → convenient workspace launcher for VS Code users
- `.vs/` → local Visual Studio cache (ignore)
- Environment variable `WOLFBOOT_ROOT` (optional) → lets you override paths for custom setups

---

Last updated: November 2025
