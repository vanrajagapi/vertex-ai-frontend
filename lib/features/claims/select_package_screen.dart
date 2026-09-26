import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../patients/patient_model.dart';
import '../patients/patient_repository.dart';
import '../admin/package_model.dart';
import 'document_upload_screen.dart';

class SelectPackageScreen extends StatefulWidget {
  final Patient patient;
  const SelectPackageScreen({super.key, required this.patient});

  @override
  State<SelectPackageScreen> createState() => _SelectPackageScreenState();
}

class _SelectPackageScreenState extends State<SelectPackageScreen> {
  final PatientRepository _patientRepository = PatientRepository();

  List<PackageModel> _packages = [];
  PackageModel? _selectedPackage;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final pkgs = await _patientRepository.getPackages();
      setState(() {
        // Only show active packages
        _packages = pkgs.where((p) => p.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load packages: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _proceedToDocumentUpload() async {
    if (_selectedPackage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final patientRepository = PatientRepository();
      final patientId = int.tryParse(widget.patient.id) ?? 0;
      final schemaData = await patientRepository.getFormSchema(
        _selectedPackage!.code,
        patientId,
        stage: 'preauth',
      );

      Map<String, List<PackageDocument>> docGroups = {};
      if (schemaData != null && schemaData['fields'] != null) {
        if (schemaData['fields'] is Map) {
          final Map<String, dynamic> fieldsMap = schemaData['fields'];
          fieldsMap.forEach((key, value) {
            if (value is List) {
              docGroups[key] = value
                  .map((f) => PackageDocument.fromJson(f as Map<String, dynamic>))
                  .toList();
            }
          });
        }
      }

      setState(() {
        _isLoading = false;
      });

      // Navigate to the Document Upload screen with patient, package, and dynamic document rules!
      Get.to(
        () => DocumentUploadScreen(
          patient: widget.patient,
          package: _selectedPackage!,
          documentGroups: docGroups,
          stage: 'preauth',
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Warning',
        'Could not fetch package form schema. Using default documents.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning.withOpacity(0.1),
        colorText: AppColors.dark,
      );

      Get.to(
        () => DocumentUploadScreen(
          patient: widget.patient,
          package: _selectedPackage!,
          documentGroups: const {},
          stage: 'preauth',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Step 3 — Select Package',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Patient Summary Card
                _buildPatientSummaryCard(),
                const SizedBox(height: 24),

                // 2. Package Selector Card
                _buildPackageSelectorCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSummaryCard() {
    return Container(
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
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const Divider(height: 32, thickness: 1),

          _buildInfoRow('Full Name', widget.patient.name, isBold: true),
          _buildInfoRow('PMJAY ID', widget.patient.pmjayNumber),
          _buildInfoRow(
            'Age / Gender',
            '${widget.patient.age} years / ${widget.patient.gender}',
          ),
          _buildInfoRow('Date of Birth', widget.patient.dob),
          _buildInfoRow(
            'Contact',
            widget.patient.contact.isEmpty ? '-' : widget.patient.contact,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.darkGrey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: AppColors.dark,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSelectorCard() {
    return Container(
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
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Select Preauth Package',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const Divider(height: 32, thickness: 1),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else ...[
            const Text(
              'Choose the medical treatment package or specialty rule applicable for this patient\'s insurance claim:',
              style: TextStyle(color: AppColors.darkGrey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Dropdown Selector
            DropdownButtonFormField<PackageModel>(
              value: _selectedPackage,
              decoration: InputDecoration(
                labelText: 'Select Package',
                prefixIcon: const Icon(Icons.medical_services_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background.withOpacity(0.3),
              ),
              items: _packages.map((pkg) {
                return DropdownMenuItem<PackageModel>(
                  value: pkg,
                  child: Text(
                    '${pkg.code} - ${pkg.name} (${pkg.specialty})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (pkg) {
                setState(() {
                  _selectedPackage = pkg;
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a package' : null,
            ),
            const SizedBox(height: 24),

            if (_selectedPackage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Package Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Code', _selectedPackage!.code),
                    _buildInfoRow('Name', _selectedPackage!.name),
                    _buildInfoRow('Specialty', _selectedPackage!.specialty),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _selectedPackage == null
                    ? null
                    : _proceedToDocumentUpload,
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: const Text(
                  'Start Preauth & Upload Documents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
