class Navbar {
  final List<String> items;
  final int currentIndex;
  final Function(int) onTap;

  Navbar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  void handleTap(int index) {
    onTap(index);
  }

}