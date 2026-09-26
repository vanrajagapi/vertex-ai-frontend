import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/login_screen.dart';
import '../admin_controller.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.lightGrey)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12, bottom: 8),
                  child: Text('Menu', style: AppTextStyles.labelSmall),
                ),
                Obx(
                  () => _buildNavItem(
                    Icons.dashboard_rounded,
                    'Dashboard',
                    isActive: controller.selectedIndex.value == 0,
                    onTap: () => controller.changeTabIndex(0),
                  ),
                ),
                Obx(
                  () => _buildNavItem(
                    Icons.people_alt_rounded,
                    'Users',
                    isActive: controller.selectedIndex.value == 1,
                    onTap: () => controller.changeTabIndex(1),
                  ),
                ),
                Obx(
                  () => _buildNavItem(
                    Icons.inventory_2_rounded,
                    'Package',
                    isActive: controller.selectedIndex.value == 2,
                    onTap: () => controller.changeTabIndex(2),
                  ),
                ),
                Obx(
                  () => _buildNavItem(
                    Icons.text_fields_rounded,
                    'Text Field Groups',
                    isActive: controller.selectedIndex.value == 3,
                    onTap: () => controller.changeTabIndex(3),
                  ),
                ),
                Obx(
                  () => _buildNavItem(
                    Icons.psychology_alt_rounded,
                    'Agent Prompts',
                    isActive: controller.selectedIndex.value == 4,
                    onTap: () => controller.changeTabIndex(4),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'Claim System',
                  style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String title, {
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    final color = isActive ? AppColors.primary : AppColors.darkGrey;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ListTile(
            leading: Icon(icon, color: color, size: 20),
            title: Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: onTap,
          ),
          if (isActive)
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(
              Icons.dark_mode_outlined,
              color: AppColors.darkGrey,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () {
              Get.offAll(() => const LoginScreen());
            },
          ),
        ],
      ),
    );
  }
}
