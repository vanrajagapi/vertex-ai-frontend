class TextFieldResponse {
  final int id;
  final String fieldName;
  final String? description;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  TextFieldResponse({
    required this.id,
    required this.fieldName,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TextFieldResponse.fromJson(Map<String, dynamic> json) {
    return TextFieldResponse(
      id: json['id'],
      fieldName: json['field_name'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field_name': fieldName,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class TextFieldGroupResponse {
  final int id;
  final String groupName;
  final String? description;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  TextFieldGroupResponse({
    required this.id,
    required this.groupName,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TextFieldGroupResponse.fromJson(Map<String, dynamic> json) {
    return TextFieldGroupResponse(
      id: json['id'],
      groupName: json['group_name'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_name': groupName,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class TextFieldGroupMappingResponse {
  final int id;
  final int groupId;
  final int fieldId;
  final String fieldName;
  final String createdAt;

  TextFieldGroupMappingResponse({
    required this.id,
    required this.groupId,
    required this.fieldId,
    required this.fieldName,
    required this.createdAt,
  });

  factory TextFieldGroupMappingResponse.fromJson(Map<String, dynamic> json) {
    return TextFieldGroupMappingResponse(
      id: json['id'],
      groupId: json['group_id'],
      fieldId: json['field_id'],
      fieldName: json['field_name'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'field_id': fieldId,
      'field_name': fieldName,
      'created_at': createdAt,
    };
  }
}

class TextFieldGroupDetailResponse {
  final int id;
  final String groupName;
  final String? description;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final List<TextFieldGroupMappingResponse> fields;

  TextFieldGroupDetailResponse({
    required this.id,
    required this.groupName,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.fields,
  });

  factory TextFieldGroupDetailResponse.fromJson(Map<String, dynamic> json) {
    var list = json['fields'] as List? ?? [];
    List<TextFieldGroupMappingResponse> fieldsList =
        list.map((i) => TextFieldGroupMappingResponse.fromJson(i)).toList();

    return TextFieldGroupDetailResponse(
      id: json['id'],
      groupName: json['group_name'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      fields: fieldsList,
    );
  }
}
