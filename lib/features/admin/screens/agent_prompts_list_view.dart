import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin_controller.dart';
import '../agent_prompt_model.dart';
import '../../../core/theme/app_colors.dart';

class AgentPromptsListView extends StatefulWidget {
  const AgentPromptsListView({super.key});

  @override
  State<AgentPromptsListView> createState() => _AgentPromptsListViewState();
}

class _AgentPromptsListViewState extends State<AgentPromptsListView> {
  final AdminController controller = Get.find<AdminController>();

  @override
  void initState() {
    super.initState();
    controller.fetchAgentPrompts();
  }

  void _showEditPromptDialog(AgentPrompt prompt) {
    final formKey = GlobalKey<FormState>();
    final promptController = TextEditingController(text: prompt.systemPrompt);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
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
                          child: const Icon(Icons.psychology_rounded, color: AppColors.primaryAccent),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Edit ${prompt.agentName} Prompt',
                          style: const TextStyle(
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
                const Text(
                  'System Prompt',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: promptController,
                  maxLines: 12,
                  minLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Enter agent system prompt instructions...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Prompt cannot be empty' : null,
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
                          await controller.updateAgentPrompt(
                            prompt.agentName,
                            promptController.text.trim(),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoadingPrompts.value && controller.agentPrompts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.agentPrompts.isEmpty) {
          return _buildEmptyState();
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.agentPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = controller.agentPrompts[index];
                    return _buildPromptCard(prompt);
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryHeader() {
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
              const Text(
                'AI Agent System Prompts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure core instructions and rules for the scoring agents. Total Agents: ${controller.agentPrompts.length}',
                style: const TextStyle(color: AppColors.darkGrey, fontSize: 13),
              ),
            ],
          ),
          const Icon(
            Icons.psychology_outlined,
            size: 40,
            color: AppColors.primaryAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard(AgentPrompt prompt) {
    String formattedTime = prompt.updatedAt;
    if (formattedTime.length > 19) {
      formattedTime = formattedTime.substring(0, 19).replaceAll('T', ' ');
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditPromptDialog(prompt),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_outlined, color: AppColors.primaryAccent, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          prompt.agentName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        Text(
                          'Updated: $formattedTime',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.darkGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lightGrey),
                      ),
                      child: Text(
                        prompt.systemPrompt,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.dark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Center(
                child: Icon(Icons.chevron_right_rounded, color: AppColors.darkGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_alt_outlined,
              size: 80,
              color: AppColors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No agent prompts configured',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.darkGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Once prompts are created in the database, they will appear here for customization.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.darkGrey),
            ),
          ],
        ),
      ),
    );
  }
}
