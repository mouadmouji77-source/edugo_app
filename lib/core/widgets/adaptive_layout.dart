import 'package:flutter/material.dart';

/// Widget gérant la mise en page adaptative (Web vs Mobile)
/// Utilise un NavigationRail sur les écrans larges et une NavigationBar sur mobile.
class AdaptiveLayout extends StatelessWidget {
  final Widget body; // Contenu principal de la page
  final Widget? drawer; // Menu latéral (optionnel)
  final int selectedIndex; // Index de l'onglet sélectionné
  final List<NavigationDestination> destinations; // Liste des destinations de navigation
  final void Function(int) onDestinationSelected; // Callback lors du changement d'onglet
  final Widget? floatingActionButton; // Bouton d'action flottant (optionnel)

  const AdaptiveLayout({
    super.key,
    required this.body,
    this.drawer,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    if (isWideScreen) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: true,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations
                  .map((dest) => NavigationRailDestination(
                        icon: dest.icon,
                        selectedIcon: dest.selectedIcon,
                        label: Text(dest.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      body: body,
      drawer: drawer,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
