import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_client.dart';
import '../../core/utils/logger.dart';
import 'user_model.dart';
import 'package:claim_automate_checker/features/admin/package_model.dart';
import 'text_field_group_model.dart';
import 'agent_prompt_model.dart';

abstract class IAdminRepository {
  Future<List<AdminUser>> getUsers();
  Future<bool> createUser(AdminUser user, String password);
  Future<List<PackageModel>> getPackages();
  Future<bool> createPackage(PackageModel package);
  Future<bool> updateUser(String username, AdminUser user);
  Future<bool> updatePackage(String code, PackageModel package);
  Future<PackageWeightsResponse?> getPackageWeights(String code);
  Future<bool> updatePackageWeights(String code, PackageWeightsUpdate update);
  Future<List<PackageDocument>> getPackageDocuments(String code);
  Future<PackageDocument?> createPackageDocument(
    String code,
    PackageDocument doc,
  );
  Future<PackageDocument?> updatePackageDocument(
    String code,
    int docId,
    PackageDocument doc,
  );
  Future<bool> deletePackageDocument(String code, int docId);
  Future<List<String>> getAgentScoringNames();
  Future<List<AgentPrompt>> getAgentPrompts();
  Future<AgentPrompt?> updateAgentPrompt(String agentName, String systemPrompt);

  // Text Field Group Management
  Future<List<TextFieldGroupResponse>> getTextFieldGroups();
  Future<TextFieldGroupDetailResponse?> getTextFieldGroupDetail(int groupId);
  Future<TextFieldGroupResponse?> createTextFieldGroup(
    String name,
    String? description,
    bool isActive,
  );
  Future<TextFieldGroupResponse?> updateTextFieldGroup(
    int groupId,
    String? name,
    String? description,
    bool? isActive,
  );
  Future<bool> deleteTextFieldGroup(int groupId);

  // Text Field Management
  Future<List<TextFieldResponse>> getTextFields();
  Future<TextFieldResponse?> createTextField(
    String name,
    String? description,
    bool isActive,
  );
  Future<TextFieldResponse?> updateTextField(
    int fieldId,
    String? name,
    String? description,
    bool? isActive,
  );
  Future<bool> deleteTextField(int fieldId);

  // Mappings
  Future<List<TextFieldGroupMappingResponse>> getGroupMappings(int groupId);
  Future<List<TextFieldGroupMappingResponse>> addFieldsToGroup(
    int groupId,
    List<int> fieldIds,
  );
  Future<bool> removeFieldFromGroup(int groupId, int mappingId);
}

class AdminRepository implements IAdminRepository {
  final Dio _dio = ApiClient.createDio();

  Options _getOptions() {
    _dio.options.baseUrl = AppConfig.baseUrl;
    final token = StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  @override
  Future<List<AdminUser>> getUsers() async {
    try {
      final response = await _dio.get(
        '/api/v1/admin/users',
        options: _getOptions(),
      );

      AppLogger.printData("getUsers status", response.statusCode.toString());

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => AdminUser.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.printData("getUsers error", e.toString());
      return [];
    }
  }

  @override
  Future<bool> createUser(AdminUser user, String password) async {
    try {
      final response = await _dio.post(
        '/api/v1/admin/users',
        data: {
          'username': user.username,
          'email': user.email,
          'full_name': user.fullName,
          'role': user.role,
          'password': password,
          'is_active': true,
        },
        options: _getOptions(),
      );

      AppLogger.printData("createUser status", response.statusCode.toString());

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      AppLogger.printData("createUser error", e.toString());
      return false;
    }
  }

  @override
  Future<List<PackageModel>> getPackages() async {
    try {
      final response = await _dio.get(
        '/api/v1/admin/packages',
        options: _getOptions(),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => PackageModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.printData("getPackages error", e.toString());
      return [];
    }
  }

  @override
  Future<bool> createPackage(PackageModel package) async {
    try {
      final response = await _dio.post(
        '/api/v1/admin/packages',
        data: package.toJson(),
        options: _getOptions(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      AppLogger.printData("createPackage error", e.toString());
      return false;
    }
  }

  @override
  Future<bool> updateUser(String username, AdminUser user) async {
    try {
      final response = await _dio.put(
        '/api/v1/admin/users/$username',
        data: user.toJson(),
        options: _getOptions(),
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.printData("updateUser error", e.toString());
      return false;
    }
  }

  @override
  Future<bool> updatePackage(String code, PackageModel package) async {
    try {
      final response = await _dio.put(
        '/api/v1/admin/packages/$code',
        data: package.toJson(),
        options: _getOptions(),
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.printData("updatePackage error", e.toString());
      return false;
    }
  }

  @override
  Future<bool> updatePackageWeights(
    String code,
    PackageWeightsUpdate update,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/admin/packages/$code/weights',
        data: update.toJson(),
        options: _getOptions(),
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.printData("updatePackageWeights error", e.toString());
      return false;
    }
  }

  @override
  Future<PackageWeightsResponse?> getPackageWeights(String code) async {
    try {
      final response = await _dio.get(
        '/api/v1/admin/packages/$code/weights',
        options: _getOptions(),
      );
      if (response.statusCode == 200) {
        return PackageWeightsResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.printData("getPackageWeights error", e.toString());
      return null;
    }
  }

  @override
  Future<List<String>> getAgentScoringNames() async {
    try {
      final response = await _dio.get(
        '/api/v1/admin/agents/scoring-names',
        options: _getOptions(),
      );
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((item) => item.toString()).toList();
      }
      return [];
    } catch (e) {
      AppLogger.printData("getAgentScoringNames error", e.toString());
      return [];
    }
  }

  @override
  Future<List<AgentPrompt>> getAgentPrompts() async {
    try {
      final response = await _dio.get(
        '/api/v1/admin/agents/prompts',
        options: _getOptions(),
      );
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => AgentPrompt.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.printData("getAgentPrompts error", e.toString());
      return [];
    }
  }

  @override
  Future<AgentPrompt?> updateAgentPrompt(
    String agentName,
    String systemPrompt,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/admin/agents/$agentName/prompt',
        data: {'system_prompt': systemPrompt},
        options: _getOptions(),
      );
      if (response.statusCode == 200) {
        return AgentPrompt.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.printData("updateAgentPrompt error", e.toString());
      return null;
    }
  }

  @override
  Future<List<PackageDocument>> getPackageDocuments(String code) async {
    try {
      final response = await _dio.get(
        '/api/v1/admin/packages/$code/documents',
        options: _getOptions(),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => PackageDocument.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.printData("getPackageDocuments error", e.toString());
      return [];
    }
  }

  @override
  Future<PackageDocument?> createPackageDocument(
    String code,
    PackageDocument doc,
  ) async {
    try {
      final payload = {
        'field_key_id': doc.fieldKeyId,
        'label': doc.label,
        'field_group_id': doc.fieldGroupId,
        'data_type': doc.dataType,
        'mandatory': doc.mandatory,
        'sort_order': doc.sortOrder,
        'notes': doc.notes,
        'stage': doc.stage,
        'clinical_relevant': doc.clinicalRelevant,
        'billing_relevant': doc.billingRelevant,
        'discharge_relevant': doc.dischargeRelevant,
        'identity_relevant': doc.identityRelevant,
        'lab_relevant': doc.labRelevant,
        'image_relevant': doc.imageRelevant,
        'radiology_relevant': doc.radiologyRelevant,
        'icp_relevant': doc.icpRelevant,
      };
      final response = await _dio.post(
        '/api/v1/admin/packages/$code/documents',
        data: payload,
        options: _getOptions(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PackageDocument.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      AppLogger.printData("createPackageDocument DioException", 
        "Status: ${e.response?.statusCode}, Data: ${e.response?.data}, Message: ${e.message}");
      return null;
    } catch (e) {
      AppLogger.printData("createPackageDocument error", e.toString());
      return null;
    }
  }

  @override
  Future<PackageDocument?> updatePackageDocument(
    String code,
    int docId,
    PackageDocument doc,
  ) async {
    try {
      final payload = {
        'field_key_id': doc.fieldKeyId,
        'label': doc.label,
        'field_group_id': doc.fieldGroupId,
        'data_type': doc.dataType,
        'mandatory': doc.mandatory,
        'sort_order': doc.sortOrder,
        'notes': doc.notes,
        'stage': doc.stage,
        'clinical_relevant': doc.clinicalRelevant,
        'billing_relevant': doc.billingRelevant,
        'discharge_relevant': doc.dischargeRelevant,
        'identity_relevant': doc.identityRelevant,
        'lab_relevant': doc.labRelevant,
        'image_relevant': doc.imageRelevant,
        'radiology_relevant': doc.radiologyRelevant,
        'icp_relevant': doc.icpRelevant,
      };
      final response = await _dio.put(
        '/api/v1/admin/packages/$code/documents/$docId',
        data: payload,
        options: _getOptions(),
      );

      if (response.statusCode == 200) {
        return PackageDocument.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      AppLogger.printData("updatePackageDocument DioException", 
        "Status: ${e.response?.statusCode}, Data: ${e.response?.data}, Message: ${e.message}");
      return null;
    } catch (e) {
      AppLogger.printData("updatePackageDocument error", e.toString());
      return null;
    }
  }

  @override
  Future<bool> deletePackageDocument(String code, int docId) async {
    try {
      final response = await _dio.delete(
        '/api/v1/admin/packages/$code/documents/$docId',
        options: _getOptions(),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppLogger.printData("deletePackageDocument error", e.toString());
      return false;
    }
  }

  // Text Field Group Management
  @override
  Future<List<TextFieldGroupResponse>> getTextFieldGroups() async {
    try {
      final response = await _dio.get(
        '/api/v1/admin/text-field-groups',
        options: _getOptions(),
      );
      if (response.statusCode == 200) {
        final List data = response.data;
        return data
            .map((json) => TextFieldGroupResponse.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.printData("getTextFieldGroups error", e.toString());
      return [];
    }
  }

  @override
  Future<TextFieldGroupDetailResponse?> getTextFieldGroupDetail(
    int groupId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/admin/text-field-groups/$groupId',
        options: _getOptions(),
      );
      if (response.statusCode == 200) {
        return TextFieldGroupDetailResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.printData("getTextFieldGroupDetail error", e.toString());
      return null;
    }
  }

  @override
  Future<TextFieldGroupResponse?> createTextFieldGroup(
    String name,
    String? description,
    bool isActive,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/admin/text-field-groups',
        data: {
          'group_name': name,
          'description': description,
          'is_active': isActive,
        },
        options: _getOptions(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TextFieldGroupResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.printData("createTextFieldGroup error", e.toString());
      return null;
    }
  }

  @override
  Future<TextFieldGroupResponse?> updateTextFieldGroup(
    int groupId,
    String? name,
    String? description,
    bool? isActive,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/admin/text-field-groups/$groupId',
        data: {
          'group_name': ?name,
          'description': ?description,
          'is_active': ?isActive,
        },
        options: _getOptions(),
      );
      if (response.statusCode == 200) {
        return TextFieldGroupResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.printData("updateTextFieldGroup error", e.toString());
      return null;
    }
  }

  @override
  Future<bool> deleteTextFieldGroup(int groupId) async {
    try {
      final response = await _dio.delete(
        '/api/v1/admin/text-field-groups/$groupId',
        options: _getOptions(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppLogger.printData("deleteTextFieldGroup error", e.toString());
      return false;
    }
  }

  // Text Field Management
  @override
  Future<List<TextFieldResponse>> getTextFields() async {
    try {
      final response = await _dio.get(
        '/api/v1/admin/text-fields',
        options: _getOptions(),
      );
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => TextFieldResponse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.printData("getTextFields error", e.toString());
      return [];
    }
  }

  @override
  Future<TextFieldResponse?> createTextField(
    String name,
    String? description,
    bool isActive,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/admin/text-fields',
        data: {
          'field_name': name,
          'description': description,
          'is_active': isActive,
        },
        options: _getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TextFieldResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.printData("createTextField error", e.toString());
      return null;
    }
  }

  @override
  Future<TextFieldResponse?> updateTextField(
    int fieldId,
    String? name,
    String? description,
    bool? isActive,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/admin/text-fields/$fieldId',
        data: {
          'field_name': ?name,
          'description': ?description,
          'is_active': ?isActive,
        },
        options: _getOptions(),
      );
      if (response.statusCode == 200) {
        return TextFieldResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.printData("updateTextField error", e.toString());
      return null;
    }
  }

  @override
  Future<bool> deleteTextField(int fieldId) async {
    try {
      final response = await _dio.delete(
        '/api/v1/admin/text-fields/$fieldId',
        options: _getOptions(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppLogger.printData("deleteTextField error", e.toString());
      return false;
    }
  }

  // Mappings
  @override
  Future<List<TextFieldGroupMappingResponse>> getGroupMappings(
    int groupId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/admin/text-field-groups/$groupId/mappings',
        options: _getOptions(),
      );
      if (response.statusCode == 200) {
        final List data = response.data;
        return data
            .map((json) => TextFieldGroupMappingResponse.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.printData("getGroupMappings error", e.toString());
      return [];
    }
  }

  @override
  Future<List<TextFieldGroupMappingResponse>> addFieldsToGroup(
    int groupId,
    List<int> fieldIds,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/admin/text-field-groups/$groupId/mappings',
        data: {'field_ids': fieldIds},
        options: _getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List data = response.data;
        return data
            .map((json) => TextFieldGroupMappingResponse.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.printData("addFieldsToGroup error", e.toString());
      return [];
    }
  }

  @override
  Future<bool> removeFieldFromGroup(int groupId, int mappingId) async {
    try {
      final response = await _dio.delete(
        '/api/v1/admin/text-field-groups/$groupId/mappings/$mappingId',
        options: _getOptions(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppLogger.printData("removeFieldFromGroup error", e.toString());
      return false;
    }
  }
}
