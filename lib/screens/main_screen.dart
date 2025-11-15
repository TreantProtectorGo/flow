import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../l10n/app_localizations.dart';

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
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        height: 65,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: navigationItems.map((item) {
          if (item.icon == Symbols.bid_landscape) {
            return NavigationDestination(
              icon: Icon(Symbols.bid_landscape, fill: 0),
              selectedIcon: Icon(Symbols.bid_landscape, fill: 1),
              label: item.label,
            );
          } else {
            return NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            );
          }
        }).toList(),
      ),
    );
  }
}

class NavigationItem {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavigationItem({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
