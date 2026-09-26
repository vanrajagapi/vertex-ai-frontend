import 'package:claim_automate_checker/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_repository.dart';
import 'user_model.dart';
import 'text_field_group_model.dart';
import '../../core/theme/app_colors.dart';

import 'package:claim_automate_checker/features/admin/package_model.dart';
import 'agent_prompt_model.dart';

class AdminController extends GetxController {
  final IAdminRepository repository;

  AdminController({required this.repository});

  final RxList<AdminUser> users = <AdminUser>[].obs;
  final RxList<PackageModel> packages = <PackageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt selectedIndex = 0.obs;

  // Text Field Group observables
  final RxList<TextFieldGroupResponse> textFieldGroups =
      <TextFieldGroupResponse>[].obs;
  final RxList<TextFieldResponse> textFields = <TextFieldResponse>[].obs;
  final RxMap<int, TextFieldGroupDetailResponse> groupDetails =
      <int, TextFieldGroupDetailResponse>{}.obs;
  final RxBool isLoadingGroups = false.obs;
  final RxBool isLoadingFields = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    fetchPackages();
  }

  void changeTabIndex(int index) {
    selectedIndex.value = index;
    if (index == 1 && users.isEmpty) fetchUsers();
    if (index == 2 && packages.isEmpty) fetchPackages();
    if (index == 3) {
      if (textFieldGroups.isEmpty) fetchTextFieldGroups();
      if (textFields.isEmpty) fetchTextFields();
    }
    if (index == 4 && agentPrompts.isEmpty) fetchAgentPrompts();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final data = await repository.getUsers();
      users.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPackages() async {
    isLoading.value = true;
    try {
      final data = await repository.getPackages();
      packages.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createUser(
    String username,
    String fullName,
    String email,
    String role,
    String password,
  ) async {
    isLoading.value = true;
    try {
      final user = AdminUser(
        username: username,
        fullName: fullName,
        email: email,
        role: role,
      );
      final success = await repository.createUser(user, password);

      if (success) {
        await fetchUsers();
        Get.back(); // Navigate back from Create User screen
        Get.snackbar(
          'Success',
          'User created successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to create user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createPackage(PackageModel package) async {
    isLoading.value = true;
    try {
      final success = await repository.createPackage(package);

      if (success) {
        await fetchPackages();
        Get.back(); // Navigate back from Create Package screen
        Get.snackbar(
          'Success',
          'Package created successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to create package',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUser(String oldUsername, AdminUser user) async {
    isLoading.value = true;
    try {
      final success = await repository.updateUser(oldUsername, user);
      if (success) {
        await fetchUsers();
        Get.back();
        Get.snackbar(
          'Success',
          'User updated successfully',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update user',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePackage(String code, PackageModel package) async {
    isLoading.value = true;

    try {
      final success = await repository.updatePackage(code, package);
      if (success) {
        await fetchPackages();
        Get.back();
        Get.snackbar(
          'Success',
          'Package updated successfully',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update package',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePackageWeights(
    String code,
    PackageWeightsUpdate update,
  ) async {
    isLoading.value = true;
    AppLogger.printData(
      "PackageWeightsUpdate list",
      update.toJson().toString(),
    );

    try {
      final success = await repository.updatePackageWeights(code, update);
      if (success) {
        await fetchPackages();
        Get.back();
        Get.snackbar(
          'Success',
          'Package weights updated successfully',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update package weights',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  final RxBool isLoadingWeights = false.obs;

  Future<List<PackageWeight>> fetchPackageWeights(String code) async {
    isLoadingWeights.value = true;
    try {
      final response = await repository.getPackageWeights(code);
      if (response != null) {
        return response.weights;
      }
      return [];
    } finally {
      isLoadingWeights.value = false;
    }
  }

  final RxList<String> agentScoringNames = <String>[].obs;
  final RxBool isLoadingAgents = false.obs;

  Future<void> fetchAgentScoringNames() async {
    isLoadingAgents.value = true;
    try {
      final data = await repository.getAgentScoringNames();
      agentScoringNames.assignAll(data);
    } finally {
      isLoadingAgents.value = false;
    }
  }

  final RxList<AgentPrompt> agentPrompts = <AgentPrompt>[].obs;
  final RxBool isLoadingPrompts = false.obs;

  Future<void> fetchAgentPrompts() async {
    isLoadingPrompts.value = true;
    try {
      final data = await repository.getAgentPrompts();
      agentPrompts.assignAll(data);
    } finally {
      isLoadingPrompts.value = false;
    }
  }

  Future<bool> updateAgentPrompt(String agentName, String systemPrompt) async {
    isLoadingPrompts.value = true;
    try {
      final updated = await repository.updateAgentPrompt(agentName, systemPrompt);
      if (updated != null) {
        Get.back(); // Close dialog first to avoid GetX snackbar popping issues
        final idx = agentPrompts.indexWhere((p) => p.agentName == agentName);
        if (idx != -1) {
          agentPrompts[idx] = updated;
        } else {
          await fetchAgentPrompts();
        }
        Get.snackbar(
          'Success',
          'Agent prompt updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to update agent prompt',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingPrompts.value = false;
    }
  }

  final RxList<PackageDocument> packageDocuments = <PackageDocument>[].obs;
  final RxBool isLoadingDocuments = false.obs;

  Future<void> fetchPackageDocuments(String code) async {
    isLoadingDocuments.value = true;
    try {
      final data = await repository.getPackageDocuments(code);
      // Sort them by sortOrder ascending
      data.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      packageDocuments.assignAll(data);
    } finally {
      isLoadingDocuments.value = false;
    }
  }

  Future<bool> createPackageDocument(String code, PackageDocument doc) async {
    isLoadingDocuments.value = true;
    try {
      final newDoc = await repository.createPackageDocument(code, doc);
      if (newDoc != null) {
        Get.back(); // Close dialog first to avoid GetX snackbar popping issues
        await fetchPackageDocuments(code);
        Get.snackbar(
          'Success',
          'Package document created successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to create package document',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingDocuments.value = false;
    }
  }

  Future<bool> updatePackageDocument(
    String code,
    int docId,
    PackageDocument doc,
  ) async {
    isLoadingDocuments.value = true;
    try {
      final updatedDoc = await repository.updatePackageDocument(
        code,
        docId,
        doc,
      );
      if (updatedDoc != null) {
        Get.back(); // Close dialog first to avoid GetX snackbar popping issues
        await fetchPackageDocuments(code);
        Get.snackbar(
          'Success',
          'Package document updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to update package document',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingDocuments.value = false;
    }
  }

  Future<bool> deletePackageDocument(String code, int docId) async {
    isLoadingDocuments.value = true;
    try {
      final success = await repository.deletePackageDocument(code, docId);
      if (success) {
        Get.back(); // Close dialog first to avoid GetX snackbar popping issues
        await fetchPackageDocuments(code);
        Get.snackbar(
          'Success',
          'Package document deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete package document',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingDocuments.value = false;
    }
  }

  // --- Text Field Group Management ---

  Future<void> fetchTextFieldGroups() async {
    isLoadingGroups.value = true;
    try {
      final data = await repository.getTextFieldGroups();
      textFieldGroups.assignAll(data);
    } finally {
      isLoadingGroups.value = false;
    }
  }

  Future<void> fetchTextFieldGroupDetail(int groupId) async {
    try {
      final detail = await repository.getTextFieldGroupDetail(groupId);
      if (detail != null) {
        groupDetails[groupId] = detail;
      }
    } catch (e) {
      debugPrint("fetchTextFieldGroupDetail error: $e");
    }
  }

  Future<bool> createTextFieldGroup(
    String name,
    String? description,
    bool isActive,
  ) async {
    isLoadingGroups.value = true;
    try {
      final result = await repository.createTextFieldGroup(
        name,
        description,
        isActive,
      );
      if (result != null) {
        Get.back(); // Close dialog first to avoid GetX snackbar popping issues
        await fetchTextFieldGroups();
        Get.snackbar(
          'Success',
          'Text field group created successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to create text field group',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingGroups.value = false;
    }
  }

  Future<bool> updateTextFieldGroup(
    int groupId,
    String? name,
    String? description,
    bool? isActive, {
    bool closeDialog = false,
  }) async {
    isLoadingGroups.value = true;
    try {
      final result = await repository.updateTextFieldGroup(
        groupId,
        name,
        description,
        isActive,
      );
      if (result != null) {
        await fetchTextFieldGroups();
        // If the group details were already fetched, refresh them
        if (groupDetails.containsKey(groupId)) {
          await fetchTextFieldGroupDetail(groupId);
        }
        if (closeDialog) {
          Get.back(); // Close dialog first to avoid GetX snackbar popping issues
        }
        Get.snackbar(
          'Success',
          'Text field group updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to update text field group',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingGroups.value = false;
    }
  }

  Future<bool> deleteTextFieldGroup(int groupId) async {
    isLoadingGroups.value = true;
    try {
      final success = await repository.deleteTextFieldGroup(groupId);
      if (success) {
        textFieldGroups.removeWhere((g) => g.id == groupId);
        groupDetails.remove(groupId);
        Get.back(); // Close confirmation dialog first to avoid GetX snackbar popping issues
        Get.snackbar(
          'Success',
          'Text field group deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete text field group',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingGroups.value = false;
    }
  }

  // --- Text Field Management ---

  Future<void> fetchTextFields() async {
    isLoadingFields.value = true;
    try {
      final data = await repository.getTextFields();
      textFields.assignAll(data);
    } finally {
      isLoadingFields.value = false;
    }
  }

  Future<bool> createTextField(
    String name,
    String? description,
    bool isActive,
  ) async {
    isLoadingFields.value = true;
    try {
      final result = await repository.createTextField(
        name,
        description,
        isActive,
      );
      if (result != null) {
        Get.back(); // Close dialog first to avoid GetX snackbar popping issues
        await fetchTextFields();
        Get.snackbar(
          'Success',
          'Text field created successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to create text field',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingFields.value = false;
    }
  }

  Future<bool> updateTextField(
    int fieldId,
    String? name,
    String? description,
    bool? isActive, {
    bool closeDialog = false,
  }) async {
    isLoadingFields.value = true;
    try {
      final result = await repository.updateTextField(
        fieldId,
        name,
        description,
        isActive,
      );
      if (result != null) {
        await fetchTextFields();
        if (closeDialog) {
          Get.back(); // Close dialog first to avoid GetX snackbar popping issues
        }
        Get.snackbar(
          'Success',
          'Text field updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to update text field',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingFields.value = false;
    }
  }

  Future<bool> deleteTextField(int fieldId) async {
    isLoadingFields.value = true;
    try {
      final success = await repository.deleteTextField(fieldId);
      if (success) {
        textFields.removeWhere((f) => f.id == fieldId);
        Get.back(); // Close confirmation dialog first to avoid GetX snackbar popping issues
        Get.snackbar(
          'Success',
          'Text field deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete text field',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingFields.value = false;
    }
  }

  // --- Group Mappings ---

  Future<bool> addFieldsToGroup(int groupId, List<int> fieldIds) async {
    isLoadingGroups.value = true;
    try {
      final result = await repository.addFieldsToGroup(groupId, fieldIds);
      if (result.isNotEmpty) {
        await fetchTextFieldGroupDetail(groupId);
        Get.snackbar(
          'Success',
          'Mapped fields to group successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to map fields to group',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingGroups.value = false;
    }
  }

  Future<bool> removeFieldFromGroup(int groupId, int mappingId) async {
    isLoadingGroups.value = true;
    try {
      final success = await repository.removeFieldFromGroup(groupId, mappingId);
      if (success) {
        await fetchTextFieldGroupDetail(groupId);
        Get.snackbar(
          'Success',
          'Removed field mapping successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to remove field mapping',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoadingGroups.value = false;
    }
  }

  Future<List<TextFieldGroupMappingResponse>> getGroupMappings(
    int groupId,
  ) async {
    return await repository.getGroupMappings(groupId);
  }
}
