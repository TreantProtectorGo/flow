enum NavigationLayout { compact, medium, expanded }

NavigationLayout layoutForWidth(double width) {
  if (width < 600) {
    return NavigationLayout.compact;
  }
  if (width < 840) {
    return NavigationLayout.medium;
  }
  return NavigationLayout.expanded;
}
