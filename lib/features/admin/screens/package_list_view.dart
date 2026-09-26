import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin_controller.dart';
import '../package_model.dart';
import '../../../core/theme/app_colors.dart';
import 'create_package_screen.dart';
import 'edit_package_screen.dart';
import 'update_package_weights_screen.dart';
import 'package_documents_screen.dart';

class PackageListView extends StatelessWidget {
  const PackageListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value && controller.packages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(controller.packages.length),
              const SizedBox(height: 20),
              Expanded(
                child: controller.packages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: controller.packages.length,
                        itemBuilder: (context, index) {
                          final package = controller.packages[index];
                          return _buildPackageCard(package);
                        },
                      ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreatePackageScreen()),
        label: const Text('Create Package'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Package Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                'Total Packages: $count',
                style: const TextStyle(color: AppColors.darkGrey),
              ),
            ],
          ),
          const Icon(
            Icons.inventory_2,
            size: 40,
            color: AppColors.primaryAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(PackageModel package) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.card_giftcard, color: AppColors.primary),
        ),
        title: Text(
          package.code,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGrey,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text('Specialty: ${package.specialty}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.description_outlined, color: AppColors.primaryAccent),
              onPressed: () => Get.to(() => PackageDocumentsScreen(package: package)),
              tooltip: 'Configure Documents',
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => Get.to(() => EditPackageScreen(package: package)),
              tooltip: 'Edit Package',
            ),
            IconButton(
              icon: const Icon(Icons.scale_outlined, color: AppColors.secondary),
              onPressed: () => Get.to(() => UpdatePackageWeightsScreen(package: package)),
              tooltip: 'Update Weights',
            ),
            Icon(
              package.isActive ? Icons.check_circle : Icons.error_outline,
              color: package.isActive ? AppColors.success : AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No packages found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.darkGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text('Click the "Create Package" button to add one.'),
        ],
      ),
    );
  }
}
