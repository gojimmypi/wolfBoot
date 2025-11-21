#!/usr/bin/env python3

# Adds .config file to CMakePresets.json
#
# Example:
#   python3 ./tools/scripts/config2presets.py ./config/examples/stm32h7.config

import argparse
import json
import os
import re
import sys
import subprocess
from collections import OrderedDict
from pathlib import Path

COMMENT_RE = re.compile(r"\s*(#.*)?$")
LINE_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*\??=\s*(.*)$')

BOOL_TRUE = {"1", "on", "true", "yes", "y"}
BOOL_FALSE = {"0", "off", "false", "no", "n"}

# Known inherited values: these are provided implicitly by presets/build
# If the .config value matches, do NOT write to cacheVariables.
# If it differs, keep it and warn that it overrides the inherited default.
KNOWN_INHERITED = {
    "SIGN": "ECC256",
    "HASH": "SHA256",
}


def normalize_bool(s: str):
    v = s.strip().lower()
    if v in BOOL_TRUE:
        return "ON"
    if v in BOOL_FALSE:
        return "OFF"
    return None


def parse_config(path: Path):
    kv = OrderedDict()
    with path.open("r", encoding="utf-8") as f:
        for ln in f:
            if COMMENT_RE.fullmatch(ln):
                continue
            m = LINE_RE.match(ln.rstrip("\n"))
            if not m:
                # skip silently; load_dot_config warns elsewhere
                continue
            key, val = m.group(1), m.group(2).strip()
            kv[key] = val
    return kv


def filter_inherited_values(kv):
    """
    Remove keys whose values match KNOWN_INHERITED defaults (do not
    emit them into cacheVariables), and collect messages about
    inherited/overridden values.
    """
    new_kv = OrderedDict()
    messages = []

    for k, v in kv.items():
        if k in KNOWN_INHERITED:
            expected = KNOWN_INHERITED[k]
            v_stripped = v.strip()
            if v_stripped == expected:
                messages.append(
                    "Note: '{}' is an inherited value with default '{}'; "
                    "omitting from preset cacheVariables.".format(k, expected)
                )
                # Do not add to new_kv; rely on inherited value
                continue
            else:
                messages.append(
                    "WARNING: '{}' in .config is '{}', overriding inherited "
                    "default '{}' in preset cacheVariables.".format(
                        k, v_stripped, expected
                    )
                )
                # Fall through to keep the override

        new_kv[k] = v

    return new_kv, messages


def choose_target(kv):
    # Prefer explicit wolfBoot var; else accept TARGET if present
    if "WOLFBOOT_TARGET" in kv and kv["WOLFBOOT_TARGET"]:
        return kv["WOLFBOOT_TARGET"]
    if "TARGET" in kv and kv["TARGET"]:
        return kv["TARGET"]
    return "custom"


def to_cache_vars(kv):
    cache = OrderedDict()
    for k, v in kv.items():
        # Map TARGET -> WOLFBOOT_TARGET if the latter is not already set
        if k == "TARGET" and "WOLFBOOT_TARGET" not in kv:
            cache["WOLFBOOT_TARGET"] = v
            continue

        # Normalize booleans to ON/OFF; keep everything else as strings
        nb = normalize_bool(v)
        cache[k] = nb if nb is not None else v
    return cache


def ensure_base_vars(cache, toolchain_value):
    # Always ensure toolchain file is set using the literal value passed in
    cache.setdefault("CMAKE_TOOLCHAIN_FILE", toolchain_value)
    # Typically desired
    cache.setdefault("BUILD_TEST_APPS", "ON")
    # Force preset mode when generating from .config into presets
    cache["WOLFBOOT_CONFIG_MODE"] = "preset"
    return cache


def make_preset_name(target):
    return f"{target}"


def make_binary_dir(source_dir, target):
    return os.path.join(source_dir, f"build-{target}")


def load_existing_presets(presets_path: Path):
    try:
        with presets_path.open("r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return None


def _merge_configure_preset_list(preset_list, cfg_preset):
    """
    Update or append a configure preset, without reordering existing entries.

    - If a preset with the same name exists:
      * Preserve all top-level keys (inherits, environment, binaryDir, etc.)
      * Merge cacheVariables: existing keys plus new ones, with new values winning.
    - If it does not exist:
      * Append the new preset at the end of the list.
    """
    name = cfg_preset.get("name")
    for idx, existing in enumerate(preset_list):
        if existing.get("name") == name:
            merged = existing.copy()

            existing_cache = existing.get("cacheVariables", {})
            new_cache = cfg_preset.get("cacheVariables", {})

            merged_cache = {}
            if isinstance(existing_cache, dict):
                merged_cache.update(existing_cache)
            if isinstance(new_cache, dict):
                merged_cache.update(new_cache)

            merged["cacheVariables"] = merged_cache
            merged["name"] = name
            preset_list[idx] = merged
            return preset_list

    # Not found: append, do not reorder existing presets
    preset_list.append(cfg_preset)
    return preset_list


def _merge_build_preset_list(preset_list, bld_preset):
    """
    Update or append a build preset, without reordering existing entries.

    - If a preset with the same name exists:
      * Preserve existing jobs/verbose/targets and any other fields.
      * Only ensure configurePreset is set if it was missing.
    - If it does not exist:
      * Append the new preset at the end of the list.
    """
    name = bld_preset.get("name")
    for idx, existing in enumerate(preset_list):
        if existing.get("name") == name:
            merged = existing.copy()
            if "configurePreset" not in merged and "configurePreset" in bld_preset:
                merged["configurePreset"] = bld_preset["configurePreset"]
            merged["name"] = name
            preset_list[idx] = merged
            return preset_list

    # Not found: append, do not reorder existing presets
    preset_list.append(bld_preset)
    return preset_list


def merge_preset(doc, cfg_preset, bld_preset):
    """
    Merge a configure/build preset into an existing CMakePresets.json document.

    - If doc is None, create a fresh schema v3 doc with just these presets.
    - Otherwise:
      * Ensure configurePresets/buildPresets arrays exist.
      * Update or append the specific presets without reordering any others.
    """
    if doc is None:
        return {
            "version": 3,
            "configurePresets": [cfg_preset],
            "buildPresets": [bld_preset],
        }

    if "configurePresets" not in doc or not isinstance(doc["configurePresets"], list):
        doc["configurePresets"] = []
    if "buildPresets" not in doc or not isinstance(doc["buildPresets"], list):
        doc["buildPresets"] = []

    _merge_configure_preset_list(doc["configurePresets"], cfg_preset)
    _merge_build_preset_list(doc["buildPresets"], bld_preset)

    return doc


def extract_unused_vars(output: str):
    """
    Parse CMake output and return a list of
    'Manually-specified variables were not used by the project' names.
    """
    lines = output.splitlines()
    unused = []
    capture = False

    for line in lines:
        if "Manually-specified variables were not used by the project:" in line:
            capture = True
            continue

        if not capture:
            continue

        stripped = line.strip()

        # Skip leading blank lines after the header
        if stripped == "":
            # If we have already collected some variables, a blank line
            # means the list is over.
            if unused:
                break
            continue

        # Only take reasonably-indented lines as variable names
        if line.startswith("    ") or line.startswith("  "):
            unused.append(stripped)
        else:
            # Non-indented line once capture has started means the block is over
            if unused:
                break

    return unused


def run_cmake_and_report_unused(preset_name: str, repo_root: Path):
    """
    Run 'cmake --preset <preset_name>' from repo_root and
    print any unused manually-specified variables reported.
    """
    print("")
    print("Running CMake configure to check for unused manually-specified variables...")
    cmd = ["cmake", "--preset", preset_name]
    print("Command:", " ".join(cmd))

    try:
        proc = subprocess.run(
            cmd,
            cwd=str(repo_root),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except FileNotFoundError:
        print("cmake not found on PATH; skipping unused-variable check.", file=sys.stderr)
        return

    combined = ""
    if proc.stdout:
        combined += proc.stdout
    if proc.stderr:
        if combined:
            combined += "\n"
        combined += proc.stderr

    unused = extract_unused_vars(combined)

    if unused:
        print("")
        print(
            "CMake reported unused manually-specified variables for preset '{}' :".format(
                preset_name
            )
        )
        for name in unused:
            print("  {}".format(name))
    else:
        print("")
        print(
            "No unused manually-specified CMake variables detected for preset '{}'.".format(
                preset_name
            )
        )

    if proc.returncode != 0:
        print("")
        print("Note: 'cmake --preset {}' exited with code {}.".format(
            preset_name, proc.returncode
        ))


def main():
    ap = argparse.ArgumentParser(description="Generate or merge a CMakePresets.json from a .config file")
    ap.add_argument(
        "config",
        help="Path to .config (relative to your current directory if not absolute)",
    )
    ap.add_argument(
        "--toolchain",
        default="cmake/toolchain_arm-none-eabi.cmake",
        help="Path to toolchain file as it should appear in CMAKE_TOOLCHAIN_FILE",
    )
    ap.add_argument(
        "--presets",
        default="CMakePresets.json",
        help="Path to CMakePresets.json to create/merge (relative to repo root if not absolute)",
    )
    ap.add_argument(
        "--generator",
        default="Ninja",
        help="CMake generator",
    )
    ap.add_argument(
        "--preset-name",
        default=None,
        help="Override preset name",
    )
    ap.add_argument(
        "--binary-dir",
        default=None,
        help="Override binaryDir",
    )
    ap.add_argument(
        "--display-name",
        default=None,
        help="Override displayName",
    )
    args = ap.parse_args()

    # Begin common dir init, for /tools/scripts
    script_path = Path(__file__).resolve()
    script_dir = script_path.parent.resolve()

    # repo root is parent of tools/scripts -- go up two levels
    repo_root = (script_dir / ".." / "..").resolve()

    caller_cwd = Path.cwd().resolve()

    # Print only if caller's current working directory is neither REPO_ROOT nor REPO_ROOT/tools/scripts
    if caller_cwd != repo_root and caller_cwd != (repo_root / "tools" / "scripts"):
        print("Script paths:")
        print(f"-- SCRIPT_PATH = {script_path}")
        print(f"-- SCRIPT_DIR  = {script_dir}")
        print(f"-- REPO_ROOT   = {repo_root}")

    # Always work from the repo root, regardless of where the script was invoked
    try:
        os.chdir(repo_root)
    except OSError as e:
        print(f"Failed to cd to: {repo_root}\n{e}", file=sys.stderr)
        sys.exit(1)
    print(f"Starting {script_path} from {Path.cwd().resolve()}")
    # End common dir init

    # Resolve paths:
    # - config: relative to caller's CWD (so user can pass local relative paths naturally)
    # - presets: relative to repo root (we already chdir there)
    config_path = Path(args.config)
    if not config_path.is_absolute():
        config_path = (caller_cwd / config_path).resolve()

    presets_path = Path(args.presets)
    if not presets_path.is_absolute():
        presets_path = (repo_root / presets_path).resolve()

    kv = parse_config(config_path)
    if not kv:
        print(f"No settings parsed from .config: {config_path}", file=sys.stderr)
        sys.exit(2)

    # Handle inherited values like SIGN/HASH before converting to cache vars
    kv, inherited_messages = filter_inherited_values(kv)

    target = choose_target(kv)
    cache = to_cache_vars(kv)

    # Use the toolchain value exactly as passed on the command line,
    # but normalize backslashes for JSON/CMake friendliness.
    toolchain_value = args.toolchain.replace("\\", "/")
    cache = ensure_base_vars(cache, toolchain_value)

    # Build preset objects
    source_dir = "${sourceDir}"  # CMake variable; leave literal
    preset_name = args.preset_name or make_preset_name(target)
    binary_dir = args.binary_dir or make_binary_dir(source_dir, target)
    display_name = args.display_name or f"Linux/WSL ARM ({target})"

    cfg_preset = OrderedDict(
        [
            ("name", preset_name),
            ("displayName", display_name),
            ("inherits", "base"),
            ("generator", args.generator),
            ("binaryDir", binary_dir),
            ("cacheVariables", cache),
        ]
    )
    bld_preset = OrderedDict(
        [
            ("name", preset_name),
            ("configurePreset", preset_name),
            ("jobs", 4),
            ("verbose", True),
            ("targets", ["all"]),
        ]
    )

    # Ensure schema v3 unless existing file says otherwise
    doc = load_existing_presets(presets_path)
    if doc is None:
        doc = {"version": 3}
    if "version" not in doc:
        doc["version"] = 3

    result = merge_preset(doc, cfg_preset, bld_preset)

    # Pretty-print with stable key order
    with presets_path.open("w", encoding="utf-8") as f:
        json.dump(result, f, indent=2)
        f.write("\n")

    print(f"Updated {presets_path} with preset '{preset_name}' targeting '{target}'")

    if inherited_messages:
        print("")
        print("Inherited .config values summary:")
        for msg in inherited_messages:
            print("  " + msg)

    # After updating presets, run cmake and show any unused variables
    run_cmake_and_report_unused(preset_name, repo_root)


if __name__ == "__main__":
    main()
