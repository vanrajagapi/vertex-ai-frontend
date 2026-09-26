import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/login_screen.dart';
import '../dashboard_controller.dart';

class SidebarMenu extends StatelessWidget {
  const SidebarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.lightGrey)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                const Text('Menu', style: AppTextStyles.labelSmall),
                const SizedBox(height: 8),

                Obx(
                  () => _buildNavItem(
                    Icons.dashboard_rounded,
                    'Dashboard',
                    isActive: controller.selectedIndex.value == 0,
                    onTap: () => controller.changeIndex(0),
                  ),
                ),
                Obx(
                  () => _buildNavItem(
                    Icons.people_alt_rounded,
                    'Patients',
                    isActive: controller.selectedIndex.value == 1,
                    onTap: () => controller.changeIndex(1),
                  ),
                ),
                Obx(
                  () => _buildNavItem(
                    Icons.assignment_turned_in_rounded,
                    'Pre-Authorizations',
                    isActive: controller.selectedIndex.value == 2,
                    onTap: () => controller.changeIndex(2),
                  ),
                ),
                Obx(
                  () => _buildNavItem(
                    Icons.receipt_long_rounded,
                    'Claims',
                    isActive: controller.selectedIndex.value == 3,
                    onTap: () => controller.changeIndex(3),
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
              Icons.verified_user_rounded,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Panel', style: AppTextStyles.label),
                Text('Claim System', style: AppTextStyles.caption),
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
    String? badgeCount,
    required VoidCallback onTap,
  }) {
    final color = isActive ? AppColors.primary : AppColors.darkGrey;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: badgeCount != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeCount,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onTap,
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
