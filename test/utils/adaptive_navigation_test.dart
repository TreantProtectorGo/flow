import 'package:flutter_test/flutter_test.dart';
import 'package:focus/utils/adaptive_navigation.dart';

void main() {
  test('uses bottom navigation for compact width', () {
    expect(layoutForWidth(599), NavigationLayout.compact);
  });

  test('uses navigation rail for medium width', () {
    expect(layoutForWidth(600), NavigationLayout.medium);
    expect(layoutForWidth(839), NavigationLayout.medium);
  });

  test('uses navigation drawer for expanded width', () {
    expect(layoutForWidth(840), NavigationLayout.expanded);
  });
}
