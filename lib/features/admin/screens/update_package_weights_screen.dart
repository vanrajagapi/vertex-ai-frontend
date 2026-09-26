import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin_controller.dart';
import '../package_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';

class UpdatePackageWeightsScreen extends StatefulWidget {
  final PackageModel package;
  const UpdatePackageWeightsScreen({super.key, required this.package});

  @override
  State<UpdatePackageWeightsScreen> createState() =>
      _UpdatePackageWeightsScreenState();
}

class _UpdatePackageWeightsScreenState
    extends State<UpdatePackageWeightsScreen> {
  final List<PackageWeight> _weights = [];
  String? _selectedAgentName;
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWeights();
    Get.find<AdminController>().fetchAgentScoringNames();
  }

  Future<void> _loadWeights() async {
    final controller = Get.find<AdminController>();
    final weights = await controller.fetchPackageWeights(widget.package.code);
    setState(() {
      _weights.addAll(
        weights.map(
          (w) => PackageWeight(agentName: w.agentName, weight: w.weight * 100),
        ),
      );
    });
  }

  void _addWeight() {
    if (_selectedAgentName != null &&
        _weightController.text.isNotEmpty) {
      final inputWeight = double.tryParse(_weightController.text);

      double currentTotal = _weights.fold(
        0.0,
        (sum, item) => sum + item.weight,
      );
      double maxAllowed = 100.0 - currentTotal;

      if (maxAllowed < 1) {
        Get.snackbar(
          'Limit Reached',
          'Total weight is already 100. Please remove existing weights first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }

      if (inputWeight == null || inputWeight < 1 || inputWeight > maxAllowed) {
        Get.snackbar(
          'Invalid Input',
          'Weight must be between 1 and ${maxAllowed.toInt()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }

      setState(() {
        _weights.add(
          PackageWeight(
            agentName: _selectedAgentName!,
            weight: inputWeight,
          ),
        );
        _selectedAgentName = null;
        _weightController.clear();
      });
    }
  }

  void _removeWeight(int index) {
    setState(() {
      _weights.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Package Weights: ${widget.package.code}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Agent Weight',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Obx(() {
                    if (controller.isLoadingAgents.value) {
                      return const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    
                    // Filter out already added agents
                    final addedAgents = _weights.map((w) => w.agentName).toSet();
                    final availableAgents = controller.agentScoringNames
                        .where((name) => !addedAgents.contains(name))
                        .toList();

                    // If _selectedAgentName is not in availableAgents, reset it to null
                    if (_selectedAgentName != null && !availableAgents.contains(_selectedAgentName)) {
                      _selectedAgentName = null;
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedAgentName,
                      hint: const Text('Select Agent'),
                      decoration: InputDecoration(
                        labelText: 'Agent Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      ),
                      items: availableAgents.map((name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedAgentName = val;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addWeight,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Current Weights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingWeights.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_weights.isEmpty) {
                  return Center(
                    child: Text(
                      'No weights added yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: _weights.length,
                  itemBuilder: (context, index) {
                    final w = _weights[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          w.agentName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              w.weight.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _removeWeight(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value || _weights.isEmpty
                      ? null
                      : () {
                          double currentTotal = _weights.fold(0.0, (sum, item) => sum + item.weight);
                          if ((currentTotal - 100.0).abs() > 0.001) {
                            Get.snackbar(
                              'Error',
                              'Total weight must be exactly 100',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.error,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          final scaledWeights = _weights
                              .map(
                                (w) => PackageWeight(
                                  agentName: w.agentName,
                                  weight: w.weight / 100,
                                ),
                              )
                              .toList();
                          final update = PackageWeightsUpdate(
                            weights: scaledWeights,
                            updatedBy: StorageService.getRole() ?? 'admin',
                          );
                          controller.updatePackageWeights(
                            widget.package.code,
                            update,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update All Weights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
