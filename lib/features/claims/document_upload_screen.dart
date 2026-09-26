import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../patients/patient_model.dart';
import '../patients/patient_repository.dart';
import '../admin/package_model.dart';
import 'package:get/get.dart';
import 'ai_analysis_result_screen.dart';

class UploadedFile {
  final String fileName;
  final Uint8List bytes;
  final DateTime uploadDate;
  final bool isPdf;

  UploadedFile({
    required this.fileName,
    required this.bytes,
    required this.uploadDate,
    this.isPdf = false,
  });
}

class DocumentItem {
  final String type;
  final String requiredFormat;
  final bool isMandatory;
  final String? fieldKey;
  final String
  fieldGroup; // e.g. 'text', 'ot_notes', 'pathology', 'radiology', 'others'
  final String dataType; // 'string' or 'array'
  final bool isDynamic;
  final List<UploadedFile> files = []; // List of uploaded files
  final TextEditingController textController;

  DocumentItem({
    required this.type,
    required this.requiredFormat,
    this.isMandatory = true,
    this.fieldKey,
    this.fieldGroup = 'others',
    this.dataType = 'string',
    this.isDynamic = false,
  }) : textController = TextEditingController();

  bool get isUploaded {
    if (fieldGroup == 'text' || fieldGroup == 'ot_notes') {
      return textController.text.trim().isNotEmpty;
    }
    return files.isNotEmpty || textController.text.trim().isNotEmpty;
  }

  void dispose() {
    textController.dispose();
  }
}

class DocumentUploadScreen extends StatefulWidget {
  final Patient patient;
  final PackageModel package;
  final Map<String, List<PackageDocument>> documentGroups;
  final String stage; // 'preauth' or 'claim'
  final int? preauthId;

  const DocumentUploadScreen({
    super.key,
    required this.patient,
    required this.package,
    required this.documentGroups,
    this.stage = 'preauth',
    this.preauthId,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  late final Map<String, List<DocumentItem>> _stepDocuments;
  late final List<String> _stepKeys;
  int _currentStepIndex = 0;
  final Map<DocumentItem, bool> _extractingStatus = {};
  bool _isSubmitting = false;

  List<DocumentItem> get _documents {
    final list = <DocumentItem>[];
    for (final key in _stepKeys) {
      list.addAll(_stepDocuments[key] ?? []);
    }
    return list;
  }

  List<DocumentItem> get _currentDocuments {
    if (_stepKeys.isEmpty) return [];
    return _stepDocuments[_stepKeys[_currentStepIndex]] ?? [];
  }

  @override
  void initState() {
    super.initState();

    _stepDocuments = {};

    // Sort keys based on the minimum sort_order of their documents
    final keys = widget.documentGroups.keys.toList();
    keys.sort((a, b) {
      final listA = widget.documentGroups[a] ?? [];
      final listB = widget.documentGroups[b] ?? [];
      final minA = listA.isEmpty
          ? 999
          : listA
                .map((d) => d.sortOrder)
                .reduce((curr, next) => curr < next ? curr : next);
      final minB = listB.isEmpty
          ? 999
          : listB
                .map((d) => d.sortOrder)
                .reduce((curr, next) => curr < next ? curr : next);
      return minA.compareTo(minB);
    });

    _stepKeys = keys
        .where((k) => widget.documentGroups[k]!.isNotEmpty)
        .toList();

    for (final key in _stepKeys) {
      final rules = widget.documentGroups[key] ?? [];
      _stepDocuments[key] = rules.map((rule) {
        return DocumentItem(
          type: rule.label,
          requiredFormat:
              rule.fieldGroup == 'text' || rule.fieldGroup == 'ot_notes'
              ? 'Text Input'
              : (rule.dataType == 'array'
                    ? 'Image/PDF (Multiple)'
                    : 'Image/PDF'),
          isMandatory: rule.mandatory,
          fieldKey: rule.fieldKey,
          fieldGroup: rule.fieldGroup,
          dataType: rule.dataType,
        );
      }).toList();
    }

    _attachFindingsListeners();
  }

  void _attachFindingsListeners() {
    for (final doc in _documents) {
      if (doc.fieldKey == 'laboratory_findings' ||
          doc.fieldKey == 'radiology_findings') {
        doc.textController.addListener(_onFindingsTextChanged);
      }
    }
  }

  void _onFindingsTextChanged() {
    if (!mounted) return;
    _syncDynamicFindingFields();
    setState(() {});
  }

  /// Parses comma/semicolon/newline-separated finding names.
  List<String> _parseFindings(String? text) {
    if (text == null || text.trim().isEmpty) return [];
    return text
        .split(RegExp(r'[,;|\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String? _findingsTextFor(String fieldKey) {
    for (final doc in _documents) {
      if (doc.fieldKey == fieldKey) {
        return doc.textController.text.trim();
      }
    }
    return null;
  }

  String? _stepKeyForGroup(String group) {
    for (final key in _stepKeys) {
      if (key.toLowerCase() == group.toLowerCase()) return key;
    }
    return null;
  }

  /// Creates mandatory array fields in pathology/radiology from findings text.
  void _syncDynamicFindingFields({Map<String, dynamic>? dataMap}) {
    final labText =
        dataMap?['laboratory_findings']?.toString() ??
        _findingsTextFor('laboratory_findings');
    final radText =
        dataMap?['radiology_findings']?.toString() ??
        _findingsTextFor('radiology_findings');

    _updateDynamicFieldsForGroup('pathology', labText);
    _updateDynamicFieldsForGroup('radiology', radText);
  }

  void _updateDynamicFieldsForGroup(String group, String? findingsText) {
    final stepKey = _stepKeyForGroup(group);
    if (stepKey == null) return;

    final docs = _stepDocuments[stepKey]!;
    final desiredKeys = _parseFindings(findingsText).toSet();

    final toRemove = docs
        .where((d) => d.isDynamic && !desiredKeys.contains(d.fieldKey))
        .toList();
    for (final d in toRemove) {
      d.dispose();
      docs.remove(d);
    }

    for (final fieldKey in desiredKeys) {
      if (docs.any((d) => d.fieldKey == fieldKey)) continue;
      docs.add(
        DocumentItem(
          type: fieldKey,
          requiredFormat: 'Image/PDF (Multiple)',
          isMandatory: true,
          fieldKey: fieldKey,
          fieldGroup: group,
          dataType: 'array',
          isDynamic: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var doc in _documents) {
      if (doc.fieldKey == 'laboratory_findings' ||
          doc.fieldKey == 'radiology_findings') {
        doc.textController.removeListener(_onFindingsTextChanged);
      }
      doc.dispose();
    }
    super.dispose();
  }

  String _formatStepTitle(String key) {
    if (key.isEmpty) return '';
    return key
        .split(RegExp(r'[\s_]+'))
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  bool _isStepCompleted(String key) {
    final docs = _stepDocuments[key] ?? [];
    if (docs.isEmpty) return false;
    final mandatoryCompleted = docs.every(
      (d) => !d.isMandatory || d.isUploaded,
    );
    if (!mandatoryCompleted) return false;
    return docs.any((d) => d.isUploaded);
  }

  /// Opens the file picker using file_picker (cross-platform).
  Future<void> _pickFile(int index) async {
    final doc = _currentDocuments[index];

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true, // Needed for web and to get bytes directly
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    final bytes = pickedFile.bytes;
    if (bytes == null) return;

    final isPdf = pickedFile.extension?.toLowerCase() == 'pdf';

    if (!mounted) return;
    setState(() {
      doc.files.add(
        UploadedFile(
          fileName: pickedFile.name,
          bytes: bytes,
          uploadDate: DateTime.now(),
          isPdf: isPdf,
        ),
      );
    });
  }

  void _removeFile(int docIndex, int fileIndex) {
    setState(() {
      _currentDocuments[docIndex].files.removeAt(fileIndex);
    });
  }

  Future<void> _handleExtractFields(DocumentItem doc) async {
    if (doc.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one document to extract data.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _extractingStatus[doc] = true;
    });

    try {
      final patientRepository = PatientRepository();

      final simplifiedFiles = doc.files
          .map((file) => {'name': file.fileName, 'bytes': file.bytes})
          .toList();

      final resultString = await patientRepository.extractFields(
        widget.package.code,
        simplifiedFiles,
      );

      if (!mounted) return;

      setState(() {
        _extractingStatus[doc] = false;
        if (resultString != null) {
          try {
            final decoded = jsonDecode(resultString);
            if (decoded is Map<String, dynamic>) {
              // Extract the nested 'extracted_data' map if present
              final Map<String, dynamic> dataMap =
                  decoded.containsKey('extracted_data') &&
                      decoded['extracted_data'] is Map<String, dynamic>
                  ? decoded['extracted_data'] as Map<String, dynamic>
                  : decoded;

              bool mappedAny = false;
              for (var docItem in _documents) {
                if (docItem.dataType == 'string' &&
                    docItem.fieldKey != null &&
                    dataMap.containsKey(docItem.fieldKey)) {
                  final val = dataMap[docItem.fieldKey];
                  if (val != null) {
                    docItem.textController.text = val.toString();
                    mappedAny = true;
                  }
                }
              }

              _syncDynamicFindingFields(dataMap: dataMap);

              // Fallback to setting raw response or targeted key
              if (!mappedAny) {
                if (doc.fieldKey != null && dataMap.containsKey(doc.fieldKey)) {
                  final val = dataMap[doc.fieldKey];
                  doc.textController.text = val != null ? val.toString() : '';
                } else {
                  doc.textController.text = resultString;
                }
              }
            } else {
              doc.textController.text = resultString;
            }
          } catch (_) {
            doc.textController.text = resultString;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Field extraction completed successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _extractingStatus[doc] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Extraction failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Full-screen zoomable image preview dialog, or opens PDF.
  void _showPreview(UploadedFile file) {
    if (file.isPdf) {
      // PDF viewing is complex cross-platform.
      // For now, we'll suggest using a PDF viewer or just showing a message.
      // On web, we could still use dart:html if we wanted, but let's stay platform-agnostic.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF Preview not implemented for desktop yet. Only images can be previewed.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                file.fileName,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.memory(file.bytes, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _submitFinalClaim() {
    if (_isSubmitting) return;
    _syncDynamicFindingFields();

    final List<String> missingFields = [];
    for (int i = 0; i < _stepKeys.length; i++) {
      final key = _stepKeys[i];
      final docs = _stepDocuments[key] ?? [];
      final incomplete = docs
          .where((d) => d.isMandatory && !d.isUploaded)
          .toList();
      for (var d in incomplete) {
        missingFields.add('${_formatStepTitle(key)}: ${d.type}');
      }
    }

    if (missingFields.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Missing Mandatory Fields',
                  style: AppTextStyles.heading2,
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The following compulsory fields/documents have not been provided:',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: missingFields.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  missingFields[index],
                                  style: const TextStyle(
                                    color: AppColors.darkGrey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Warning: Submitting without these mandatory details may cause the claim validator to FAIL/Reject this claim.',
                            style: TextStyle(
                              color: AppColors.error.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: AppColors.darkGrey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showClaimDetailsDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit Anyway'),
              ),
            ],
          );
        },
      );
    } else {
      _showClaimDetailsDialog();
    }
  }

  void _handleNextOrSubmit() {
    _syncDynamicFindingFields();
    if (_currentStepIndex < _stepKeys.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      _submitFinalClaim();
    }
  }

  Future<void> _showClaimDetailsDialog() async {
    final formKey = GlobalKey<FormState>();
    final hospitalIdController = TextEditingController(
      text: 'Parul Sevashram Hospital',
    );
    DateTime admissionDate = DateTime.now().subtract(const Duration(days: 5));
    DateTime dischargeDate = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.stage == 'preauth'
                        ? 'Preauth Details'
                        : 'Hospitalization Details',
                    style: AppTextStyles.heading2,
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stage == 'preauth'
                            ? 'Please provide the preauth details to finalize the submission.'
                            : 'Please provide the hospitalization details to finalize the claim submission.',
                        style: const TextStyle(
                          color: AppColors.darkGrey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: hospitalIdController,
                        decoration: InputDecoration(
                          labelText: 'Hospital ID',
                          prefixIcon: const Icon(Icons.local_hospital_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      // Admission Date field
                      InkWell(
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: admissionDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            setDialogState(() {
                              admissionDate = selected;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Admission Date',
                            prefixIcon: const Icon(Icons.login_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            '${admissionDate.year}-${admissionDate.month.toString().padLeft(2, '0')}-${admissionDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      if (widget.stage != 'preauth') ...[
                        const SizedBox(height: 16),
                        // Discharge Date field
                        InkWell(
                          onTap: () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: dischargeDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selected != null) {
                              setDialogState(() {
                                dischargeDate = selected;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Discharge Date',
                              prefixIcon: const Icon(Icons.logout_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              '${dischargeDate.year}-${dischargeDate.month.toString().padLeft(2, '0')}-${dischargeDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.darkGrey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (widget.stage != 'preauth' &&
                          dischargeDate.isBefore(admissionDate)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Discharge date cannot be before admission date.',
                            ),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop({
                        'hospital_id': hospitalIdController.text.trim(),
                        'admission_date':
                            '${admissionDate.year}-${admissionDate.month.toString().padLeft(2, '0')}-${admissionDate.day.toString().padLeft(2, '0')}',
                        if (widget.stage != 'preauth')
                          'discharge_date':
                              '${dischargeDate.year}-${dischargeDate.month.toString().padLeft(2, '0')}-${dischargeDate.day.toString().padLeft(2, '0')}',
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    _performClaimSubmission(result);
  }

  Future<void> _performClaimSubmission(Map<String, dynamic> details) async {
    setState(() {
      _isSubmitting = true;
    });

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.stage == 'preauth'
                      ? 'Submitting preauth to PMJAY...'
                      : 'Submitting claim to PMJAY...',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final List<Map<String, dynamic>> claimDocuments = [];
      for (var doc in _documents) {
        if (doc.dataType == 'string') {
          claimDocuments.add({
            'field_key': doc.fieldKey,
            'field_group': doc.fieldGroup,
            'text_value': doc.textController.text.trim(),
            'files': [],
          });
        } else {
          final List<Map<String, dynamic>> filesList = doc.files.map((file) {
            return {
              'filename': file.fileName,
              'content_base64': base64Encode(file.bytes),
              'file_path': null,
            };
          }).toList();

          claimDocuments.add({
            'field_key': doc.fieldKey,
            'field_group': doc.fieldGroup,
            'text_value': null,
            'files': filesList,
          });
        }
      }

      final patientRepository = PatientRepository();
      final patientId = int.tryParse(widget.patient.id) ?? 0;

      if (widget.stage == 'preauth') {
        final response = await patientRepository.submitPreauth(
          patientId: patientId,
          packageCode: widget.package.code,
          hospitalId: details['hospital_id'],
          admissionDate: details['admission_date'],
          documents: claimDocuments,
        );

        // Pop the loading dialog
        Navigator.of(context).pop();

        setState(() {
          _isSubmitting = false;
        });

        if (response != null &&
            (response['preauth_id'] != null || response['claim_id'] != null)) {
          final preauthId = response['preauth_id'] ?? response['claim_id'];

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 32),
                  SizedBox(width: 12),
                  Text('Preauth Successful', style: AppTextStyles.heading2),
                ],
              ),
              content: Text(
                'Preauth submitted successfully! Preauth ID: $preauthId.\nProceed to Step 5: AI Scoring and Analysis?',
                style: AppTextStyles.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // pop success dialog
                    Navigator.of(
                      context,
                    ).popUntil((r) => r.isFirst); // return to dashboard
                  },
                  child: const Text(
                    'Return to Dashboard',
                    style: TextStyle(color: AppColors.darkGrey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // pop success dialog
                    Get.to(() => AiAnalysisResultScreen(preauthId: preauthId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start AI Analysis'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preauth submitted, but no preauth ID returned.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final response = await patientRepository.submitClaim(
          patientId: patientId,
          packageCode: widget.package.code,
          hospitalId: details['hospital_id'],
          admissionDate: details['admission_date'],
          dischargeDate: details['discharge_date'],
          documents: claimDocuments,
          preauthId: widget.preauthId,
        );

        // Pop the loading dialog
        Navigator.of(context).pop();

        setState(() {
          _isSubmitting = false;
        });

        if (response != null &&
            (response['claim_id'] != null || response['preauth_id'] != null)) {
          final claimId = response['claim_id'] ?? response['preauth_id'];

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 32),
                  SizedBox(width: 12),
                  Text('Submission Successful', style: AppTextStyles.heading2),
                ],
              ),
              content: Text(
                'Claim submitted successfully! Claim ID: $claimId.\nProceed to Step 5: AI Scoring and Analysis?',
                style: AppTextStyles.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // pop success dialog
                    Navigator.of(
                      context,
                    ).popUntil((r) => r.isFirst); // return to dashboard
                  },
                  child: const Text(
                    'Return to Dashboard',
                    style: TextStyle(color: AppColors.darkGrey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // pop success dialog
                    Get.to(() => AiAnalysisResultScreen(claimId: claimId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start AI Analysis'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Claim submitted, but no claim ID returned.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Pop loading dialog
      Navigator.of(context).pop();

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.stage == 'preauth'
              ? 'Step 4 — Preauth Document Upload'
              : 'Step 4 — Claim Document Upload',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryDark,
        elevation: 1,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Indicator
                _buildStepIndicator(),
                const SizedBox(height: 12),

                // ── Card ────────────────────────────────────────────────────
                Container(
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
                    border: Border.all(
                      color: AppColors.lightGrey.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.file_upload_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _stepKeys.isNotEmpty
                                ? _formatStepTitle(_stepKeys[_currentStepIndex])
                                : 'Upload Required Documents',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload an image/document for this step. '
                        'Tap the thumbnail to zoom in, and fill in any text field inputs.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Responsive layout
                      if (_currentDocuments.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Text(
                              'No documents to upload for this step.',
                              style: TextStyle(
                                color: AppColors.darkGrey,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (ctx, constraints) =>
                              constraints.maxWidth > 620
                              ? _buildDesktopTable()
                              : _buildMobileList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Navigation Buttons ────────────────────────────────────────────
                _buildNavigationRow(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step Indicator ──────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    if (_stepKeys.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_stepKeys.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connecting line
            final stepIndex = index ~/ 2;
            final isLineCompleted = _isStepCompleted(_stepKeys[stepIndex]);
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 36,
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      color: isLineCompleted
                          ? AppColors.success
                          : AppColors.lightGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Empty space matching label height to keep line columns aligned
                  const SizedBox(height: 16),
                ],
              ),
            );
          } else {
            // Step bubble + label
            final stepIndex = index ~/ 2;
            final key = _stepKeys[stepIndex];
            final isCurrent = stepIndex == _currentStepIndex;
            final isCompleted = _isStepCompleted(key);
            final title = _formatStepTitle(key);

            return SizedBox(
              width: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Tooltip(
                    message: title,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _currentStepIndex = stepIndex;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary
                              : (isCompleted
                                    ? AppColors.success
                                    : AppColors.background),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primaryDark
                                : (isCompleted
                                      ? AppColors.success
                                      : AppColors.grey),
                            width: 2,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${stepIndex + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent
                                        ? Colors.white
                                        : AppColors.darkGrey,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 80,
                    height: 16,
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: 120,
                      minHeight: 0,
                      maxHeight: 16,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? AppColors.primary
                              : (isCompleted
                                    ? AppColors.success
                                    : AppColors.darkGrey),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }),
      ),
    );
  }

  // ── Navigation Row ──────────────────────────────────────────────────────────

  Widget _buildNavigationRow() {
    if (_stepKeys.isEmpty) {
      return SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFinalClaim,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  widget.stage == 'preauth'
                      ? 'Finalize Preauth Submission'
                      : 'Finalize Claim Submission',
                  style: AppTextStyles.button,
                ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStepIndex > 0)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStepIndex--;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  label: const Text(
                    'Previous Step',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleNextOrSubmit,
              icon: Icon(
                _currentStepIndex == _stepKeys.length - 1
                    ? Icons.check_circle_outline
                    : Icons.arrow_forward,
                color: Colors.white,
              ),
              label: Text(
                _currentStepIndex == _stepKeys.length - 1
                    ? (widget.stage == 'preauth'
                          ? 'Finalize Preauth'
                          : 'Finalize Claim')
                    : 'Next Step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
        ),
      ],
    );
  }

  // ── Desktop table ──────────────────────────────────────────────────────────

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.5), // Document type
          1: FlexColumnWidth(1.1), // Thumbnail
          2: FlexColumnWidth(2.8), // Notes text field
          3: FlexColumnWidth(1.3), // Status
          4: FlexColumnWidth(1.0), // Action
        },
        border: TableBorder(
          horizontalInside: BorderSide(
            color: AppColors.lightGrey.withOpacity(0.5),
          ),
        ),
        children: [
          // Header row
          TableRow(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            children: [
              _tableHeader('Document Type'),
              _tableHeader('Preview'),
              _tableHeader('Notes / Data'),
              _tableHeader('Status'),
              _tableHeader('Action'),
            ],
          ),
          for (int i = 0; i < _currentDocuments.length; i++)
            _buildDesktopRow(i),
        ],
      ),
    );
  }

  TableRow _buildDesktopRow(int i) {
    final doc = _currentDocuments[i];
    final isArrayType = doc.dataType == 'array';
    final isTextOrOtNotes =
        (doc.fieldGroup == 'text' || doc.fieldGroup == 'ot_notes') &&
        doc.dataType != 'string';

    return TableRow(
      children: [
        // Document name
        _tableCell(
          doc.type + (doc.isMandatory ? ' *' : ' (Optional)'),
          isBold: true,
        ),

        // Thumbnail(s) or Text Area indication
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: isTextOrOtNotes
              ? Container(
                  height: 60,
                  width: 74,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                  ),
                  child: const Tooltip(
                    message: 'Text data field. Type in notes column.',
                    child: Icon(
                      Icons.edit_note_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                )
              : (doc.files.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(doc.files.length, (fileIndex) {
                          final file = doc.files[fileIndex];
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () => _showPreview(file),
                                child: Tooltip(
                                  message: 'Click to zoom',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: file.isPdf
                                        ? Container(
                                            height: 60,
                                            width: 74,
                                            color: AppColors.lightGrey
                                                .withOpacity(0.3),
                                            child: const Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.redAccent,
                                              size: 32,
                                            ),
                                          )
                                        : Image.memory(
                                            file.bytes,
                                            height: 60,
                                            width: 74,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: GestureDetector(
                                  onTap: () => _removeFile(i, fileIndex),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.cancel,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      )
                    : _emptyThumbnail()),
        ),

        // Notes field / Dynamic text area input
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: isArrayType
              ? const Center(
                  child: Text(
                    'Files only (No Text)',
                    style: TextStyle(
                      color: AppColors.darkGrey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : TextFormField(
                  controller: doc.textController,
                  maxLines: isTextOrOtNotes ? 25 : 25,
                  minLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isTextOrOtNotes
                        ? 'Fill / type in data for ${doc.type} here…'
                        : 'Type document notes / key data here…',
                    hintStyle: const TextStyle(
                      color: AppColors.darkGrey,
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.lightGrey),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
        ),

        // Status
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: _statusWidget(doc),
        ),

        // Upload / Add More button (Hidden for text-input forms)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: isTextOrOtNotes
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickFile(i),
                        icon: Icon(
                          doc.files.isNotEmpty
                              ? Icons.add_a_photo
                              : Icons.upload_file,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          doc.files.isNotEmpty ? 'Add More' : 'Upload',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                      ),
                      if (doc.dataType == 'string' && doc.files.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _extractingStatus[doc] == true
                            ? const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.success,
                                    ),
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: () => _handleExtractFields(doc),
                                icon: const Icon(
                                  Icons.psychology,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Extract',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ── Mobile list ────────────────────────────────────────────────────────────

  Widget _buildMobileList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _currentDocuments.length,
      separatorBuilder: (context, index) =>
          const Divider(color: AppColors.lightGrey, height: 1),
      itemBuilder: (_, i) {
        final doc = _currentDocuments[i];
        final isArrayType = doc.dataType == 'array';
        final isTextOrOtNotes =
            (doc.fieldGroup == 'text' || doc.fieldGroup == 'ot_notes') &&
            doc.dataType != 'string';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      doc.type + (doc.isMandatory ? ' *' : ' (Optional)'),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: doc.isMandatory
                            ? AppColors.dark
                            : AppColors.darkGrey,
                      ),
                    ),
                  ),
                  if (!isTextOrOtNotes)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (doc.dataType == 'string') ...[
                          _extractingStatus[doc] == true
                              ? const Padding(
                                  padding: EdgeInsets.only(right: 12.0),
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.success,
                                      ),
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleExtractFields(doc),
                                    icon: const Icon(
                                      Icons.psychology,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Extract',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                        OutlinedButton.icon(
                          onPressed: () => _pickFile(i),
                          icon: Icon(
                            doc.files.isNotEmpty
                                ? Icons.add_a_photo
                                : Icons.upload_file,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            doc.files.isNotEmpty ? 'Add More' : 'Upload',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Image preview(s) or Text Indicator
              if (isTextOrOtNotes)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_note_outlined, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Text data input field. Fill details below.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (doc.files.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(doc.files.length, (fileIndex) {
                      final file = doc.files[fileIndex];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => _showPreview(file),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: file.isPdf
                                    ? Container(
                                        height: 120,
                                        width: 160,
                                        color: AppColors.lightGrey.withOpacity(
                                          0.3,
                                        ),
                                        child: const Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.redAccent,
                                          size: 50,
                                        ),
                                      )
                                    : Image.memory(
                                        file.bytes,
                                        height: 120,
                                        width: 160,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: GestureDetector(
                                onTap: () => _removeFile(i, fileIndex),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.cancel,
                                    color: AppColors.error,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                )
              else ...[
                _emptyThumbnail(fullWidth: true),
              ],
              const SizedBox(height: 12),

              // Notes field / Data Fill area (Hidden for array type)
              if (!isArrayType) ...[
                TextFormField(
                  controller: doc.textController,
                  maxLines: isTextOrOtNotes ? 5 : 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: isTextOrOtNotes
                        ? 'Fill / type in data for ${doc.type} here…'
                        : 'Type document notes / key data here…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.lightGrey),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
              ],

              // Status
              _statusWidget(doc),
            ],
          ),
        );
      },
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _emptyThumbnail({bool fullWidth = false}) {
    return Container(
      height: fullWidth ? 100 : 68,
      width: fullWidth ? double.infinity : 84,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.8)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: AppColors.darkGrey, size: 26),
          SizedBox(height: 4),
          Text(
            'No file uploaded',
            style: TextStyle(fontSize: 11, color: AppColors.darkGrey),
          ),
        ],
      ),
    );
  }

  Widget _statusWidget(DocumentItem doc) {
    if (doc.files.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                '${doc.files.length} File${doc.files.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(doc.files.last.uploadDate),
            style: const TextStyle(color: AppColors.darkGrey, fontSize: 11),
          ),
        ],
      );
    } else if (doc.textController.text.trim().isNotEmpty) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 15),
          SizedBox(width: 4),
          Text(
            'Manual Entry',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            doc.isMandatory ? Icons.pending_actions : Icons.info_outline,
            color: doc.isMandatory ? AppColors.warning : AppColors.grey,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            doc.isMandatory ? 'Pending' : 'Optional',
            style: TextStyle(
              color: doc.isMandatory ? AppColors.warning : AppColors.darkGrey,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      );
    }
  }

  Widget _tableHeader(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
        fontSize: 13,
      ),
    ),
  );

  Widget _tableCell(String text, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: isBold ? FontWeight.w500 : FontWeight.normal,
        color: isBold ? AppColors.dark : AppColors.darkGrey,
        fontSize: 13,
      ),
    ),
  );

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
