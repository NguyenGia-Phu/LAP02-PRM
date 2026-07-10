import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/shared_research_selection_viewmodel.dart';
import 'home/home_screen.dart';
import 'journals/journals_screen.dart';
import 'keywords/keywords_screen.dart';
import 'profile/profile_tab_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selection = context.watch<SharedResearchSelectionViewModel>();
    final screens = [
      const HomeScreen(),
      JournalsScreen(
        selectedLabel: selection.label,
        selectedDomainId: selection.domainId,
        selectedFieldId: selection.fieldId,
        selectionKey: selection.key,
        autoLoadSelection: _currentIndex == 1,
      ),
      KeywordsScreen(
        selectedLabel: selection.label,
        selectedDomainId: selection.domainId,
        selectedFieldId: selection.fieldId,
        selectionKey: selection.key,
        autoLoadSelection: _currentIndex == 2,
      ),
      const ProfileTabScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Journals',
          ),
          NavigationDestination(
            icon: Icon(Icons.label_important_outline_rounded),
            selectedIcon: Icon(Icons.label_important_rounded),
            label: 'Keywords',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        elevation: 8,
        shadowColor: Colors.black,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
      ),
    );
  }
}
