import 'package:flutter/material.dart';

import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../models/notification_model.dart';
import '../../models/report_model.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/notification_service.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/project_card.dart';
import '../../widgets/task_card.dart';
import '../../widgets/notification_card.dart';
import '../../widgets/progress_chart.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/connection_error_widget.dart';
import '../../app/routes.dart';
import '../app_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _projectService = ProjectService();
  final _taskService = TaskService();
  final _notificationService = NotificationService();
  final _reportService = ReportService();
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
      _notificationService.refresh(),
      _reportService.refresh(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Panel',
        currentIndex: 0,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final connectionFailed = _projectService.connectionFailed ||
        _taskService.connectionFailed ||
        _notificationService.connectionFailed ||
        _reportService.connectionFailed;

    if (connectionFailed) {
      return AppScaffold(
        title: 'Panel',
        currentIndex: 0,
        body: ConnectionErrorWidget(
          onRetry: () {
            setState(() => _loading = true);
            _loadData();
          },
        ),
      );
    }

    final projects = _projectService.getAllProjects();
    final activeProjects = _projectService.getProjectsByStatus(ProjectStatus.active);
    final upcomingTasks = _taskService.getUpcomingTasks(days: 14);
    final recentNotifications = _notificationService.getAllNotifications().take(4).toList();
    final reports = _reportService.getAllReports();

    return AppScaffold(
      title: 'Panel',
      currentIndex: 0,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createProject),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Crear proyecto',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loading = true);
          await _loadData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: AppDimens.spaceLg),
              _buildMetricsRow(),
              const SizedBox(height: AppDimens.spaceXl),
              _buildSectionTitle('Progreso por Proyecto'),
              const SizedBox(height: AppDimens.spaceMd),
              _buildProgressChart(projects),
              const SizedBox(height: AppDimens.spaceXl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Proyectos Activos'),
                        const SizedBox(height: AppDimens.spaceMd),
                        _buildActiveProjects(activeProjects),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.spaceLg),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Próximas Tareas'),
                        const SizedBox(height: AppDimens.spaceMd),
                        _buildUpcomingTasks(upcomingTasks),
                        const SizedBox(height: AppDimens.spaceXl),
                        _buildSectionTitle('Actividad Reciente'),
                        const SizedBox(height: AppDimens.spaceMd),
                        _buildRecentNotifications(recentNotifications),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spaceXl),
              _buildSectionTitle('Informes Recientes'),
              const SizedBox(height: AppDimens.spaceMd),
              _buildRecentReports(reports),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final user = AuthService.instance.currentUser;
    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenida de vuelta',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? 'Usuario',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tienes ${_taskService.getTasksByAssignee(user?.id ?? '').where((t) => t.status != TaskStatus.done).length} tareas pendientes y ${_notificationService.unreadCount} notificaciones sin leer.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
            ),
            child: const Icon(Icons.science, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
      final spacing = AppDimens.spaceMd;
      final itemWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          SizedBox(
            width: itemWidth,
            child: MetricCard(
              label: 'Proyectos Activos',
              value: '${_projectService.activeProjects}',
              icon: Icons.folder_open,
              color: AppColors.primary,
              trend: '+2',
            ),
          ),
          SizedBox(
            width: itemWidth,
            child: MetricCard(
              label: 'Tareas Pendientes',
              value: '${_taskService.totalTasks - _taskService.completedTasks}',
              icon: Icons.checklist_rtl,
              color: AppColors.secondary,
              trend: '+5',
            ),
          ),
          SizedBox(
            width: itemWidth,
            child: MetricCard(
              label: 'Tareas Vencidas',
              value: '${_taskService.overdueCount}',
              icon: Icons.warning_amber,
              color: AppColors.error,
              trend: '-1',
              trendUp: false,
            ),
          ),
          SizedBox(
            width: itemWidth,
            child: MetricCard(
              label: 'Progreso Promedio',
              value: '${_projectService.averageProgress.toStringAsFixed(0)}%',
              icon: Icons.insights,
              color: AppColors.success,
              trend: '+8%',
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildProgressChart(List<ProjectModel> projects) {
    if (projects.isEmpty) {
      return const EmptyState(icon: Icons.bar_chart, title: 'Sin datos de progreso');
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      child: ProgressChart(
        labels: projects.map((p) => Helpers.truncate(p.title, 12)).toList(),
        values: projects.map((p) => p.progress.toDouble()).toList(),
      ),
    );
  }

  Widget _buildActiveProjects(List<ProjectModel> projects) {
    if (projects.isEmpty) {
      return const EmptyState(icon: Icons.folder_off, title: 'Sin proyectos activos');
    }
    return Column(
      children: projects.take(3).map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.spaceMd),
          child: ProjectCard(
            project: p,
            memberCount: p.memberIds.length,
            taskCount: _taskService.getTasksForProject(p.id).length,
            onTap: () => Navigator.pushNamed(
              context,
              '/projects/workspace',
              arguments: p.id,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUpcomingTasks(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const EmptyState(icon: Icons.event_available, title: 'Sin tareas próximas');
    }
    return Column(
      children: tasks.take(4).map((t) {
        final project = _projectService.getProjectById(t.projectId);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.spaceSm),
          child: TaskCard(
            task: t,
            projectTitle: project?.title,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentNotifications(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return const EmptyState(icon: Icons.notifications_off, title: 'Sin notificaciones');
    }
    return Column(
      children: notifications.map((n) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.spaceSm),
          child: NotificationCard(notification: n),
        );
      }).toList(),
    );
  }

  Widget _buildRecentReports(List<ReportModel> reports) {
    if (reports.isEmpty) {
      return const EmptyState(icon: Icons.assessment, title: 'Sin informes');
    }
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimens.spaceMd),
        itemBuilder: (_, i) {
          final r = reports[i];
          return Container(
            width: 280,
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
                    Icon(Icons.description, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.summary,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      r.authorName,
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const Spacer(),
                    Text(
                      Helpers.timeAgo(r.createdAt),
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
