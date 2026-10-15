import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import '../screens/patients/patients_screen.dart';
import '../screens/profile/doctor_profile_screen.dart';
import '../widgets/bottom_nav.dart';
import 'app_navigator.dart';

/// Holds the three primary tabs. Tabs keep their scroll state (IndexedStack).
/// "Assess Patient" is deliberately NOT a tab – it is the hero CTA on Home.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ShellTab>(
      valueListenable: AppNavigator.currentTab,
      builder: (context, tab, _) {
        return PopScope(
          // Android back on Patients/Profile returns to Home first.
          canPop: tab == ShellTab.home,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) AppNavigator.currentTab.value = ShellTab.home;
          },
          child: Scaffold(
            // Tabs switch in place (no page transition); the incoming tab
            // only fades in briefly so the change doesn't feel abrupt.
            body: IndexedStack(
              index: tab.index,
              children: [
                for (final (t, page) in const [
                  (ShellTab.home, HomeScreen()),
                  (ShellTab.patients, PatientsScreen()),
                  (ShellTab.profile, DoctorProfileScreen()),
                ])
                  AnimatedOpacity(
                    opacity: t == tab ? 1 : 0,
                    duration: AppMotion.tab,
                    curve: Curves.easeOut,
                    child: page,
                  ),
              ],
            ),
            bottomNavigationBar: AiovyBottomNav(
              current: tab,
              onSelect: (t) => AppNavigator.currentTab.value = t,
            ),
          ),
        );
      },
    );
  }
}
