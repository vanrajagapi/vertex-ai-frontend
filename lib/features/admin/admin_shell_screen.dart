import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_controller.dart';
import 'admin_repository.dart';
import 'screens/admin_home_view.dart';
import 'screens/user_list_view.dart';
import 'screens/package_list_view.dart';
import 'screens/text_field_groups_list_view.dart';
import 'widgets/admin_sidebar.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import 'screens/agent_prompts_list_view.dart';

class AdminShellScreen extends StatelessWidget {
  const AdminShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminController(repository: AdminRepository()));
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1100;

    final List<Widget> views = [
      const AdminHomeView(),
      const UserListView(),
      const PackageListView(),
      const TextFieldGroupsListView(),
      const AgentPromptsListView(),
    ];

    final List<String> titles = [
      'Dashboard',
      'Users',
      'Packages',
      'Text Field Groups',
      'Agent Prompts',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Obx(
                () => Text(
                  titles[controller.selectedIndex.value],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    if (controller.selectedIndex.value == 1)
                      controller.fetchUsers();
                    if (controller.selectedIndex.value == 2)
                      controller.fetchPackages();
                    if (controller.selectedIndex.value == 3) {
                      controller.fetchTextFieldGroups();
                      controller.fetchTextFields();
                    }
                    if (controller.selectedIndex.value == 4) {
                      controller.fetchAgentPrompts();
                    }
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    Get.offAll(() => const LoginScreen());
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                ),
              ],
            ),
      drawer: isDesktop ? null : const Drawer(child: AdminSidebar()),
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildDesktopHeader(controller, titles),
                Expanded(
                  child: Obx(() => views[controller.selectedIndex.value]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(AdminController controller, List<String> titles) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Obx(
            () => Text(
              titles[controller.selectedIndex.value],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              if (controller.selectedIndex.value == 1) controller.fetchUsers();
              if (controller.selectedIndex.value == 2)
                controller.fetchPackages();
              if (controller.selectedIndex.value == 3) {
                controller.fetchTextFieldGroups();
                controller.fetchTextFields();
              }
              if (controller.selectedIndex.value == 4) {
                controller.fetchAgentPrompts();
              }
            },
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          _buildAdminProfile(),
        ],
      ),
    );
  }

  Widget _buildAdminProfile() {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Admin User',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              'System Administrator',
              style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
      ],
    );
  }
}
