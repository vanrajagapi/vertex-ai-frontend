import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin_controller.dart';
import '../text_field_group_model.dart';
import '../../../core/theme/app_colors.dart';
import 'group_mappings_dialog.dart';

class TextFieldGroupsListView extends StatefulWidget {
  const TextFieldGroupsListView({super.key});

  @override
  State<TextFieldGroupsListView> createState() => _TextFieldGroupsListViewState();
}

class _TextFieldGroupsListViewState extends State<TextFieldGroupsListView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminController controller = Get.find<AdminController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update Floating Action Button label/icon
    });
    
    // Initial fetch
    controller.fetchTextFieldGroups();
    controller.fetchTextFields();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateGroupDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isActive = true;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Text Field Group',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.darkGrey),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    prefixIcon: const Icon(Icons.folder_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setStateDialog) => Row(
                    children: [
                      const Text(
                        'Active Status',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey),
                      ),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setStateDialog(() {
                            isActive = val;
                          });
                        },
                      ),
                    ],
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
                          await controller.createTextFieldGroup(
                            nameController.text.trim(),
                            descController.text.trim().isEmpty ? null : descController.text.trim(),
                            isActive,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Create', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditGroupDialog(TextFieldGroupResponse group) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: group.groupName);
    final descController = TextEditingController(text: group.description ?? '');
    bool isActive = group.isActive;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Text Field Group',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.darkGrey),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    prefixIcon: const Icon(Icons.folder_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setStateDialog) => Row(
                    children: [
                      const Text(
                        'Active Status',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey),
                      ),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setStateDialog(() {
                            isActive = val;
                          });
                        },
                      ),
                    ],
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
                          await controller.updateTextFieldGroup(
                            group.id,
                            nameController.text.trim(),
                            descController.text.trim().isEmpty ? null : descController.text.trim(),
                            isActive,
                            closeDialog: true,
                          );
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
        ),
      ),
    );
  }

  void _showDeleteGroupDialog(TextFieldGroupResponse group) {
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
        content: Text('Are you sure you want to delete the group "${group.groupName}"? This action is permanent.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.deleteTextFieldGroup(group.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateFieldDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isActive = true;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Text Field',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.darkGrey),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Field Name',
                    prefixIcon: const Icon(Icons.text_fields_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setStateDialog) => Row(
                    children: [
                      const Text(
                        'Active Status',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey),
                      ),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setStateDialog(() {
                            isActive = val;
                          });
                        },
                      ),
                    ],
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
                          await controller.createTextField(
                            nameController.text.trim(),
                            descController.text.trim().isEmpty ? null : descController.text.trim(),
                            isActive,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Create', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditFieldDialog(TextFieldResponse field) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: field.fieldName);
    final descController = TextEditingController(text: field.description ?? '');
    bool isActive = field.isActive;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Text Field',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.darkGrey),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Field Name',
                    prefixIcon: const Icon(Icons.text_fields_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setStateDialog) => Row(
                    children: [
                      const Text(
                        'Active Status',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGrey),
                      ),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setStateDialog(() {
                            isActive = val;
                          });
                        },
                      ),
                    ],
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
                          await controller.updateTextField(
                            field.id,
                            nameController.text.trim(),
                            descController.text.trim().isEmpty ? null : descController.text.trim(),
                            isActive,
                            closeDialog: true,
                          );
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
        ),
      ),
    );
  }

  void _showDeleteFieldDialog(TextFieldResponse field) {
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
        content: Text('Are you sure you want to delete the field "${field.fieldName}"? This action is permanent.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.deleteTextField(field.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isGroupsTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.darkGrey,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 32),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_special_rounded),
                    SizedBox(width: 8),
                    Text('Groups', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.text_fields_rounded),
                    SizedBox(width: 8),
                    Text('All Fields', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsTab(),
          _buildFieldsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isGroupsTab ? _showCreateGroupDialog : _showCreateFieldDialog,
        icon: Icon(isGroupsTab ? Icons.group_add_rounded : Icons.add_box_rounded, color: Colors.white),
        label: Text(
          isGroupsTab ? 'Create Group' : 'Create Field',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Obx(() {
      if (controller.isLoadingGroups.value && controller.textFieldGroups.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.textFieldGroups.isEmpty) {
        return _buildEmptyState(
          icon: Icons.folder_off_rounded,
          title: 'No Groups Found',
          subtitle: 'Create a text field group to group relevant text check fields.',
          onAction: _showCreateGroupDialog,
          buttonText: 'Create Group',
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: controller.textFieldGroups.length,
          itemBuilder: (context, index) {
            final group = controller.textFieldGroups[index];
            return _buildGroupCard(group);
          },
        ),
      );
    });
  }

  Widget _buildGroupCard(TextFieldGroupResponse group) {
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_special_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.groupName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                        ),
                      ),
                      Switch(
                        value: group.isActive,
                        activeThumbColor: AppColors.success,
                        onChanged: (val) {
                          controller.updateTextFieldGroup(group.id, null, null, val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.description ?? 'No description provided.',
                    style: const TextStyle(color: AppColors.darkGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Get.dialog(GroupMappingsDialog(group: group));
                        },
                        icon: const Icon(Icons.settings_input_component_rounded, size: 16, color: Colors.white),
                        label: const Text('Manage Mappings', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _showEditGroupDialog(group),
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                        label: const Text('Edit', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _showDeleteGroupDialog(group),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                        label: const Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsTab() {
    return Obx(() {
      if (controller.isLoadingFields.value && controller.textFields.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.textFields.isEmpty) {
        return _buildEmptyState(
          icon: Icons.text_fields_rounded,
          title: 'No Text Fields Found',
          subtitle: 'Create a text field so you can map it to groups for AI checklists.',
          onAction: _showCreateFieldDialog,
          buttonText: 'Create Field',
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: controller.textFields.length,
          itemBuilder: (context, index) {
            final field = controller.textFields[index];
            return _buildFieldCard(field);
          },
        ),
      );
    });
  }

  Widget _buildFieldCard(TextFieldResponse field) {
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.text_fields_rounded, color: AppColors.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.fieldName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                        ),
                      ),
                      Switch(
                        value: field.isActive,
                        activeThumbColor: AppColors.success,
                        onChanged: (val) {
                          controller.updateTextField(field.id, null, null, val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    field.description ?? 'No description provided.',
                    style: const TextStyle(color: AppColors.darkGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditFieldDialog(field),
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                        label: const Text('Edit', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _showDeleteFieldDialog(field),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                        label: const Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onAction,
    required String buttonText,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, color: AppColors.darkGrey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(buttonText, style: const TextStyle(color: Colors.white)),
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
