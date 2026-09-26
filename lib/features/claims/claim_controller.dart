import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../patients/patient_model.dart';
import '../patients/patient_repository.dart';
import '../patients/patient_controller.dart';
import '../dashboard/dashboard_controller.dart';
import '../../core/theme/app_colors.dart';
import 'select_package_screen.dart';

class ClaimController extends GetxController {
  final IPatientRepository patientRepository;

  ClaimController({required this.patientRepository});

  final formKey = GlobalKey<FormState>();

  // Patient Details
  final patientNameController = TextEditingController();
  final ageController = TextEditingController();
  final beneficiaryIdController = TextEditingController();
  final doctorNameController = TextEditingController();

  final mobileNumberController = TextEditingController();
  final selectedTitle = 'Mr'.obs;
  final gender = RxnString('Male');
  final dateOfBirth = Rxn<DateTime>();

  @override
  void onClose() {
    patientNameController.dispose();
    ageController.dispose();
    beneficiaryIdController.dispose();
    mobileNumberController.dispose();
    super.onClose();
  }

  void setTitle(String? value) {
    if (value != null) {
      selectedTitle.value = value;
      if (value == 'Mr') {
        gender.value = 'Male';
      } else if (value == 'Miss' || value == 'Mrs') {
        gender.value = 'Female';
      }
    }
  }

  void setGender(String? value) => gender.value = value;

  void setDateOfBirth(DateTime date) {
    dateOfBirth.value = date;
    calculateAge(date);
  }

  void calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    ageController.text = age.toString();
  }

  Future<void> savePatient() async {
    if (!formKey.currentState!.validate()) return;

    if (dateOfBirth.value == null) {
      Get.snackbar(
        'Validation Error',
        'Date of Birth is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    final patient = Patient(
      id: '',
      name: '${selectedTitle.value}. ${patientNameController.text.trim().toUpperCase()}',
      age: ageController.text,
      gender: gender.value ?? 'Unknown',
      contact: mobileNumberController.text,
      email: '', // Not in form
      address: '', // Not in form
      pmjayNumber: beneficiaryIdController.text.trim(),
      dob: dateOfBirth.value != null
          ? "${dateOfBirth.value!.year}-${dateOfBirth.value!.month.toString().padLeft(2, '0')}-${dateOfBirth.value!.day.toString().padLeft(2, '0')}"
          : '',
    );

    try {
      await patientRepository.addPatient(patient);

      Get.back(); // Pop registration screen

      // Refresh patient list from the API
      if (Get.isRegistered<PatientController>()) {
        await Get.find<PatientController>().fetchPatients();
      }

      // Switch active screen to Patient List Screen (Index 1)
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().changeIndex(1);
      }

      Get.snackbar(
        'Success',
        'Patient saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save patient: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> saveAndStartClaim() async {
    if (!formKey.currentState!.validate()) return;

    if (dateOfBirth.value == null) {
      Get.snackbar(
        'Validation Error',
        'Date of Birth is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    final patient = Patient(
      id: '',
      name: '${selectedTitle.value}. ${patientNameController.text.trim().toUpperCase()}',
      age: ageController.text,
      gender: gender.value ?? 'Unknown',
      contact: mobileNumberController.text,
      email: '',
      address: '',
      pmjayNumber: beneficiaryIdController.text.trim(),
      dob: dateOfBirth.value != null
          ? "${dateOfBirth.value!.year}-${dateOfBirth.value!.month.toString().padLeft(2, '0')}-${dateOfBirth.value!.day.toString().padLeft(2, '0')}"
          : '',
    );

    try {
      final savedPatient = await patientRepository.addPatient(patient);

      if (savedPatient != null) {
        Get.back(); // Pop registration screen

        // Refresh patient list from the API
        if (Get.isRegistered<PatientController>()) {
          await Get.find<PatientController>().fetchPatients();
        }

        // Switch active screen to Patient List Screen (Index 1)
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().changeIndex(1);
        }

        // Route instantly to Package Selector for this Patient
        Get.to(() => SelectPackageScreen(patient: savedPatient));
      } else {
        Get.snackbar(
          'Error',
          'Failed to start claim: Patient could not be saved',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save patient: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
}
