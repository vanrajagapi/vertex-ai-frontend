import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../patients/patient_model.dart';
import '../patients/patient_controller.dart';
import '../patients/patient_repository.dart';
import '../claims/ai_analysis_result_screen.dart';

class PreauthListScreen extends StatefulWidget {
  const PreauthListScreen({super.key});

  @override
  State<PreauthListScreen> createState() => _PreauthListScreenState();
}

class _PreauthListScreenState extends State<PreauthListScreen> {
  final _repository = PatientRepository();
  final _searchController = TextEditingController();

  List<dynamic> _allItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPreauths();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPreauths() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _repository.getPreauths();
      setState(() {
        _allItems = data ?? [];
        _filteredItems = _allItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to fetch pre-authorizations: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
    }
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredItems = _allItems.where((item) {
          final claimRef = (item['claim_ref'] ?? item['preauth_ref'] ?? '').toString().toLowerCase();
          final preauthId = (item['preauth_id'] ?? item['id'] ?? '').toString().toLowerCase();
          final packageCode = (item['package_code'] ?? '').toString().toLowerCase();
          final verdict = (item['verdict'] ?? '').toString().toLowerCase();
          final admissionDate = (item['admission_date'] ?? '').toString().toLowerCase();
          final dischargeDate = (item['discharge_date'] ?? '').toString().toLowerCase();
          
          final patientData = item['patient'];
          String patientName = '';
          String pmjayNumber = '';
          String patientId = '';
          if (patientData is Map) {
            patientName = (patientData['name'] ?? '').toString().toLowerCase();
            pmjayNumber = (patientData['pmjay_number'] ?? '').toString().toLowerCase();
            patientId = (patientData['patient_id'] ?? '').toString().toLowerCase();
          } else {
            patientId = (item['patient_id'] ?? '').toString().toLowerCase();
            patientName = (item['patient_name'] ?? 'patient #$patientId').toString().toLowerCase();
            pmjayNumber = (item['pmjay_number'] ?? '').toString().toLowerCase();
          }

          return claimRef.contains(lowercaseQuery) ||
              preauthId.contains(lowercaseQuery) ||
              packageCode.contains(lowercaseQuery) ||
              verdict.contains(lowercaseQuery) ||
              patientName.contains(lowercaseQuery) ||
              pmjayNumber.contains(lowercaseQuery) ||
              patientId.contains(lowercaseQuery) ||
              admissionDate.contains(lowercaseQuery) ||
              dischargeDate.contains(lowercaseQuery);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterItems('');
  }

  void _viewPatientDetails(String patientId, String pmjayNumber) {
    final patientController = Get.isRegistered<PatientController>()
        ? Get.find<PatientController>()
        : Get.put(PatientController(repository: PatientRepository()));
    if (patientId.isNotEmpty) {
      patientController.getPatientById(patientId);
    } else if (pmjayNumber.isNotEmpty) {
      patientController.getPatientByPMJY(pmjayNumber);
    }
  }

  Future<void> _startClaim(dynamic item) async {
    final preauthId = item['preauth_id'] ?? item['id'];
    final packageCode = item['package_code'] ?? '';
    final patientId = (item['patient_id'] ?? item['patient']?['id'] ?? '').toString();
    final pmjayNumber = (item['pmjay_number'] ?? item['patient']?['pmjay_number'] ?? '').toString();
    
    if (preauthId == null || packageCode.isEmpty) {
      Get.snackbar('Error', 'Invalid pre-authorization details');
      return;
    }

    Get.dialog(
      const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      barrierDismissible: false,
    );

    try {
      Patient? patient;
      if (patientId.isNotEmpty) {
        patient = await _repository.getPatientById(patientId);
      } else if (pmjayNumber.isNotEmpty) {
        patient = await _repository.getPatientByPMJY(pmjayNumber);
      }
      Get.back(); // close loading dialog

      if (patient != null) {
        final patientController = Get.isRegistered<PatientController>()
            ? Get.find<PatientController>()
            : Get.put(PatientController(repository: PatientRepository()));
        
        final idInt = preauthId is int ? preauthId : int.tryParse(preauthId.toString());
        if (idInt != null) {
          await patientController.startClaimFromPreauth(patient, packageCode, idInt);
        } else {
          Get.snackbar('Error', 'Invalid pre-authorization ID');
        }
      } else {
        Get.snackbar('Error', 'Failed to retrieve patient details');
      }
    } catch (e) {
      Get.back(); // close loading dialog
      Get.snackbar('Error', 'Failed to start claim: ${e.toString()}');
    }
  }

  Color _getVerdictColor(String verdict) {
    if (verdict == 'PASS') return AppColors.success;
    if (verdict == 'FAIL') return AppColors.error;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredItems.isEmpty
                      ? _buildEmptyState()
                      : isDesktop
                          ? _buildDesktopTable()
                          : _buildMobileList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  Text('Pre-Authorizations', style: AppTextStyles.heading1),
                  SizedBox(height: 4),
                  Text(
                    'View and manage all patient pre-authorization submissions.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: _fetchPreauths,
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
                    controller: _searchController,
                    onChanged: _filterItems,
                    decoration: InputDecoration(
                      hintText: 'Search by ID, Patient Name, Package, or Verdict...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.darkGrey,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.darkGrey,
                              ),
                              onPressed: _clearSearch,
                            )
                          : const SizedBox.shrink(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppColors.darkGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No pre-authorizations found matching "$_searchQuery"'
                : 'No pre-authorizations found',
            style: AppTextStyles.heading3.copyWith(color: AppColors.darkGrey),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try searching for something else'
                : 'Submissions will show up here once created',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkGrey),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _clearSearch,
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

  Widget _buildDesktopTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
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
                DataColumn(label: Text('Ref / ID')),
                DataColumn(label: Text('Patient')),
                DataColumn(label: Text('Dates')),
                DataColumn(label: Text('Package Code')),
                DataColumn(label: Text('Verdict')),
                DataColumn(label: Text('Confidence')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _filteredItems.map((item) {
                final preauthId = item['preauth_id'] ?? item['id'];
                final preauthRef = item['claim_ref'] ?? item['preauth_ref'] ?? 'Ref: $preauthId';
                final packageCode = item['package_code'] ?? '-';
                final verdict = item['verdict'] ?? 'UNKNOWN';
                final verdictColor = _getVerdictColor(verdict);
                final scoreNum = item['total_score'] as num?;
                final score = scoreNum != null ? '${scoreNum.round()}%' : '-';

                final patientData = item['patient'];
                String patientName = '';
                String pmjayNumber = '';
                String patientId = '';
                if (patientData is Map) {
                  patientName = patientData['name'] ?? '';
                  pmjayNumber = patientData['pmjay_number'] ?? '';
                  patientId = (patientData['patient_id'] ?? '').toString();
                } else {
                  patientId = (item['patient_id'] ?? '').toString();
                  patientName = item['patient_name'] ?? 'Patient #$patientId';
                  pmjayNumber = item['pmjay_number'] ?? '';
                }

                final admissionDate = item['admission_date'] ?? '-';
                final dischargeDate = item['discharge_date'] ?? '-';

                return DataRow(
                  cells: [
                    DataCell(Text(preauthRef, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(
                      InkWell(
                        onTap: () => _viewPatientDetails(patientId, pmjayNumber),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            if (pmjayNumber.isNotEmpty)
                              Text(
                                pmjayNumber,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkGrey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Adm: $admissionDate',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dis: $dischargeDate',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(packageCode)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: verdictColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: verdictColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          verdict,
                          style: TextStyle(
                            color: verdictColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (scoreNum != null)
                            Container(
                              width: 32,
                              height: 6,
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: scoreNum / 100.0,
                                  backgroundColor: AppColors.lightGrey,
                                  color: _getVerdictColor(verdict),
                                ),
                              ),
                            ),
                          Text(score, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (preauthId != null)
                            IconButton(
                              icon: const Icon(
                                Icons.analytics_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              tooltip: 'View AI Preauth Analysis',
                              onPressed: () {
                                final idInt = preauthId is int ? preauthId : int.tryParse(preauthId.toString());
                                if (idInt != null) {
                                  Get.to(() => AiAnalysisResultScreen(preauthId: idInt));
                                }
                              },
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill,
                              size: 20,
                              color: AppColors.success,
                            ),
                            tooltip: 'Start Claim',
                            onPressed: () => _startClaim(item),
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

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final preauthId = item['preauth_id'] ?? item['id'];
        final preauthRef = item['claim_ref'] ?? item['preauth_ref'] ?? 'Ref: $preauthId';
        final packageCode = item['package_code'] ?? '-';
        final verdict = item['verdict'] ?? 'UNKNOWN';
        final verdictColor = _getVerdictColor(verdict);
        final scoreNum = item['total_score'] as num?;
        final score = scoreNum != null ? '${scoreNum.round()}%' : '-';

        final patientData = item['patient'];
        String patientName = '';
        String patientId = '';
        String pmjayNumber = '';
        if (patientData is Map) {
          patientName = patientData['name'] ?? '';
          patientId = (patientData['patient_id'] ?? '').toString();
          pmjayNumber = (patientData['pmjay_number'] ?? '').toString();
        } else {
          patientId = (item['patient_id'] ?? '').toString();
          patientName = item['patient_name'] ?? 'Patient #$patientId';
          pmjayNumber = item['pmjay_number'] ?? '';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      preauthRef,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: verdictColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
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
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _viewPatientDetails(patientId, pmjayNumber),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: AppColors.darkGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.darkGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item['admission_date'] ?? '-'}  to  ${item['discharge_date'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pkg: $packageCode', style: const TextStyle(color: AppColors.darkGrey)),
                    Text('Confidence: $score', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (preauthId != null)
                      TextButton.icon(
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: const Text('AI Analysis'),
                        onPressed: () {
                          final idInt = preauthId is int ? preauthId : int.tryParse(preauthId.toString());
                          if (idInt != null) {
                            Get.to(() => AiAnalysisResultScreen(preauthId: idInt));
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start Claim'),
                      onPressed: () => _startClaim(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
