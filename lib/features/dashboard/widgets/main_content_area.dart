import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class MainContentArea extends StatelessWidget {
  const MainContentArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildSummaryCards(),
            const SizedBox(height: 32),
            _buildChartSection(),
            const SizedBox(height: 32),
            _buildClaimsTableSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics', style: AppTextStyles.heading1),
            SizedBox(height: 4),
            Text('Welcome back, Let\'s get back to work.', style: AppTextStyles.bodyMedium),
          ],
        ),
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const TextField(
            decoration: InputDecoration(
              icon: Icon(Icons.search, color: AppColors.darkGrey),
              hintText: 'Search Dashboard',
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            title: 'Total Claims',
            count: '2,140',
            icon: Icons.folder_shared_rounded,
            color: AppColors.primary,
            progress: 0.6,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildCard(
            title: 'PASS Rate',
            count: '85%',
            icon: Icons.verified_user_rounded,
            color: AppColors.success,
            progress: 0.85,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildCard(
            title: 'Pending Items',
            count: '140',
            icon: Icons.pending_actions_rounded,
            color: AppColors.secondary,
            progress: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelSmall),
                  Text(count, style: AppTextStyles.heading2),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.lightGrey,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChartStat('Total Claims', '500k'),
              _buildChartStat('Period', '1 Month'),
              _buildChartStat('Upcoming Actions', '245'),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 20,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                value.toInt().toString().padLeft(2, '0'),
                                style: const TextStyle(color: AppColors.darkGrey, fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(12, (i) {
                      final values = [12, 6, 14, 8, 16, 5, 12, 4, 15, 6, 16, 8];
                      return BarChartGroupData(
                        x: i + 1,
                        barRods: [
                          BarChartRodData(
                            toY: values[i].toDouble(),
                            color: AppColors.secondary,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      );
                    }),
                  ),
                ),
                LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: 20,
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 16),
                          FlSpot(1, 10),
                          FlSpot(2, 12),
                          FlSpot(3, 10),
                          FlSpot(4, 15),
                          FlSpot(5, 11),
                          FlSpot(6, 14),
                          FlSpot(7, 10),
                          FlSpot(8, 16),
                          FlSpot(9, 13),
                          FlSpot(10, 15),
                          FlSpot(11, 18),
                        ],
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartStat(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.heading3),
        ],
      ),
    );
  }

  Widget _buildClaimsTableSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Table', style: AppTextStyles.heading2),
              Text('View All', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryAccent)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              headingTextStyle: AppTextStyles.label.copyWith(color: AppColors.dark),
              dataTextStyle: AppTextStyles.bodyMedium,
              horizontalMargin: 0,
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('Claim ID')),
                DataColumn(label: Text('Patient Name')),
                DataColumn(label: Text('Package')),
                DataColumn(label: Text('Score')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: [
                _buildTableRow('CLM-001', 'John Doe', 'Cardiac Surgery', '85%', 'Approved'),
                _buildTableRow('CLM-002', 'Jane Smith', 'Maternity', '92%', 'Pending'),
                _buildTableRow('CLM-003', 'Michael Clark', 'Orthopedic', '45%', 'Rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildTableRow(String id, String name, String pkg, String score, String status) {
    Color statusColor;
    if (status == 'Approved') {
      statusColor = AppColors.success;
    } else if (status == 'Pending') {
      statusColor = AppColors.secondary;
    } else {
      statusColor = AppColors.error;
    }

    return DataRow(
      cells: [
        DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(name)),
        DataCell(Text(pkg)),
        DataCell(Text(score)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          PopupMenuButton<String>(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkGrey),
            tooltip: 'Actions',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (value) {
              // Handle action
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('View'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'upload',
                child: Row(
                  children: [
                    Icon(Icons.upload_file_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Upload Docs'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
