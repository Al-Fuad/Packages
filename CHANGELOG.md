# Changelog

All notable changes to this project will be documented in this file.

The format is based on **Keep a Changelog**,  
and this project follows **Semantic Versioning**.

## [0.0.4] - Fix Path

### Fixed
- **Fix Path**: Resolved incorrect file pathing issues within android project.

## [0.0.3] - Change Organization

### Changed
- **Organization Rename**: Updated package name and organization identifiers to `me.alfuad`.

---

## [0.0.2] - Dart Documentation

### Added
- **Full API Documentation**: Added dartdoc comments to 100% of the public API to improve developer experience and pub.dev score.

---

## [0.0.1] - Core Runtime Detection Layer

### Added
- **Emulator Detection**
  - Detects Android emulators and iOS simulators
  - Identifies virtualized environments used for analysis
- **Frida Basic Detection**
  - Detects common Frida server/process indicators
  - Checks for known Frida-related artifacts
- **Root Detection (Android)**
  - Detects rooted devices using multiple indicators
  - Checks for su binaries and dangerous system properties
- **Jailbreak Detection (iOS)**
  - Detects jailbroken environments using filesystem and runtime checks
- **Debugger Detection**
  - Detects attached debuggers at runtime
  - Prevents debugging-based reverse engineering

### Architecture
- Platform-specific detection logic (Android / iOS)
- Modular detection system for easy extension
- Runtime-first security checks (executed during app lifecycle)

### Notes
- Detection modules are implemented and tested individually
- Response handling is intentionally minimal at this stage

---

## [Unreleased]

### Planned
- **Unified Security Result**
  - Centralized security state aggregation
  - Single source of truth for all detection outcomes
- **Simple Runtime Response**
  - Immediate action handling on threat detection
  - Configurable responses (log, warn, restrict, terminate)
- Advanced Frida & Hook Detection
- Memory Tampering Detection
- Security Policy Engine
- Developer Configuration API
