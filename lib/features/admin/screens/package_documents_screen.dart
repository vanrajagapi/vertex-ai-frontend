import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin_controller.dart';
import '../package_model.dart';
import '../text_field_group_model.dart';
import '../../../core/theme/app_colors.dart';

class PackageDocumentsScreen extends StatefulWidget {
  final PackageModel package;
  const PackageDocumentsScreen({super.key, required this.package});

  @override
  State<PackageDocumentsScreen> createState() => _PackageDocumentsScreenState();
}

class _PackageDocumentsScreenState extends State<PackageDocumentsScreen> with SingleTickerProviderStateMixin {
  final AdminController controller = Get.find<AdminController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to filter the documents list
    });
    controller.fetchPackageDocuments(widget.package.code);
    controller.fetchTextFieldGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDocumentDialog() {
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController();
    final notesController = TextEditingController();
    final sortOrderController = TextEditingController(text: '0');
    
    int? selectedFieldGroupId;
    int? selectedFieldKeyId;
    List<TextFieldGroupMappingResponse> mappedFields = [];
    bool isLoadingFields = false;
    String selectedDataType = 'string';
    bool isMandatory = true;
    String selectedStage = 'preauth';
    bool isClinicalRelevant = false;
    bool isBillingRelevant = false;
    bool isDischargeRelevant = false;
    bool isIdentityRelevant = false;
    bool isLabRelevant = false;
    bool isImageRelevant = false;
    bool isRadiologyRelevant = false;
    bool isIcpRelevant = false;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
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
                                  color: AppColors.primaryAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.note_add_outlined, color: AppColors.primaryAccent),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Add Document Rule',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
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
                      const Divider(height: 24, thickness: 1),
                      const SizedBox(height: 8),

                      // Field Group Dropdown
                      DropdownButtonFormField<int>(
                        value: selectedFieldGroupId,
                        decoration: InputDecoration(
                          labelText: 'Field Group',
                          prefixIcon: const Icon(Icons.folder_open_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null ? 'Required' : null,
                        items: controller.textFieldGroups.map((g) {
                          return DropdownMenuItem<int>(
                            value: g.id,
                            child: Text(g.groupName),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            setStateDialog(() {
                              selectedFieldGroupId = val;
                              selectedFieldKeyId = null;
                              mappedFields = [];
                              isLoadingFields = true;
                            });
                            try {
                              final fields = await controller.getGroupMappings(val);
                              setStateDialog(() {
                                mappedFields = fields;
                                  isLoadingFields = false;
                              });
                            } catch (e) {
                              setStateDialog(() {
                                isLoadingFields = false;
                              });
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Field Key Dropdown (dynamic)
                      if (selectedFieldGroupId == null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: const Text(
                            'Please select a Field Group first to view its fields.',
                            style: TextStyle(color: AppColors.darkGrey, fontSize: 13),
                          ),
                        )
                      else if (isLoadingFields)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (mappedFields.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: const Text(
                            'No fields are mapped to the selected group.',
                            style: TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: selectedFieldKeyId,
                          decoration: InputDecoration(
                            labelText: 'Field Key',
                            prefixIcon: const Icon(Icons.key_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value == null ? 'Required' : null,
                          items: mappedFields.map((f) {
                            return DropdownMenuItem<int>(
                              value: f.fieldId,
                              child: Text(f.fieldName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() {
                                selectedFieldKeyId = val;
                                // Auto-fill Label based on the field name
                                final selectedMapping = mappedFields.firstWhere((f) => f.fieldId == val);
                                labelController.text = selectedMapping.fieldName
                                    .replaceAll('_', ' ')
                                    .split(' ')
                                    .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
                                    .join(' ');
                              });
                            }
                          },
                        ),
                      const SizedBox(height: 16),

                      // Label Field
                      TextFormField(
                        controller: labelController,
                        decoration: InputDecoration(
                          labelText: 'Label (e.g. Discharge Summary)',
                          prefixIcon: const Icon(Icons.label_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Data Type Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedDataType,
                        decoration: InputDecoration(
                          labelText: 'Data Type',
                          prefixIcon: const Icon(Icons.data_object_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'string', child: Text('Single File (string)')),
                          DropdownMenuItem(value: 'array', child: Text('Multiple Files (array)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              selectedDataType = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sort Order & Mandatory Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: sortOrderController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Sort Order',
                                prefixIcon: const Icon(Icons.sort_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (int.tryParse(value) == null) return 'Must be numeric';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Mandatory',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey),
                              ),
                              Switch(
                                value: isMandatory,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isMandatory = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stage Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedStage,
                        decoration: InputDecoration(
                          labelText: 'Stage',
                          prefixIcon: const Icon(Icons.layers_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'preauth', child: Text('Pre-Auth')),
                          DropdownMenuItem(value: 'claim', child: Text('Claim')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              selectedStage = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Relevance Flags Wrap
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isClinicalRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isClinicalRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Clinical Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isBillingRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isBillingRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Billing Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isDischargeRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isDischargeRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Discharge Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isIdentityRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isIdentityRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Identity Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isLabRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isLabRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Lab Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isImageRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isImageRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Image Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isRadiologyRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isRadiologyRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Radiology Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isIcpRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isIcpRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'ICP Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes Field
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Guideline Notes (Optional)',
                          prefixIcon: const Icon(Icons.info_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.darkGrey)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                // Find selected group's group name for local state compatibility
                                final groupName = controller.textFieldGroups
                                    .firstWhere((g) => g.id == selectedFieldGroupId)
                                    .groupName;
                                
                                // Find selected field's field name for local state compatibility
                                final fieldName = mappedFields
                                    .firstWhere((f) => f.fieldId == selectedFieldKeyId)
                                    .fieldName;

                                final doc = PackageDocument(
                                  fieldKeyId: selectedFieldKeyId,
                                  fieldKey: fieldName,
                                  label: labelController.text.trim(),
                                  fieldGroupId: selectedFieldGroupId,
                                  fieldGroup: groupName,
                                  dataType: selectedDataType,
                                  mandatory: isMandatory,
                                  sortOrder: int.parse(sortOrderController.text),
                                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                  stage: selectedStage,
                                  clinicalRelevant: isClinicalRelevant,
                                  billingRelevant: isBillingRelevant,
                                  dischargeRelevant: isDischargeRelevant,
                                  identityRelevant: isIdentityRelevant,
                                  labRelevant: isLabRelevant,
                                  imageRelevant: isImageRelevant,
                                  radiologyRelevant: isRadiologyRelevant,
                                  icpRelevant: isIcpRelevant,
                                );
                                await controller.createPackageDocument(widget.package.code, doc);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Add Rule', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditDocumentDialog(PackageDocument doc) async {
    // Show a loading overlay while fetching the mappings for the document's group
    Get.showOverlay(
      asyncFunction: () async {
        if (doc.fieldGroupId != null) {
          return await controller.getGroupMappings(doc.fieldGroupId!);
        }
        return <TextFieldGroupMappingResponse>[];
      },
      loadingWidget: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Loading field mappings...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    ).then((mappings) {
      _showEditDocumentDialogWithMappings(doc, mappings);
    });
  }

  void _showEditDocumentDialogWithMappings(PackageDocument doc, List<TextFieldGroupMappingResponse> initialMappings) {
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController(text: doc.label);
    final notesController = TextEditingController(text: doc.notes ?? '');
    final sortOrderController = TextEditingController(text: doc.sortOrder.toString());
    
    int? selectedFieldGroupId = doc.fieldGroupId;
    int? selectedFieldKeyId = doc.fieldKeyId;
    List<TextFieldGroupMappingResponse> mappedFields = initialMappings;
    bool isLoadingFields = false;
    String selectedDataType = doc.dataType;
    bool isMandatory = doc.mandatory;
    String selectedStage = doc.stage;
    bool isClinicalRelevant = doc.clinicalRelevant;
    bool isBillingRelevant = doc.billingRelevant;
    bool isDischargeRelevant = doc.dischargeRelevant;
    bool isIdentityRelevant = doc.identityRelevant;
    bool isLabRelevant = doc.labRelevant;
    bool isImageRelevant = doc.imageRelevant;
    bool isRadiologyRelevant = doc.radiologyRelevant;
    bool isIcpRelevant = doc.icpRelevant;

    // Safety check in case the loaded mapping doesn't contain the currently selected key ID
    if (selectedFieldKeyId != null && !mappedFields.any((f) => f.fieldId == selectedFieldKeyId)) {
      selectedFieldKeyId = null;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
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
                                  color: AppColors.primaryAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.edit_note_outlined, color: AppColors.primaryAccent),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Edit Document Rule',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
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
                      const Divider(height: 24, thickness: 1),
                      const SizedBox(height: 8),

                      // Field Group Dropdown
                      DropdownButtonFormField<int>(
                        value: selectedFieldGroupId,
                        decoration: InputDecoration(
                          labelText: 'Field Group',
                          prefixIcon: const Icon(Icons.folder_open_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null ? 'Required' : null,
                        items: controller.textFieldGroups.map((g) {
                          return DropdownMenuItem<int>(
                            value: g.id,
                            child: Text(g.groupName),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val != null && val != selectedFieldGroupId) {
                            setStateDialog(() {
                              selectedFieldGroupId = val;
                              selectedFieldKeyId = null;
                              mappedFields = [];
                              isLoadingFields = true;
                            });
                            try {
                              final fields = await controller.getGroupMappings(val);
                              setStateDialog(() {
                                mappedFields = fields;
                                isLoadingFields = false;
                              });
                            } catch (e) {
                              setStateDialog(() {
                                isLoadingFields = false;
                              });
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Field Key Dropdown (dynamic)
                      if (selectedFieldGroupId == null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: const Text(
                            'Please select a Field Group first to view its fields.',
                            style: TextStyle(color: AppColors.darkGrey, fontSize: 13),
                          ),
                        )
                      else if (isLoadingFields)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (mappedFields.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: const Text(
                            'No fields are mapped to the selected group.',
                            style: TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: selectedFieldKeyId,
                          decoration: InputDecoration(
                            labelText: 'Field Key',
                            prefixIcon: const Icon(Icons.key_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value == null ? 'Required' : null,
                          items: mappedFields.map((f) {
                            return DropdownMenuItem<int>(
                              value: f.fieldId,
                              child: Text(f.fieldName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() {
                                selectedFieldKeyId = val;
                                // Auto-fill Label based on the field name
                                final selectedMapping = mappedFields.firstWhere((f) => f.fieldId == val);
                                labelController.text = selectedMapping.fieldName
                                    .replaceAll('_', ' ')
                                    .split(' ')
                                    .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
                                    .join(' ');
                              });
                            }
                          },
                        ),
                      const SizedBox(height: 16),

                      // Label Field
                      TextFormField(
                        controller: labelController,
                        decoration: InputDecoration(
                          labelText: 'Label (e.g. Discharge Summary)',
                          prefixIcon: const Icon(Icons.label_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Data Type Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedDataType,
                        decoration: InputDecoration(
                          labelText: 'Data Type',
                          prefixIcon: const Icon(Icons.data_object_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'string', child: Text('Single File (string)')),
                          DropdownMenuItem(value: 'array', child: Text('Multiple Files (array)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              selectedDataType = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sort Order & Mandatory Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: sortOrderController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Sort Order',
                                prefixIcon: const Icon(Icons.sort_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (int.tryParse(value) == null) return 'Must be numeric';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Mandatory',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey),
                              ),
                              Switch(
                                value: isMandatory,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isMandatory = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stage Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedStage,
                        decoration: InputDecoration(
                          labelText: 'Stage',
                          prefixIcon: const Icon(Icons.layers_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'preauth', child: Text('Pre-Auth')),
                          DropdownMenuItem(value: 'claim', child: Text('Claim')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              selectedStage = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Relevance Flags Wrap
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isClinicalRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isClinicalRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Clinical Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isBillingRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isBillingRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Billing Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isDischargeRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isDischargeRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Discharge Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isIdentityRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isIdentityRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Identity Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isLabRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isLabRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Lab Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isImageRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isImageRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Image Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isRadiologyRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isRadiologyRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Radiology Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isIcpRelevant,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    isIcpRelevant = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'ICP Relevant',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes Field
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Guideline Notes (Optional)',
                          prefixIcon: const Icon(Icons.info_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.darkGrey)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                // Find selected group's group name for local state compatibility
                                final groupName = controller.textFieldGroups
                                    .firstWhere((g) => g.id == selectedFieldGroupId)
                                    .groupName;
                                
                                // Find selected field's field name for local state compatibility
                                final fieldName = mappedFields
                                    .firstWhere((f) => f.fieldId == selectedFieldKeyId)
                                    .fieldName;

                                final updatedDoc = PackageDocument(
                                  id: doc.id,
                                  packageId: doc.packageId,
                                  fieldKeyId: selectedFieldKeyId,
                                  fieldKey: fieldName,
                                  label: labelController.text.trim(),
                                  fieldGroupId: selectedFieldGroupId,
                                  fieldGroup: groupName,
                                  dataType: selectedDataType,
                                  mandatory: isMandatory,
                                  sortOrder: int.parse(sortOrderController.text),
                                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                  stage: selectedStage,
                                  clinicalRelevant: isClinicalRelevant,
                                  billingRelevant: isBillingRelevant,
                                  dischargeRelevant: isDischargeRelevant,
                                  identityRelevant: isIdentityRelevant,
                                  labRelevant: isLabRelevant,
                                  imageRelevant: isImageRelevant,
                                  radiologyRelevant: isRadiologyRelevant,
                                  icpRelevant: isIcpRelevant,
                                );
                                if (doc.id != null) {
                                  await controller.updatePackageDocument(
                                    widget.package.code,
                                    doc.id!,
                                    updatedDoc,
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(PackageDocument doc) {
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
          'Are you sure you want to delete the document rule "${doc.label}"? This action cannot be undone.',
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
            onPressed: () async {
              if (doc.id != null) {
                await controller.deletePackageDocument(
                  widget.package.code,
                  doc.id!,
                );
              }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Documents Rule: ${widget.package.code}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: 'PRE-AUTH'),
            Tab(text: 'CLAIM'),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingDocuments.value && controller.packageDocuments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredDocs = controller.packageDocuments.where((doc) {
          if (_tabController.index == 0) return true;
          if (_tabController.index == 1) return doc.stage == 'preauth';
          return doc.stage == 'claim';
        }).toList();

        if (filteredDocs.isEmpty) {
          String filterName = _tabController.index == 1 ? 'Pre-Auth' : (_tabController.index == 2 ? 'Claim' : '');
          return _buildEmptyState(
            title: filterName.isNotEmpty ? 'No $filterName document rules' : 'No document rules defined',
            subtitle: filterName.isNotEmpty
                ? 'Define the required files, groups, and mandates for the $filterName stage under this package.'
                : 'Define the required files, groups, and mandates for claims registered under the ${widget.package.name} (${widget.package.code}) package.',
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    return _buildDocumentCard(doc);
                  },
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDocumentDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Document Rule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final filteredCount = controller.packageDocuments.where((doc) {
      if (_tabController.index == 0) return true;
      if (_tabController.index == 1) return doc.stage == 'preauth';
      return doc.stage == 'claim';
    }).length;

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
              Text(
                widget.package.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _tabController.index == 0
                    ? 'Total Configured Documents: ${controller.packageDocuments.length}'
                    : 'Documents in this stage: $filteredCount (out of ${controller.packageDocuments.length})',
                style: const TextStyle(color: AppColors.darkGrey, fontSize: 13),
              ),
            ],
          ),
          const Icon(
            Icons.article_outlined,
            size: 36,
            color: AppColors.primaryAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(PackageDocument doc) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.primaryAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          doc.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: doc.mandatory 
                              ? AppColors.error.withOpacity(0.1) 
                              : AppColors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          doc.mandatory ? 'Mandatory' : 'Optional',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: doc.mandatory ? AppColors.error : AppColors.darkGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTag('Key: ${doc.fieldKey}', AppColors.primary.withOpacity(0.1), AppColors.primary),
                      const SizedBox(width: 8),
                      _buildTag('Group: ${doc.fieldGroup.toUpperCase()}', Colors.orange.withOpacity(0.1), Colors.orange),
                      const SizedBox(width: 8),
                      _buildTag('Type: ${doc.dataType}', Colors.teal.withOpacity(0.1), Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildTag('Stage: ${doc.stage.toUpperCase()}', Colors.purple.withOpacity(0.1), Colors.purple),
                      if (doc.clinicalRelevant)
                        _buildTag('Clinical', Colors.red.withOpacity(0.1), Colors.red),
                      if (doc.billingRelevant)
                        _buildTag('Billing', Colors.blue.withOpacity(0.1), Colors.blue),
                      if (doc.dischargeRelevant)
                        _buildTag('Discharge', Colors.green.withOpacity(0.1), Colors.green),
                      if (doc.identityRelevant)
                        _buildTag('Identity', Colors.indigo.withOpacity(0.1), Colors.indigo),
                      if (doc.labRelevant)
                        _buildTag('Lab', Colors.amber.withOpacity(0.1), Colors.amber.shade800),
                      if (doc.imageRelevant)
                        _buildTag('Image', Colors.cyan.withOpacity(0.1), Colors.cyan.shade800),
                      if (doc.radiologyRelevant)
                        _buildTag('Radiology', Colors.deepOrange.withOpacity(0.1), Colors.deepOrange),
                      if (doc.icpRelevant)
                        _buildTag('ICP', Colors.teal.withOpacity(0.1), Colors.teal),
                    ],
                  ),
                  if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Guidelines: ${doc.notes}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                  onPressed: () => _showEditDocumentDialog(doc),
                  tooltip: 'Edit Document Rule',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => _showDeleteConfirmationDialog(doc),
                  tooltip: 'Delete Document Rule',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }

  Widget _buildEmptyState({String? title, String? subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 80,
              color: AppColors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'No document rules defined',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.darkGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle ?? 'Define the required files, groups, and mandates for claims registered under the ${widget.package.name} (${widget.package.code}) package.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddDocumentDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Document Rule', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
