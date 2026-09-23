import 'package:flutter/material.dart';

import '../../models/document_model.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/document_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/progress_chart.dart';
import '../../widgets/budget_chart.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/connection_error_widget.dart';
import '../app_scaffold.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _projectService = ProjectService();
  final _taskService = TaskService();
  final _documentService = DocumentService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _projectService.refresh(),
      _taskService.refresh(),
      _documentService.refresh(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Analíticas',
        currentIndex: 7,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final connectionFailed = _projectService.connectionFailed ||
        _taskService.connectionFailed ||
        _documentService.connectionFailed;

    if (connectionFailed) {
      return AppScaffold(
        title: 'Analíticas',
        currentIndex: 7,
        body: ConnectionErrorWidget(
          onRetry: () {
            setState(() => _loading = true);
            _loadData();
          },
        ),
      );
    }

    final projects = _projectService.getAllProjects();
    final totalBudget = _projectService.totalBudget;
    final totalSpent = _projectService.totalSpent;

    return AppScaffold(
      title: 'Analíticas',
      currentIndex: 7,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top metrics
            LayoutBuilder(builder: (context, constraints) {
              final count = constraints.maxWidth > 800 ? 4 : 2;
              final spacing = AppDimens.spaceMd;
              final w = (constraints.maxWidth - spacing * (count - 1)) / count;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: w,
                    child: MetricCard(
                      label: 'Progreso Promedio',
                      value: '${_projectService.averageProgress.toStringAsFixed(0)}%',
                      icon: Icons.insights,
                      color: AppColors.primary,
                      trend: '+8%',
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: MetricCard(
                      label: 'Tareas Completadas',
                      value: '${_taskService.completedTasks}/${_taskService.totalTasks}',
                      icon: Icons.task_alt,
                      color: AppColors.success,
                      trend: '${_taskService.completionRate.toStringAsFixed(0)}%',
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: MetricCard(
                      label: 'Presupuesto Total',
                      value: Helpers.formatCurrency(totalBudget),
                      icon: Icons.account_balance_wallet,
                      color: AppColors.info,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: MetricCard(
                      label: 'Utilización',
                      value: Helpers.formatPercent(
                        totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0,
                      ),
                      icon: Icons.pie_chart,
                      color: AppColors.warning,
                      trend: totalSpent > totalBudget * 0.8 ? 'Alto' : 'Normal',
                      trendUp: totalSpent <= totalBudget * 0.8,
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: AppDimens.spaceXl),
            // Progress by project
            const Text(
              'Progreso por Proyecto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimens.spaceMd),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(AppDimens.spaceLg),
              child: ProgressChart(
                labels: projects.map((p) => Helpers.truncate(p.title, 10)).toList(),
                values: projects.map((p) => p.progress.toDouble()).toList(),
                maxHeight: 240,
              ),
            ),
            const SizedBox(height: AppDimens.spaceXl),
            // Budget vs Spent
            const Text(
              'Presupuesto vs. Gasto por Proyecto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimens.spaceMd),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(AppDimens.spaceLg),
              child: BudgetChart(
                labels: projects.map((p) => Helpers.truncate(p.title, 8)).toList(),
                budgetValues: projects.map((p) => p.budget).toList(),
                spentValues: projects.map((p) => p.spent).toList(),
                maxHeight: 260,
              ),
            ),
            const SizedBox(height: AppDimens.spaceXl),
            // Task distribution
            const Text(
              'Distribución de Tareas por Estado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimens.spaceMd),
            _buildTaskDistribution(),
            const SizedBox(height: AppDimens.spaceXl),
            // Documents by type
            const Text(
              'Documentos por Tipo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimens.spaceMd),
            _buildDocumentTypeBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDistribution() {
    final statuses = <(String, TaskStatus, Color)>[
      ('Por Hacer', TaskStatus.todo, AppColors.textMuted),
      ('En Progreso', TaskStatus.inProgress, AppColors.info),
      ('En Revisión', TaskStatus.review, AppColors.warning),
      ('Completadas', TaskStatus.done, AppColors.success),
    ];

    final allTasks = _taskService.getAllTasks();
    final counts = statuses.map((s) {
      final count = allTasks.where((t) => t.status == s.$2).length;
      return (s.$1, count, s.$3);
    }).toList();

    final maxCount = counts.map((c) => c.$2).reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) {
      return const EmptyState(icon: Icons.bar_chart, title: 'Sin datos de tareas');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      child: Column(
        children: counts.map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.spaceMd),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    c.$1,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: AppDimens.spaceSm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: c.$2 / maxCount,
                      minHeight: 20,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(c.$3),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.spaceSm),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${c.$2}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDocumentTypeBreakdown() {
    final allDocs = _documentService.getAllDocuments();
    if (allDocs.isEmpty) {
      return const EmptyState(icon: Icons.folder_off, title: 'Sin documentos');
    }

    final typeCounts = <String, int>{};
    for (final doc in allDocs) {
      final label = doc.type.label;
      typeCounts[label] = (typeCounts[label] ?? 0) + 1;
    }

    final entries = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = entries.first.value;
    final colors = AppColors.chartPalette;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      child: Column(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          final color = colors[i % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.spaceMd),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppDimens.spaceSm),
                SizedBox(
                  width: 100,
                  child: Text(
                    e.key,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: AppDimens.spaceSm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: e.value / maxCount,
                      minHeight: 20,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.spaceSm),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${e.value}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
