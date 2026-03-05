/// A customizable and responsive navigation bar for Flutter applications.
library easy_bottom_nav;

/// Exporting the main EasyBottomNav class for external use.
class EasyBottomNav {

  /// [items] - A list of strings representing the navigation items.
  /// [currentIndex] - The index of the currently selected item.
  /// [onTap] - A callback function that is triggered when an item is tapped.
  final List<String> items;
  final int currentIndex;
  final Function(int) onTap;

  /// Creates a new instance of the EasyBottomNav class.
  EasyBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  /// Handles tap events on the navigation items and triggers the provided callback.
  ///
  /// [index] - The index of the tapped item.
  /// This method calls the `onTap` callback with the index of the tapped item, allowing the parent widget to update the state accordingly.
  void handleTap(int index) {
    onTap(index);
  }

}