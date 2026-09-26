import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/sidebar_menu.dart';
import 'widgets/main_content_area.dart';
import 'widgets/right_panel.dart';
import '../patients/patient_list_screen.dart';
import 'preauth_list_screen.dart';
import 'claim_list_screen.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 800 && screenWidth <= 1200;

    Widget buildBody() {
      return Obx(() {
        switch (controller.selectedIndex.value) {
          case 0:
            return const MainContentArea();
          case 1:
            return const PatientListScreen();
          case 2:
            return const PreauthListScreen();
          case 3:
            return const ClaimListScreen();
          default:
            return const MainContentArea();
        }
      });
    }

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            const SidebarMenu(),
            Expanded(child: buildBody()),
            Obx(() => controller.selectedIndex.value == 0 ? const RightPanel() : const SizedBox.shrink()),
          ],
        ),
      );
    } else if (isTablet) {
      return Scaffold(
        backgroundColor: AppColors.background,
        drawer: const Drawer(child: SidebarMenu()),
        body: Row(
          children: [
            Expanded(child: buildBody()),
            Obx(() => controller.selectedIndex.value == 0 ? const RightPanel() : const SizedBox.shrink()),
          ],
        ),
      );
    } else {
      // Mobile view
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primaryDark,
          elevation: 1,
          title: Obx(() {
            switch (controller.selectedIndex.value) {
              case 0:
                return const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold));
              case 1:
                return const Text('Patients', style: TextStyle(fontWeight: FontWeight.bold));
              case 2:
                return const Text('Pre-Authorizations', style: TextStyle(fontWeight: FontWeight.bold));
              case 3:
                return const Text('Claims', style: TextStyle(fontWeight: FontWeight.bold));
              default:
                return const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold));
            }
          }),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
        drawer: const Drawer(child: SidebarMenu()),
        endDrawer: const Drawer(child: RightPanel()),
        body: buildBody(),
      );
    }
  }
}
