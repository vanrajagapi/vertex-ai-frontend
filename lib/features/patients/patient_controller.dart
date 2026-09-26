import 'package:claim_automate_checker/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'patient_model.dart';
import 'patient_repository.dart';
import '../claims/ai_analysis_result_screen.dart';
import '../admin/package_model.dart';
import '../claims/document_upload_screen.dart';

class PatientController extends GetxController {
  final IPatientRepository repository;

  PatientController({required this.repository});

  final RxList<Patient> patients = <Patient>[].obs;
  final RxBool isLoading = false.obs;

  // Search text controller
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPatients();

    // Setup debounce for search query
    debounce(searchQuery, (query) {
      fetchPatients(search: query);
    }, time: const Duration(milliseconds: 500));
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchPatients({String? search}) async {
    isLoading.value = true;
    try {
      final data = await repository.getPatients(search: search);
      patients.assignAll(data);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch patients from server',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addPatient(Patient patient) async {
    isLoading.value = true;
    try {
      final newPatient = await repository.addPatient(patient);
      if (newPatient != null) {
        patients.add(newPatient);
      }
      Get.back(); // Close dialog/screen
      Get.snackbar(
        'Success',
        'Patient added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add patient to server: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePatient(String id) async {
    try {
      await repository.deletePatient(id);
      patients.removeWhere((p) => p.id == id);
      Get.snackbar(
        'Deleted',
        'Patient record removed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete patient',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> getPatientById(String id) async {
    isLoading.value = true;
    try {
      final patient = await repository.getPatientById(id);
      if (patient != null) {
        List<dynamic> claims = [];
        List<dynamic> preauths = [];
        final patientIdInt = int.tryParse(patient.id);
        if (patientIdInt != null) {
          try {
            final fetchedClaims = await repository.getPatientClaims(patientIdInt);
            if (fetchedClaims != null) {
              claims = fetchedClaims;
            }
          } catch (e) {
            debugPrint("Failed to fetch claims for patient: $e");
          }
          try {
            final fetchedPreauths = await repository.getPatientPreauths(patientIdInt);
            if (fetchedPreauths != null) {
              preauths = fetchedPreauths;
            }
          } catch (e) {
            debugPrint("Failed to fetch preauths for patient: $e");
          }
        }
        _showPatientDetailsDialog(patient, claims: claims, preauths: preauths);
      } else {
        Get.snackbar(
          'Error',
          'Patient not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.1),
          colorText: AppColors.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch patient details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getPatientByPMJY(String pmjayNumber) async {
    isLoading.value = true;
    try {
      final patient = await repository.getPatientByPMJY(pmjayNumber);
      if (patient != null) {
        List<dynamic> claims = [];
        List<dynamic> preauths = [];
        final patientIdInt = int.tryParse(patient.id);
        if (patientIdInt != null) {
          try {
            final fetchedClaims = await repository.getPatientClaims(patientIdInt);
            if (fetchedClaims != null) {
              claims = fetchedClaims;
            }
          } catch (e) {
            debugPrint("Failed to fetch claims for patient: $e");
          }
          try {
            final fetchedPreauths = await repository.getPatientPreauths(patientIdInt);
            if (fetchedPreauths != null) {
              preauths = fetchedPreauths;
            }
          } catch (e) {
            debugPrint("Failed to fetch preauths for patient: $e");
          }
        }
        _showPatientDetailsDialog(patient, claims: claims, preauths: preauths);
      } else {
        Get.snackbar(
          'Error',
          'Patient not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.1),
          colorText: AppColors.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch patient details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> showPatientDetails(Patient patient) async {
    isLoading.value = true;
    List<dynamic> claims = [];
    List<dynamic> preauths = [];
    final patientIdInt = int.tryParse(patient.id);
    if (patientIdInt != null) {
      try {
        final fetchedClaims = await repository.getPatientClaims(patientIdInt);
        if (fetchedClaims != null) {
          claims = fetchedClaims;
        }
      } catch (e) {
        debugPrint("Failed to fetch claims for patient: $e");
      }
      try {
        final fetchedPreauths = await repository.getPatientPreauths(patientIdInt);
        if (fetchedPreauths != null) {
          preauths = fetchedPreauths;
        }
      } catch (e) {
        debugPrint("Failed to fetch preauths for patient: $e");
      }
    }
    isLoading.value = false;
    _showPatientDetailsDialog(patient, claims: claims, preauths: preauths);
  }

  void _showPatientDetailsDialog(
    Patient patient, {
    List<dynamic> claims = const [],
    List<dynamic> preauths = const [],
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.badge_outlined, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Patient Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.darkGrey),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 1),
                _buildCompactInfoSection(patient),
                const Divider(height: 20, thickness: 1),
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Pre-Authorization History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (preauths.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No pre-authorizations found for this patient.',
                      style: TextStyle(
                        color: AppColors.darkGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: preauths.length,
                      itemBuilder: (context, index) {
                        final preauth = preauths[index];
                        final preauthId = preauth['preauth_id'] ?? preauth['id'];
                        final preauthRef = preauth['claim_ref'] ?? 'Ref: $preauthId';
                        final packageCode = preauth['package_code'] ?? 'Unknown Pkg';
                        final verdict = preauth['verdict'] ?? 'UNKNOWN';
                        final score = preauth['total_score'] != null ? '${(preauth['total_score'] as num).round()}%' : '-';
                        
                        Color verdictColor;
                        if (verdict == 'PASS') {
                          verdictColor = AppColors.success;
                        } else if (verdict == 'FAIL') {
                          verdictColor = AppColors.error;
                        } else {
                          verdictColor = AppColors.warning;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          child: ListTile(
                            dense: true,
                            title: Text(
                              '$packageCode ($preauthRef)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PRE-AUTH',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Verdict: '),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: verdictColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    verdict,
                                    style: TextStyle(
                                      color: verdictColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('Score: $score'),
                              ],
                            ),
                            trailing: preauthId != null
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                                        onPressed: () {
                                          Get.back();
                                          final idInt = preauthId is int ? preauthId : int.tryParse(preauthId.toString());
                                          if (idInt != null) {
                                            Get.to(() => AiAnalysisResultScreen(preauthId: idInt));
                                          }
                                        },
                                        tooltip: 'View AI Preauth Analysis',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.play_arrow_outlined, color: AppColors.success, size: 20),
                                        onPressed: () {
                                          Get.back();
                                          final idInt = preauthId is int ? preauthId : int.tryParse(preauthId.toString());
                                          if (idInt != null) {
                                            _startClaimFromPreauth(patient, packageCode, idInt);
                                          }
                                        },
                                        tooltip: 'Start Claim for this Preauth',
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(height: 20, thickness: 1),
                Row(
                  children: [
                    const Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Claims History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (claims.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No claims found for this patient.',
                      style: TextStyle(
                        color: AppColors.darkGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: claims.length,
                      itemBuilder: (context, index) {
                        final claim = claims[index];
                        final claimId = claim['claim_id'] ?? claim['id'];
                        final claimRef = claim['claim_ref'] ?? 'Ref: $claimId';
                        final packageCode = claim['package_code'] ?? 'Unknown Pkg';
                        final verdict = claim['verdict'] ?? 'UNKNOWN';
                        final score = claim['total_score'] != null ? '${(claim['total_score'] as num).round()}%' : '-';
                        
                        Color verdictColor;
                        if (verdict == 'PASS') {
                          verdictColor = AppColors.success;
                        } else if (verdict == 'FAIL') {
                          verdictColor = AppColors.error;
                        } else {
                          verdictColor = AppColors.warning;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          child: ListTile(
                            dense: true,
                            title: Text(
                              '$packageCode ($claimRef)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'CLAIM',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Verdict: '),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: verdictColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    verdict,
                                    style: TextStyle(
                                      color: verdictColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('Score: $score'),
                              ],
                            ),
                            trailing: claimId != null
                                ? IconButton(
                                    icon: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                                    onPressed: () {
                                      Get.back();
                                      final idInt = claimId is int ? claimId : int.tryParse(claimId.toString());
                                      if (idInt != null) {
                                        Get.to(() => AiAnalysisResultScreen(claimId: idInt));
                                      }
                                    },
                                    tooltip: 'View AI Claim Analysis',
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoSection(Patient patient) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCompactDetailRow('Patient ID', patient.id)),
            Expanded(child: _buildCompactDetailRow('PMJAY ID', patient.pmjayNumber)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _buildCompactDetailRow('Full Name', patient.name)),
            Expanded(child: _buildCompactDetailRow('Date of Birth', patient.dob)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _buildCompactDetailRow('Age', '${patient.age} years')),
            Expanded(child: _buildCompactDetailRow('Gender', patient.gender)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _buildCompactDetailRow('Contact', patient.contact.isEmpty ? '-' : patient.contact)),
            Expanded(
              child: patient.createdAt.isNotEmpty
                  ? _buildCompactDetailRow('Registered On', patient.createdAt.substring(0, 10))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.darkGrey,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  Future<void> startClaimFromPreauth(Patient patient, String packageCode, int preauthId) =>
      _startClaimFromPreauth(patient, packageCode, preauthId);

  Future<void> _startClaimFromPreauth(Patient patient, String packageCode, int preauthId) async {
    isLoading.value = true;
    try {
      final schemaData = await repository.getFormSchema(packageCode, int.parse(patient.id), stage: 'claim');

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

      final pkgs = await repository.getPackages();
      PackageModel? package;
      for (var p in pkgs) {
        if (p.code == packageCode) {
          package = p;
          break;
        }
      }
      package ??= PackageModel(
        code: packageCode,
        name: 'Package $packageCode',
        specialty: '',
      );

      isLoading.value = false;

      Get.to(
        () => DocumentUploadScreen(
          patient: patient,
          package: package!,
          documentGroups: docGroups,
          stage: 'claim',
          preauthId: preauthId,
        ),
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Could not fetch claim form schema: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
    }
  }
}
