import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../l10n/app_localizations.dart';
import '../utils/adaptive_navigation.dart';

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  List<NavigationItem> _getNavigationItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      NavigationItem(
        path: '/timer',
        icon: Icons.timer_outlined,
        selectedIcon: Icons.timer,
        label: l10n.timer,
      ),
      NavigationItem(
        path: '/tasks',
        icon: Icons.task_outlined,
        selectedIcon: Icons.task,
        label: l10n.tasks,
      ),
      NavigationItem(
        path: '/stats',
        icon: Symbols.bid_landscape,
        selectedIcon: Symbols.bid_landscape,
        label: l10n.statistics,
        isSymbolIcon: true, // Material Symbols need fill property
      ),
      NavigationItem(
        path: '/settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.settings,
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      final navigationItems = _getNavigationItems(context);
      context.go(navigationItems[index].path);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final String location = GoRouterState.of(context).uri.path;
    final navigationItems = _getNavigationItems(context);
    for (int i = 0; i < navigationItems.length; i++) {
      if (location.startsWith(navigationItems[i].path)) {
        setState(() {
          _selectedIndex = i;
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = _getNavigationItems(context);
    final layout = layoutForWidth(MediaQuery.sizeOf(context).width);

    if (layout == NavigationLayout.compact) {
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(fontSize: 13);
              }
              return const TextStyle(fontSize: 13);
            }),
            iconTheme: WidgetStateProperty.all(const IconThemeData(size: 26)),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: navigationItems
                .map((item) => item.toDestination())
                .toList(),
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: layout == NavigationLayout.medium
                ? NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                    labelType: NavigationRailLabelType.selected,
                    destinations: navigationItems
                        .map((item) => item.toRailDestination())
                        .toList(),
                  )
                : NavigationDrawer(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                    children: [
                      const SizedBox(height: 12),
                      ...navigationItems.map(
                        (item) => item.toDrawerDestination(),
                      ),
                    ],
                  ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

/// Navigation item model - encapsulates navigation destination logic (OOP)
class NavigationItem {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSymbolIcon; // For material_symbols_icons that need fill property

  const NavigationItem({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.isSymbolIcon = false,
  });

  /// Converts this item to a NavigationDestination widget (DRY)
  NavigationDestination toDestination() {
    return NavigationDestination(
      icon: isSymbolIcon ? Icon(icon, fill: 0) : Icon(icon),
      selectedIcon: isSymbolIcon
          ? Icon(selectedIcon, fill: 1)
          : Icon(selectedIcon),
      label: label,
    );
  }

  NavigationRailDestination toRailDestination() {
    return NavigationRailDestination(
      icon: isSymbolIcon ? Icon(icon, fill: 0) : Icon(icon),
      selectedIcon: isSymbolIcon
          ? Icon(selectedIcon, fill: 1)
          : Icon(selectedIcon),
      label: Text(label),
    );
  }

  NavigationDrawerDestination toDrawerDestination() {
    return NavigationDrawerDestination(
      icon: isSymbolIcon ? Icon(icon, fill: 0) : Icon(icon),
      selectedIcon: isSymbolIcon
          ? Icon(selectedIcon, fill: 1)
          : Icon(selectedIcon),
      label: Text(label),
    );
  }
}
