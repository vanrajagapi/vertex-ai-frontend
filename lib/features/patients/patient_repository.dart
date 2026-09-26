import 'package:dio/dio.dart';
import 'dart:convert';
import '../../core/config/app_config.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_client.dart';
import '../../core/utils/logger.dart';
import '../admin/package_model.dart';
import 'patient_model.dart';

abstract class IPatientRepository {
  Future<List<Patient>> getPatients({String? search});
  Future<Patient?> addPatient(Patient patient);
  Future<bool> deletePatient(String id);
  Future<Patient?> getPatientById(String id);
  Future<Patient?> getPatientByPMJY(String pmjyNumber);
  Future<Map<String, dynamic>?> getFormSchema(
    String code,
    int patientId, {
    String? stage,
  });
  Future<List<PackageModel>> getPackages();
  Future<String?> extractFields(
    String packageCode,
    List<Map<String, dynamic>> files,
  );
  Future<Map<String, dynamic>?> submitClaim({
    required int patientId,
    required String packageCode,
    required String hospitalId,
    required String admissionDate,
    required String dischargeDate,
    required List<Map<String, dynamic>> documents,
    int? preauthId,
  });
  Future<Map<String, dynamic>?> scoreClaim(int claimId);
  Future<Map<String, dynamic>?> preflightCheck(int claimId);
  Future<Map<String, dynamic>?> getClaimReport(int claimId);
  Future<List<dynamic>?> getPatientClaims(int patientId);
  Future<List<PackageWeight>> getPackageWeights(String code);
  Future<bool> updatePackageWeights(String code, PackageWeightsUpdate update);

  // Preauth endpoints
  Future<Map<String, dynamic>?> submitPreauth({
    required int patientId,
    required String packageCode,
    required String hospitalId,
    required String admissionDate,
    required List<Map<String, dynamic>> documents,
  });
  Future<Map<String, dynamic>?> scorePreauth(int preauthId);
  Future<Map<String, dynamic>?> preflightCheckPreauth(int preauthId);
  Future<Map<String, dynamic>?> getPreauthReport(int preauthId);
  Future<List<dynamic>?> getPatientPreauths(int patientId);
  Future<List<dynamic>?> getClaims();
  Future<List<dynamic>?> getPreauths();
}

class PatientRepository implements IPatientRepository {
  final Dio _dio = ApiClient.createDio();

  final Dio _dioForGetClaimReport = ApiClient.createDio(
    connectTimeout: const Duration(minutes: 10),
    receiveTimeout: const Duration(minutes: 10),
  );

  Options _getOptions() {
    final baseUrl = AppConfig.baseUrl;
    _dio.options.baseUrl = baseUrl;
    _dioForGetClaimReport.options.baseUrl = baseUrl;
    final token = StorageService.getToken();

    AppLogger.printData("Token ", token ?? "");

    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  @override
  Future<List<Patient>> getPatients({String? search}) async {
    try {
      final response = await _dio.get(
        '/api/v1/patients/',
        queryParameters: search != null && search.isNotEmpty
            ? {'search': search}
            : null,
        options: _getOptions(),
      );

      AppLogger.printData("getPatients status", response.statusCode.toString());

      if (response.statusCode == 200) {
        AppLogger.printData("getPatients data", response.toString());

        final List data = response.data;
        return data.map((json) => Patient.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.printData("getPatients error", e.toString());
      return [];
    }
  }

  @override
  Future<Patient?> addPatient(Patient patient) async {
    try {
      final response = await _dio.post(
        '/api/v1/patients/',
        data: patient.toJson(),
        options: _getOptions(),
      );

      AppLogger.printData("addPatient status", response.statusCode.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Patient.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.printData("addPatient error", e.toString());
      rethrow;
    }
  }

  @override
  Future<bool> deletePatient(String id) async {
    // Note: The backend api doesn't currently support patient deletion.
    // We will return true to allow UI-level mock deletion/removal for stability.
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<Patient?> getPatientById(String id) async {
    try {
      final response = await _dio.get(
        '/api/v1/patients/$id',
        options: _getOptions(),
      );

      AppLogger.printData(
        "getPatientById status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200) {
        AppLogger.printData("getPatientById data", response.toString());
        return Patient.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.printData("getPatientById error", e.toString());
      return null;
    }
  }

  @override
  Future<Patient?> getPatientByPMJY(String pmjyNumber) async {
    try {
      final response = await _dio.get(
        '/api/v1/patients/pmjay/$pmjyNumber',
        options: _getOptions(),
      );

      AppLogger.printData(
        "getPatientByPMJY status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200) {
        AppLogger.printData("getPatientByPMJY data", response.toString());
        return Patient.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.printData("getPatientByPMJY error", e.toString());
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getFormSchema(
    String code,
    int patientId, {
    String? stage,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/packages/$code/form-schema',
        queryParameters: {
          'patient_id': patientId,
          if (stage != null) 'stage': stage,
        },
        options: _getOptions(),
      );

      AppLogger.printData(
        "getFormSchema status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200) {
        AppLogger.printData("getFormSchema data", response.toString());

        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.printData("getFormSchema error", e.toString());
      return null;
    }
  }

  @override
  Future<List<PackageModel>> getPackages() async {
    try {
      final response = await _dio.get(
        '/api/v1/packages',
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
  Future<String?> extractFields(
    String packageCode,
    List<Map<String, dynamic>> files,
  ) async {
    try {
      final List<MultipartFile> multipartFiles = [];
      for (var f in files) {
        final String name = f['name'] ?? 'file';
        final List<int> bytes = f['bytes'] as List<int>;
        multipartFiles.add(MultipartFile.fromBytes(bytes, filename: name));
      }

      final formData = FormData.fromMap({
        'package_code': packageCode,
        'files': multipartFiles,
      });

      final response = await _dio.post(
        '/api/v1/claims/extract-fields',
        data: formData,
        options: _getOptions(),
      );

      AppLogger.printData(
        "extractFields status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.printData("extractFields data", response.data.toString());

        if (response.data is Map || response.data is List) {
          final encoder = const JsonEncoder.withIndent('  ');
          return encoder.convert(response.data);
        } else {
          return response.data?.toString();
        }
      }
      return null;
    } catch (e) {
      AppLogger.printData("extractFields error", e.toString());
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> submitClaim({
    required int patientId,
    required String packageCode,
    required String hospitalId,
    required String admissionDate,
    required String dischargeDate,
    required List<Map<String, dynamic>> documents,
    int? preauthId,
  }) async {
    AppLogger.printData("submitClaim documents", documents.toString());

    try {
      final response = await _dio.post(
        '/api/v1/claims/',
        data: {
          'patient_id': patientId,
          'package_code': packageCode,
          'hospital_id': hospitalId,
          'admission_date': admissionDate,
          'discharge_date': dischargeDate,
          'documents': documents,
          if (preauthId != null) 'preauth_id': preauthId,
        },
        options: _getOptions(),
      );

      AppLogger.printData("submitClaim status", response.statusCode.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.printData("submitClaim data", response.data.toString());
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.printData("submitClaim error", e.toString());
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> scoreClaim(int claimId) async {
    try {
      final response = await _dioForGetClaimReport.post(
        '/api/v1/claims/$claimId/score',
        options: _getOptions(),
      );

      AppLogger.printData("scoreClaim status", response.statusCode.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.printData("scoreClaim data", response.data.toString());
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.printData("scoreClaim error", e.toString());
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> preflightCheck(int claimId) async {
    try {
      final response = await _dio.get(
        '/api/v1/claims/$claimId/preflight',
        options: _getOptions(),
      );

      AppLogger.printData(
        "preflightCheck status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200) {
        AppLogger.printData("preflightCheck data", response.data.toString());
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.printData("preflightCheck error", e.toString());
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getClaimReport(int claimId) async {
    try {
      final response = await _dioForGetClaimReport.get(
        '/api/v1/claims/$claimId/report',
        options: _getOptions(),
      );

      AppLogger.printData(
        "getClaimReport status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200) {
        AppLogger.printData("getClaimReport data", response.data.toString());
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.printData("getClaimReport error", e.toString());
      rethrow;
    }
  }

  @override
  Future<List<dynamic>?> getPatientClaims(int patientId) async {
    try {
      final response = await _dio.get(
        '/api/v1/claims/patient/$patientId',
        options: _getOptions(),
      );

      AppLogger.printData(
        "getPatientClaims status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200) {
        AppLogger.printData("getPatientClaims data", response.data.toString());
        if (response.data is List) {
          return response.data as List<dynamic>;
        } else if (response.data is Map && response.data['results'] != null) {
          return response.data['results'] as List<dynamic>;
        }
        return [response.data];
      }
      return null;
    } catch (e) {
      AppLogger.printData("getPatientClaims error", e.toString());
      rethrow;
    }
  }

  @override
  Future<List<PackageWeight>> getPackageWeights(String code) async {
    try {
      final response = await _dio.get(
        '/api/v1/packages/$code/weights',
        options: _getOptions(),
      );

      if (response.statusCode == 200) {
        final List weightsData = response.data['weights'] ?? [];
        return weightsData.map((json) => PackageWeight.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.printData("getPackageWeights error", e.toString());
      return [];
    }
  }

  @override
  Future<bool> updatePackageWeights(
    String code,
    PackageWeightsUpdate update,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/packages/$code/weights',
        data: update.toJson(),
        options: _getOptions(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      AppLogger.printData("updatePackageWeights error", e.toString());
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> submitPreauth({
    required int patientId,
    required String packageCode,
    required String hospitalId,
    required String admissionDate,
    required List<Map<String, dynamic>> documents,
  }) async {
    AppLogger.printData("submitPreauth documents", documents.toString());

    try {
      final response = await _dio.post(
        '/api/v1/claims/preauth',
        data: {
          'patient_id': patientId,
          'package_code': packageCode,
          'hospital_id': hospitalId,
          'admission_date': admissionDate,
          'documents': documents,
        },
        options: _getOptions(),
      );

      AppLogger.printData(
        "submitPreauth status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.printData("submitPreauth data", response.data.toString());
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.printData("submitPreauth error", e.toString());
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> scorePreauth(int preauthId) async {
    try {
      final response = await _dioForGetClaimReport.post(
        '/api/v1/claims/preauth/$preauthId/score',
        options: _getOptions(),
      );

      AppLogger.printData(
        "scorePreauth status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.printData("scorePreauth data", response.data.toString());
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.printData("scorePreauth error", e.toString());
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> preflightCheckPreauth(int preauthId) async {
    try {
      final response = await _dio.get(
        '/api/v1/claims/preauth/$preauthId/preflight',
        options: _getOptions(),
      );

      AppLogger.printData(
        "preflightCheckPreauth status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200) {
        AppLogger.printData(
          "preflightCheckPreauth data",
          response.data.toString(),
        );
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.printData("preflightCheckPreauth error", e.toString());
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getPreauthReport(int preauthId) async {
    try {
      final response = await _dioForGetClaimReport.get(
        '/api/v1/claims/preauth/$preauthId/report',
        options: _getOptions(),
      );

      AppLogger.printData(
        "getPreauthReport status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200) {
        AppLogger.printData("getPreauthReport data", response.data.toString());
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.printData("getPreauthReport error", e.toString());
      rethrow;
    }
  }

  @override
  Future<List<dynamic>?> getPatientPreauths(int patientId) async {
    try {
      final response = await _dio.get(
        '/api/v1/claims/patient/$patientId/preauths',
        options: _getOptions(),
      );

      AppLogger.printData(
        "getPatientPreauths status",
        response.statusCode.toString(),
      );

      if (response.statusCode == 200) {
        AppLogger.printData(
          "getPatientPreauths data",
          response.data.toString(),
        );
        if (response.data is List) {
          return response.data as List<dynamic>;
        } else if (response.data is Map && response.data['results'] != null) {
          return response.data['results'] as List<dynamic>;
        }
        return [response.data];
      }
      return null;
    } catch (e) {
      AppLogger.printData("getPatientPreauths error", e.toString());
      rethrow;
    }
  }

  @override
  Future<List<dynamic>?> getClaims() async {
    try {
      final response = await _dio.get(
        '/api/v1/claims/',
        options: _getOptions(),
      );

      AppLogger.printData("getClaims status", response.statusCode.toString());

      if (response.statusCode == 200) {
        AppLogger.printData("getClaims data", response.toString());
        if (response.data is List) {
          return response.data as List<dynamic>;
        } else if (response.data is Map && response.data['results'] != null) {
          return response.data['results'] as List<dynamic>;
        }
        return [response.data];
      }
      return null;
    } catch (e) {
      AppLogger.printData("getClaims error", e.toString());
      rethrow;
    }
  }

  @override
  Future<List<dynamic>?> getPreauths() async {
    try {
      final response = await _dio.get(
        '/api/v1/claims/preauth',
        options: _getOptions(),
      );

      AppLogger.printData("getPreauths status", response.statusCode.toString());

      if (response.statusCode == 200) {
        AppLogger.printData("getPreauths data", response.toString());
        if (response.data is List) {
          return response.data as List<dynamic>;
        } else if (response.data is Map && response.data['results'] != null) {
          return response.data['results'] as List<dynamic>;
        }
        return [response.data];
      }
      return null;
    } catch (e) {
      AppLogger.printData("getPreauths error", e.toString());
      rethrow;
    }
  }
}
