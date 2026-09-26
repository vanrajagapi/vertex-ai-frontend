import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'patient_controller.dart';
import 'patient_model.dart';
import 'patient_repository.dart';
import '../claims/new_claim_screen.dart';
import '../claims/select_package_screen.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      PatientController(repository: PatientRepository()),
    );

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _buildHeader(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.patients.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.patients.isEmpty) {
                return _buildEmptyState(controller);
              }
              return _buildPatientTable(context, controller);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PatientController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patients', style: AppTextStyles.heading1),
                  SizedBox(height: 4),
                  Text(
                    'Manage and view all registered patients.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => Get.to(() => const NewClaimScreen()),
                icon: const Icon(Icons.add),
                label: const Text('New Patient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: (val) => controller.searchQuery.value = val,
                    decoration: InputDecoration(
                      hintText: 'Search patients by name or PMJAY number...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.darkGrey,
                      ),
                      suffixIcon: Obx(
                        () => controller.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppColors.darkGrey,
                                ),
                                onPressed: () => controller.clearSearch(),
                              )
                            : const SizedBox.shrink(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: () => controller.fetchPatients(
                  search: controller.searchQuery.value,
                ),
                tooltip: 'Refresh list',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: AppColors.lightGrey.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(PatientController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.darkGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.isNotEmpty
                ? 'No patients found matching "${controller.searchQuery.value}"'
                : 'No patients registered yet',
            style: AppTextStyles.heading3.copyWith(color: AppColors.darkGrey),
          ),
          const SizedBox(height: 8),
          Text(
            controller.searchQuery.isNotEmpty
                ? 'Try searching for another name or PMJAY ID'
                : 'Get started by clicking the "New Patient" button',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkGrey),
          ),
          if (controller.searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => controller.clearSearch(),
              child: const Text(
                'Clear Search',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientTable(
    BuildContext context,
    PatientController controller,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32.0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataTable(
              headingTextStyle: AppTextStyles.label.copyWith(
                color: AppColors.dark,
              ),
              dataTextStyle: AppTextStyles.bodyMedium,
              horizontalMargin: 0,
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('PMJAY ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('DOB')),
                DataColumn(label: Text('Age')),
                DataColumn(label: Text('Gender')),
                DataColumn(label: Text('Contact')),
                DataColumn(label: Text('Actions')),
              ],
              rows: controller.patients.map((patient) {
                return DataRow(
                  cells: [
                    DataCell(Text(patient.id)),
                    DataCell(
                      InkWell(
                        onTap: () {
                          controller.showPatientDetails(patient);
                        },
                        child: Text(
                          patient.pmjayNumber,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        patient.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text(patient.dob)),
                    DataCell(Text(patient.age)),
                    DataCell(Text(patient.gender)),
                    DataCell(
                      Text(patient.contact.isEmpty ? '-' : patient.contact),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill,
                              size: 20,
                              color: AppColors.success,
                            ),
                            tooltip: 'Start Preauth',
                            onPressed: () => Get.to(() => SelectPackageScreen(patient: patient)),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.error,
                            ),
                            tooltip: 'Delete Patient',
                            onPressed: () => _showDeleteConfirmation(
                              context,
                              controller,
                              patient,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    PatientController controller,
    Patient patient,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Confirm Delete'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete patient "${patient.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.darkGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deletePatient(patient.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
