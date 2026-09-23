import 'package:flutter/material.dart';

import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/project_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/connection_error_widget.dart';
import '../app_scaffold.dart';

class ProgressReportsScreen extends StatefulWidget {
  const ProgressReportsScreen({super.key});

  @override
  State<ProgressReportsScreen> createState() => _ProgressReportsScreenState();
}

class _ProgressReportsScreenState extends State<ProgressReportsScreen> {
  final _reportService = ReportService();
  final _projectService = ProjectService();
  String? _selectedProjectId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _reportService.refresh(),
      _projectService.refresh(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  List<ReportModel> get _filteredReports {
    var reports = _reportService.getAllReports();
    if (_selectedProjectId != null) {
      reports = reports.where((r) => r.projectId == _selectedProjectId).toList();
    }
    return reports;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Informes de Progreso',
        currentIndex: 6,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_reportService.connectionFailed) {
      return AppScaffold(
        title: 'Informes de Progreso',
        currentIndex: 6,
        body: ConnectionErrorWidget(
          onRetry: () {
            setState(() => _loading = true);
            _loadData();
          },
        ),
      );
    }

    final projects = _projectService.getAllProjects();
    final reports = _filteredReports;

    return AppScaffold(
      title: 'Informes de Progreso',
      currentIndex: 6,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateReportDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final count = constraints.maxWidth > 700 ? 3 : 1;
              final spacing = AppDimens.spaceMd;
              final w = (constraints.maxWidth - spacing * (count - 1)) / count;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: w,
                    child: MetricCard(
                      label: 'Total Informes',
                      value: '${_reportService.totalReports}',
                      icon: Icons.assessment,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: MetricCard(
                      label: 'Proyectos con Informes',
                      value: '${reports.map((r) => r.projectId).toSet().length}',
                      icon: Icons.folder_open,
                      color: AppColors.info,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: MetricCard(
                      label: 'Avance Promedio',
                      value: '${_averageDelta(reports).toStringAsFixed(0)}%',
                      icon: Icons.trending_up,
                      color: AppColors.success,
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: AppDimens.spaceXl),
            // Project filter
            const Text(
              'Filtrar por proyecto',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimens.spaceSm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', null),
                  const SizedBox(width: AppDimens.spaceSm),
                  ...projects.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AppDimens.spaceSm),
                      child: _buildFilterChip(
                        Helpers.truncate(p.title, 20),
                        p.id,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.spaceXl),
            if (reports.isEmpty)
              const EmptyState(
                icon: Icons.assessment,
                title: 'Sin informes',
                message: 'No se han generado informes todavía.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppDimens.spaceMd),
                itemBuilder: (_, i) {
                  final r = reports[i];
                  return Dismissible(
                    key: Key(r.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppDimens.radiusL),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      setState(() => _reportService.deleteReport(r.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Informe "${r.title}" eliminado'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    },
                    child: _buildReportCard(r),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  double _averageDelta(List<ReportModel> reports) {
    if (reports.isEmpty) return 0;
    final deltas = reports.map((r) => r.progressDelta).toList();
    return deltas.reduce((a, b) => a + b) / deltas.length;
  }

  Widget _buildFilterChip(String label, String? projectId) {
    final isSelected = _selectedProjectId == projectId;
    return GestureDetector(
      onTap: () => setState(() => _selectedProjectId = projectId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    final project = _projectService.getProjectById(report.projectId);
    final delta = report.progressDelta;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: const Icon(Icons.description, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppDimens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project?.title ?? 'Proyecto',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (delta >= 0 ? AppColors.success : AppColors.error).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: Text(
                  '${delta >= 0 ? '+' : ''}$delta%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: delta >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceMd),
          Text(
            report.summary,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.spaceLg),
          // Progress delta visualization
          Row(
            children: [
              Text(
                '${report.progressBefore}%',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(width: AppDimens.spaceSm),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: report.progressAfter / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.spaceSm),
              Text(
                '${report.progressAfter}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceLg),
          if (report.highlights.isNotEmpty) ...[
            _buildSection('Logros', report.highlights, AppColors.success, Icons.check_circle_outline),
            const SizedBox(height: AppDimens.spaceMd),
          ],
          if (report.challenges.isNotEmpty) ...[
            _buildSection('Desafíos', report.challenges, AppColors.warning, Icons.warning_amber),
            const SizedBox(height: AppDimens.spaceMd),
          ],
          if (report.nextSteps.isNotEmpty)
            _buildSection('Próximos Pasos', report.nextSteps, AppColors.info, Icons.arrow_forward),
          const SizedBox(height: AppDimens.spaceLg),
          Divider(color: AppColors.border),
          const SizedBox(height: AppDimens.spaceSm),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  Helpers.initialsFromName(report.authorName),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                report.authorName,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '${Helpers.formatDateShort(report.periodStart)} - ${Helpers.formatDateShort(report.periodEnd)}',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.spaceSm),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 22, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  void _showCreateReportDialog() {
    final projects = _projectService.getAllProjects();
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Primero crea un proyecto'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    final highlightsCtrl = TextEditingController();
    final challengesCtrl = TextEditingController();
    final nextStepsCtrl = TextEditingController();
    String selectedProjectId = projects.first.id;
    int progressBefore = 0;
    int progressAfter = 0;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo Informe'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedProjectId,
                        decoration: const InputDecoration(labelText: 'Proyecto'),
                        items: projects
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.title, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedProjectId = v!),
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Título del informe'),
                        validator: (v) => Validators.required(v, field: 'El título'),
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      TextFormField(
                        controller: summaryCtrl,
                        decoration: const InputDecoration(labelText: 'Resumen'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Progreso antes %'),
                              keyboardType: TextInputType.number,
                              initialValue: '0',
                              onChanged: (v) =>
                                  progressBefore = int.tryParse(v) ?? 0,
                            ),
                          ),
                          const SizedBox(width: AppDimens.spaceMd),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Progreso después %'),
                              keyboardType: TextInputType.number,
                              initialValue: '0',
                              onChanged: (v) =>
                                  progressAfter = int.tryParse(v) ?? 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      TextFormField(
                        controller: highlightsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Logros (uno por línea)',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      TextFormField(
                        controller: challengesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Desafíos (uno por línea)',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      TextFormField(
                        controller: nextStepsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Próximos pasos (uno por línea)',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final now = DateTime.now();
                    final report = ReportModel(
                      id: 'r${now.millisecondsSinceEpoch}',
                      projectId: selectedProjectId,
                      title: titleCtrl.text.trim(),
                      summary: summaryCtrl.text.trim(),
                      authorId: 'u1',
                      authorName: 'Dra. Elena Vargas',
                      progressBefore: progressBefore,
                      progressAfter: progressAfter,
                      highlights: _parseLines(highlightsCtrl.text),
                      challenges: _parseLines(challengesCtrl.text),
                      nextSteps: _parseLines(nextStepsCtrl.text),
                      periodStart: now.subtract(const Duration(days: 90)),
                      periodEnd: now,
                      createdAt: now,
                    );
                    _reportService.addReport(report);
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Informe "${report.title}" creado'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<String> _parseLines(String text) {
    return text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }
}
