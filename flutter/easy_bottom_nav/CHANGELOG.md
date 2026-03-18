# Changelog

All notable changes to this project will be documented in this file.

The format is based on **Keep a Changelog**,
and this project follows **Semantic Versioning**.

## [0.1.0]

### Added
- Introduced `EasyBottomNav` as a reusable widget built on Flutter's `BottomNavigationBar`.
- Added `EasyBottomNavItem` model with support for `icon`, `activeIcon`, `label`, `tooltip`, and optional `backgroundColor`.
- Added configurable styling and behavior options like colors, label styles, icon size, and feedback.
- Added assertions to validate minimum items and `currentIndex` bounds.

### Changed
- Rebuilt the example app to demonstrate real tab switching with Home, Search, and Profile sections.
- Replaced placeholder tests with widget tests for rendering, tap callbacks, and assertion behavior.
- Updated README usage to reflect the widget-based API.

## [0.0.1] - Initial Release

### Added
- Initial version of `easy_bottom_nav` containing the `EasyBottomNav` class with
  items list, currentIndex, and onTap handler.
- Example app demonstrating basic integration.
- Skeleton test file.


<!--
### Changed
### Deprecated
### Removed
### Fixed
### Security
-->
