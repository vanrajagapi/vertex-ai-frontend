import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../patients/patient_repository.dart';

class AiAnalysisResultScreen extends StatefulWidget {
  final int? claimId;
  final int? preauthId;
  const AiAnalysisResultScreen({super.key, this.claimId, this.preauthId});

  @override
  State<AiAnalysisResultScreen> createState() => _AiAnalysisResultScreenState();
}

class _AiAnalysisResultScreenState extends State<AiAnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _scores = [];
  int _calculatedScore = 0;
  String _verdict = 'REVIEW';
  String? _verdictLabel;
  List<String> _missingDocuments = [];
  List<String> _identityMismatches = [];
  List<String> _recommendations = [];
  List<Map<String, dynamic>> _flags = [];

  bool _preflightFailed = false;
  List<String> _missingMandatory = [];
  List<String> _missingOptional = [];
  List<Map<String, dynamic>> _preflightFields = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    if (widget.claimId != null || widget.preauthId != null) {
      _fetchClaimScore();
    } else {
      // Fallback/mock mode if no claimId is provided
      _scores = [
        {'module': 'Identity Check', 'score': 90},
        {'module': 'Package Compliance', 'score': 80},
        {'module': 'Document Completeness', 'score': 85},
        {'module': 'Clinical Relevance', 'score': 75},
        {'module': 'Lab / Image Validation', 'score': 70},
      ];
      _calculatedScore = 80;
      _verdict = 'REVIEW';
      _verdictLabel = 'Requires Manual Review';
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          _animationController.forward();
        }
      });
    }
  }

  int _parseScore(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed.round();
      }
    }
    return 0;
  }

  Future<void> _fetchClaimScore() async {
    try {
      final patientRepository = PatientRepository();
      final isPreauth = widget.preauthId != null;

      // First, try to fetch an existing report to avoid redundant slow scoring
      Map<String, dynamic>? report;
      try {
        if (isPreauth) {
          report = await patientRepository.getPreauthReport(widget.preauthId!);
        } else {
          report = await patientRepository.getClaimReport(widget.claimId!);
        }
      } catch (e) {
        // If GET /report fails (e.g., not yet scored), proceed to scoring flow
        AppLogger.printData(
          isPreauth
              ? "getPreauthReport error/not found, proceeding to score"
              : "getClaimReport error/not found, proceeding to score",
          e.toString(),
        );
      }

      if (report == null) {
        // Step 2: Call Preflight Check
        final preflight = isPreauth
            ? await patientRepository.preflightCheckPreauth(widget.preauthId!)
            : await patientRepository.preflightCheck(widget.claimId!);
        if (preflight == null) {
          throw Exception('Failed to load preflight check from server.');
        }

        final isReady = preflight['ready'] ?? false;

        if (!isReady) {
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
            _preflightFailed = true;

            final List missingM = preflight['missing_mandatory'] ?? [];
            _missingMandatory = missingM.map((e) => e.toString()).toList();

            final List missingO = preflight['missing_optional'] ?? [];
            _missingOptional = missingO.map((e) => e.toString()).toList();

            final List fields = preflight['fields'] ?? [];
            _preflightFields = fields.map((f) {
              return {
                'field_key': f['field_key'] ?? '',
                'label': f['label'] ?? '',
                'mandatory': f['mandatory'] ?? false,
                'provided': f['provided'] ?? false,
                'status': f['status'] ?? 'missing',
              };
            }).toList();
          });
          _animationController.forward();
          return;
        }

        // Step 3: Call Score
        report = isPreauth
            ? await patientRepository.scorePreauth(widget.preauthId!)
            : await patientRepository.scoreClaim(widget.claimId!);
        if (report == null) {
          throw Exception('Failed to load score report from server.');
        }
      } else {}

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _preflightFailed = false;

        final List modules = report!['module_scores'] ?? [];
        _scores = modules.map((m) {
          return {
            'module': m['module'] ?? 'Unknown',
            'score': _parseScore(m['raw_score']),
          };
        }).toList();

        _calculatedScore = _parseScore(report['total_score']);
        _verdict = report['verdict'] ?? 'REVIEW';

        if (_verdict == 'PASS') {
          _verdictLabel = widget.preauthId != null
              ? 'Highly Confident - Preauth Pass'
              : 'Highly Confident - Claim Pass';
        } else if (_verdict == 'FAIL') {
          _verdictLabel = 'Rejected / Failed Policies';
        } else {
          _verdictLabel = 'Requires Manual Review';
        }

        final List missing = report['missing_documents'] ?? [];
        _missingDocuments = missing.map((e) => e.toString()).toList();

        final List identity = report['identity_mismatches'] ?? [];
        _identityMismatches = identity.map((e) => e.toString()).toList();

        final List recs = report['recommendations'] ?? [];
        _recommendations = recs.map((e) => e.toString()).toList();

        final List rawFlags = report['all_flags'] ?? [];
        _flags = rawFlags.map((f) {
          return {
            'field': f['field'] ?? '',
            'severity': f['severity'] ?? 'LOW',
            'reason': f['reason'] ?? '',
            'affected_doc': f['affected_doc'] ?? '',
          };
        }).toList();
      });

      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getScoreColor(int score, {bool ignoreVerdict = false}) {
    if (!ignoreVerdict) {
      if (_verdict == 'PASS') return AppColors.success;
      if (_verdict == 'FAIL') return AppColors.error;
    }
    if (score >= 85) return AppColors.success;
    if (score >= 75) return AppColors.primary;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  int get _overallScore {
    if (widget.claimId != null) {
      return _calculatedScore;
    }
    if (_scores.isEmpty) return 0;
    final total = _scores.fold<int>(
      0,
      (sum, item) => sum + (item['score'] as int),
    );
    return (total / _scores.length).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Step 5 — AI Analysis Result',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryDark,
        elevation: 1,
      ),
      body: Center(
        child: _isProcessing
            ? _buildProcessingState()
            : (_errorMessage != null
                  ? _buildErrorState()
                  : (_preflightFailed
                        ? _buildPreflightFailedState()
                        : _buildResultsState())),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            color: AppColors.primary,
            backgroundColor: AppColors.lightGrey,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          widget.preauthId != null
              ? 'AI is analyzing the preauth documents...'
              : 'AI is analyzing the claim documents...',
          style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDark),
        ),
        const SizedBox(height: 8),
        Text(
          widget.preauthId != null
              ? 'Cross-referencing policies and verifying pre-authorization documents.'
              : 'Cross-referencing policies and verifying medical records.',
          style: const TextStyle(color: AppColors.darkGrey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          'Error loading claim analysis',
          style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDark),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.darkGrey, fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isProcessing = true;
              _errorMessage = null;
            });
            _fetchClaimScore();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildResultsState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOverallScoreCard(),
              const SizedBox(height: 24),
              _buildDetailedScoresCard(),
              _buildFlagsAndWarningsSection(),
              _buildRecommendationsSection(),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Final return to dashboard
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Complete Process',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallScoreCard() {
    final score = _overallScore;
    final color = _getScoreColor(score);
    final verdictLabel =
        _verdictLabel ??
        (score >= 80 ? 'Highly Confident' : 'Requires Manual Review');

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const Text(
                    '/ 100',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Confidence Score',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.preauthId != null
                      ? 'The AI has completed checking the documents against policy guidelines and past records. A higher score indicates a stronger probability of an authentic and compliant pre-authorization.'
                      : 'The AI has completed checking the documents against policy guidelines and past records. A higher score indicates a stronger probability of an authentic and compliant claim.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.darkGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    verdictLabel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedScoresCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Detailed Module Breakdown',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_scores.isEmpty)
            const Text(
              'No module scores returned.',
              style: TextStyle(color: AppColors.darkGrey),
            )
          else
            ..._scores
                .map((item) => _buildScoreRow(item['module'], item['score']))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String title, int score) {
    final color = _getScoreColor(score, ignoreVerdict: true);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$score/100',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: AppColors.lightGrey,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFlagsAndWarningsSection() {
    final List<Widget> warningWidgets = [];

    if (_identityMismatches.isNotEmpty) {
      warningWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identity Mismatches:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 6),
              ..._identityMismatches.map(
                (m) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        m,
                        style: const TextStyle(color: AppColors.dark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_missingDocuments.isNotEmpty) {
      warningWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Missing Documents:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 6),
              ..._missingDocuments.map(
                (doc) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        doc,
                        style: const TextStyle(color: AppColors.dark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_flags.isNotEmpty) {
      warningWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Policy & Verification Flags:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 8),
            ..._flags.map((flag) {
              final severity = flag['severity'] ?? 'LOW';
              final severityColor = severity == 'HIGH'
                  ? AppColors.error
                  : (severity == 'MEDIUM'
                        ? AppColors.warning
                        : AppColors.primary);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: severityColor.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.flag, color: severityColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Field: ${flag['field']} ($severity)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: severityColor,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            flag['reason'] ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (flag['affected_doc'] != null &&
                              flag['affected_doc'].toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Affected Document: ${flag['affected_doc']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    if (warningWidgets.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'Flags & Policy Violations',
      icon: Icons.warning_amber_outlined,
      iconColor: AppColors.warning,
      children: warningWidgets,
    );
  }

  Widget _buildRecommendationsSection() {
    if (_recommendations.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'AI Recommendations',
      icon: Icons.lightbulb_outline,
      iconColor: AppColors.success,
      children: _recommendations
          .map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPreflightFailedState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.cancel_outlined,
                      color: AppColors.error,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preflight Check Failed',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The claim cannot be submitted for scoring because one or more mandatory fields are missing or empty.',
                            style: TextStyle(
                              color: AppColors.primaryDark.withOpacity(0.8),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_missingMandatory.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.lightGrey.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Missing Mandatory Fields',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._missingMandatory.map(
                        (field) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_right,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                field,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.lightGrey.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Field Status Check',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FixedColumnWidth(90),
                        2: FixedColumnWidth(100),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.lightGrey),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Field Label / Key',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Mandatory',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        ..._preflightFields.map((field) {
                          final status = field['status'] as String;
                          Widget statusWidget;
                          if (status == 'ok') {
                            statusWidget = const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'OK',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            );
                          } else if (status == 'empty') {
                            statusWidget = const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: AppColors.warning,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Empty',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            statusWidget = const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cancel,
                                  color: AppColors.error,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Missing',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            );
                          }

                          return TableRow(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.lightGrey,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      field['label'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      field['field_key'],
                                      style: const TextStyle(
                                        color: AppColors.darkGrey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  field['mandatory'] ? 'Yes' : 'No',
                                  style: TextStyle(
                                    fontWeight: field['mandatory']
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: field['mandatory']
                                        ? AppColors.error
                                        : AppColors.darkGrey,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: statusWidget,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Back to Upload',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Return to Dashboard',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
