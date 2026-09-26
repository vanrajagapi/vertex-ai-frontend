import 'package:claim_automate_checker/features/admin/admin_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_repository.dart';
import '../dashboard/dashboard_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/storage_service.dart';

class LoginController extends GetxController {
  final ILoginRepository repository;

  LoginController({required this.repository});

  final formKey = GlobalKey<FormState>();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool rememberMe = false.obs;

  @override
  void onClose() {
    userNameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void toggleObscurePassword() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  Future<void> login() async {
    // This will trigger the validation messages on the fields
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final success = await repository.login(
        userNameController.text.trim(),
        passwordController.text,
      );

      if (success) {
        final role = StorageService.getRole();

        Get.snackbar(
          'Login Successful!',
          'Welcome back to Claim Automate Checker',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );

        if (role == 'admin') {
          Get.offAll(() => const AdminShellScreen());
        } else {
          Get.offAll(() => const DashboardScreen());
        }
      } else {
        Get.snackbar(
          'Login Failed',
          'Invalid email or password. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
