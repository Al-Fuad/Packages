/// A lightweight wrapper around Flutter's [BottomNavigationBar].
library easy_bottom_nav;

import 'package:flutter/material.dart';

/// Callback used when a bottom navigation item is tapped.
typedef EasyBottomNavTapCallback = void Function(int index);

/// Describes one item shown by [EasyBottomNav].
class EasyBottomNavItem {
  /// Creates an item for [EasyBottomNav].
  const EasyBottomNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.tooltip,
    this.backgroundColor,
  });

  /// The icon shown when this item is not selected.
  final Widget icon;

  /// The icon shown when this item is selected.
  final Widget? activeIcon;

  /// The label shown below the icon.
  final String label;

  /// Optional semantic tooltip for the item.
  final String? tooltip;

  /// Optional background color used by shifting navigation bars.
  final Color? backgroundColor;
}

/// A simple and customizable bottom navigation widget.
class EasyBottomNav extends StatelessWidget {
  /// Creates an [EasyBottomNav].
  const EasyBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.type,
    this.elevation,
    this.iconSize = 24,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true,
    this.backgroundColor,
    this.enableFeedback,
  }) : assert(items.length >= 2, 'EasyBottomNav requires at least two items.'),
       assert(
         currentIndex >= 0 && currentIndex < items.length,
         'currentIndex must be within items bounds.',
       );

  /// Navigation items to display.
  final List<EasyBottomNavItem> items;

  /// Currently selected item index.
  final int currentIndex;

  /// Called when a new item is selected.
  final EasyBottomNavTapCallback onTap;

  /// Defines the layout and behavior of the navigation bar.
  final BottomNavigationBarType? type;

  /// The z-coordinate of this navigation bar.
  final double? elevation;

  /// Size of all item icons.
  final double iconSize;

  /// Color of the selected item.
  final Color? selectedItemColor;

  /// Color of unselected items.
  final Color? unselectedItemColor;

  /// Text style for selected item labels.
  final TextStyle? selectedLabelStyle;

  /// Text style for unselected item labels.
  final TextStyle? unselectedLabelStyle;

  /// Whether to show labels for selected items.
  final bool showSelectedLabels;

  /// Whether to show labels for unselected items.
  final bool showUnselectedLabels;

  /// The navigation bar background color.
  final Color? backgroundColor;

  /// Whether detected gestures should provide feedback.
  final bool? enableFeedback;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: items
          .map(
            (item) => BottomNavigationBarItem(
              icon: item.icon,
              activeIcon: item.activeIcon,
              label: item.label,
              tooltip: item.tooltip,
              backgroundColor: item.backgroundColor,
            ),
          )
          .toList(growable: false),
      currentIndex: currentIndex,
      onTap: onTap,
      type: type,
      elevation: elevation,
      iconSize: iconSize,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      selectedLabelStyle: selectedLabelStyle,
      unselectedLabelStyle: unselectedLabelStyle,
      showSelectedLabels: showSelectedLabels,
      showUnselectedLabels: showUnselectedLabels,
      backgroundColor: backgroundColor,
      enableFeedback: enableFeedback,
    );
  }
}
