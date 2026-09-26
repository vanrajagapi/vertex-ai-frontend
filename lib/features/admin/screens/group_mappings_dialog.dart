import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin_controller.dart';
import '../text_field_group_model.dart';
import '../../../core/theme/app_colors.dart';

class GroupMappingsDialog extends StatefulWidget {
  final TextFieldGroupResponse group;
  const GroupMappingsDialog({super.key, required this.group});

  @override
  State<GroupMappingsDialog> createState() => _GroupMappingsDialogState();
}

class _GroupMappingsDialogState extends State<GroupMappingsDialog> {
  final AdminController controller = Get.find<AdminController>();
  final List<int> _selectedFieldIds = [];

  @override
  void initState() {
    super.initState();
    controller.fetchTextFieldGroupDetail(widget.group.id);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Obx(() {
          final detail = controller.groupDetails[widget.group.id];
          final mappedFields = detail?.fields ?? [];
          final allFields = controller.textFields;

          // Filter unmapped active fields
          final mappedIds = mappedFields.map((m) => m.fieldId).toSet();
          final unmappedFields = allFields
              .where((f) => f.isActive && !mappedIds.contains(f.id))
              .toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mappings: ${widget.group.groupName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Configure text fields that belong to this group.',
                          style: TextStyle(
                            color: AppColors.darkGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.darkGrey),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Content split into two sections: Current Mappings and Add Mappings
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Current Mappings
                      const Text(
                        'Currently Mapped Fields',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (mappedFields.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'No fields mapped to this group yet.',
                              style: TextStyle(
                                color: AppColors.darkGrey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: mappedFields.length,
                          itemBuilder: (context, index) {
                            final mapping = mappedFields[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.lightGrey),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.text_fields_rounded,
                                    color: AppColors.primaryLight,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      mapping.fieldName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      controller.removeFieldFromGroup(
                                        widget.group.id,
                                        mapping.id,
                                      );
                                    },
                                    tooltip: 'Remove Mapping',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Section 2: Add Mappings
                      const Text(
                        'Map New Fields',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (unmappedFields.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'All active fields are mapped to this group.',
                              style: TextStyle(
                                color: AppColors.darkGrey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: unmappedFields.length,
                          itemBuilder: (context, index) {
                            final field = unmappedFields[index];
                            final isChecked = _selectedFieldIds.contains(
                              field.id,
                            );
                            return CheckboxListTile(
                              value: isChecked,
                              title: Text(
                                field.fieldName,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: field.description != null
                                  ? Text(
                                      field.description!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.darkGrey,
                                      ),
                                    )
                                  : null,
                              dense: true,
                              activeColor: AppColors.primary,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (bool? checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedFieldIds.add(field.id);
                                  } else {
                                    _selectedFieldIds.remove(field.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              // const SizedBox(height: 16),

              // Footer close button
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: _selectedFieldIds.isEmpty
                      ? null
                      : () async {
                          final success = await controller.addFieldsToGroup(
                            widget.group.id,
                            _selectedFieldIds,
                          );
                          if (success) {
                            setState(() {
                              _selectedFieldIds.clear();
                            });
                          }
                        },
                  icon: const Icon(Icons.add_link_rounded, color: Colors.white),
                  label: const Text(
                    'Map Selected Fields',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
