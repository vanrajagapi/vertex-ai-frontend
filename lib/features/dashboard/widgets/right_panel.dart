import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RightPanel extends StatelessWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.lightGrey)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 32),
            _buildQuickLinks(),
            const SizedBox(height: 32),
            _buildStatusChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
            IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
            image: const DecorationImage(
              image: NetworkImage('https://i.pravatar.cc/150?img=11'), // Dummy image
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Admin User', style: AppTextStyles.heading3),
        const Text('System Administrator', style: AppTextStyles.bodySmall),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('457', 'Claims'),
            _buildStatItem('450', 'Verified'),
            _buildStatItem('12', 'Pending'),
          ],
        )
      ],
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildQuickLinks() {
    return Column(
      children: [
        _buildLinkItem(Icons.track_changes_outlined, 'Goals'),
        _buildLinkItem(Icons.calendar_month_outlined, 'Monthly Plan', iconColor: AppColors.error),
        _buildLinkItem(Icons.settings_outlined, 'Settings', iconColor: AppColors.secondary),
      ],
    );
  }

  Widget _buildLinkItem(IconData icon, String title, {Color iconColor = AppColors.darkGrey}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: AppTextStyles.label)),
          const Icon(Icons.chevron_right, color: AppColors.darkGrey),
        ],
      ),
    );
  }

  Widget _buildStatusChart() {
    return Column(
      children: [
        const Text('Claim Status Ratio', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Text('121 / 143', style: AppTextStyles.heading2.copyWith(fontSize: 24)),
        const Text('claims verified', style: AppTextStyles.caption),
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 60,
              sections: [
                PieChartSectionData(
                  color: AppColors.success,
                  value: 65,
                  title: '',
                  radius: 20,
                ),
                PieChartSectionData(
                  color: AppColors.secondary,
                  value: 20,
                  title: '',
                  radius: 20,
                ),
                PieChartSectionData(
                  color: AppColors.error,
                  value: 15,
                  title: '',
                  radius: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
