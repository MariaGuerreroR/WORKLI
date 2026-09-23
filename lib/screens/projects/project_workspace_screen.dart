import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../models/document_model.dart';
import '../../models/report_model.dart';
import '../../models/objective_model.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/document_service.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/task_card.dart';
import '../../widgets/document_card.dart';
import '../../widgets/budget_chart.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/connection_error_widget.dart';
import '../app_scaffold.dart';

class ProjectWorkspaceScreen extends StatefulWidget {
  final String projectId;

  const ProjectWorkspaceScreen({super.key, required this.projectId});

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  final _projectService = ProjectService();
  final _taskService = TaskService();
  final _documentService = DocumentService();
  final _reportService = ReportService();

  late TabController _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _projectService.refresh(),
      _taskService.refresh(),
      _documentService.refresh(),
      _reportService.refresh(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Proyecto',
        currentIndex: 1,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final connectionFailed = _projectService.connectionFailed ||
        _taskService.connectionFailed ||
        _documentService.connectionFailed ||
        _reportService.connectionFailed;

    if (connectionFailed) {
      return AppScaffold(
        title: 'Proyecto',
        currentIndex: 1,
        body: ConnectionErrorWidget(
          onRetry: () {
            setState(() => _loading = true);
            _loadData();
          },
        ),
      );
    }

    final project = _projectService.getProjectById(widget.projectId);

    if (project == null) {
      return AppScaffold(
        title: 'Proyecto no encontrado',
        currentIndex: 1,
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Proyecto no encontrado',
          message: 'El proyecto que buscas no existe o fue eliminado.',
        ),
      );
    }

    final tasks = _taskService.getTasksForProject(project.id);
    final documents = _documentService.getDocumentsForProject(project.id);
    final objectives = _projectService.getObjectivesForProject(project.id);
    final reports = _reportService.getReportsForProject(project.id);

    return AppScaffold(
      title: Helpers.truncate(project.title, 30),
      currentIndex: 1,
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'Chat del proyecto',
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.editProject,
            arguments: project.id,
          ),
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Editar proyecto',
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMemberQuickAction(project),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Añadir miembro',
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          _buildProjectHeader(project),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Resumen'),
              Tab(text: 'Tareas'),
              Tab(text: 'Miembros'),
              Tab(text: 'Documentos'),
              Tab(text: 'Objetivos'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(project, reports),
                _buildTasksTab(tasks),
                _buildMembersTab(project),
                _buildDocumentsTab(documents),
                _buildObjectivesTab(objectives),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader(ProjectModel project) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(project.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: Text(
                  project.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(project.status),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.spaceSm),
              if (project.area != null)
                Text(
                  project.area!,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceSm),
          Text(
            project.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.spaceMd),
          Row(
            children: [
              Text(
                'Progreso: ${project.progress}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppDimens.spaceMd),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: project.progress / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(_statusColor(project.status)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceSm),
          Row(
            children: [
              _buildInfoChip(Icons.people_outline, '${project.memberIds.length} miembros'),
              const SizedBox(width: AppDimens.spaceMd),
              _buildInfoChip(Icons.calendar_today, Helpers.formatDateShort(project.startDate)),
              const SizedBox(width: AppDimens.spaceMd),
              _buildInfoChip(
                Icons.attach_money,
                '${Helpers.formatCurrency(project.spent)} / ${Helpers.formatCurrency(project.budget)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return AppColors.success;
      case ProjectStatus.planning:
        return AppColors.info;
      case ProjectStatus.onHold:
        return AppColors.warning;
      case ProjectStatus.completed:
        return AppColors.primary;
      case ProjectStatus.cancelled:
        return AppColors.error;
    }
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildSummaryTab(ProjectModel project, List<ReportModel> reports) {
    final utilization = project.budgetUtilization;
    final isOverBudget = project.isOverBudget;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Presupuesto y Gasto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spaceMd),
          LayoutBuilder(builder: (context, constraints) {
            final count = constraints.maxWidth > 600 ? 3 : 1;
            final spacing = AppDimens.spaceMd;
            final w = (constraints.maxWidth - spacing * (count - 1)) / count;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: w,
                  child: _buildBudgetCard(
                    'Presupuesto',
                    Helpers.formatCurrency(project.budget),
                    Icons.account_balance_wallet,
                    AppColors.info,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _buildBudgetCard(
                    'Gastado',
                    Helpers.formatCurrency(project.spent),
                    Icons.trending_down,
                    AppColors.accent,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _buildBudgetCard(
                    'Disponible',
                    Helpers.formatCurrency(project.budget - project.spent),
                    Icons.savings,
                    isOverBudget ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: AppDimens.spaceMd),
          Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Utilización del Presupuesto',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isOverBudget ? AppColors.error : AppColors.success).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppDimens.radiusS),
                      ),
                      child: Text(
                        '${utilization.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isOverBudget ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.spaceSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (utilization / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverBudget ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ),
                if (isOverBudget) ...[
                  const SizedBox(height: AppDimens.spaceSm),
                  Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text(
                        'Este proyecto ha excedido el presupuesto',
                        style: TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceXl),
          const Text(
            'Gráfico de Presupuesto',
            style: TextStyle(
              fontSize: 16,
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
              labels: ['Presupuesto', 'Gastado', 'Disponible'],
              budgetValues: [
                project.budget,
                project.spent,
                project.budget - project.spent,
              ],
              spentValues: [
                project.budget,
                project.spent,
                project.budget - project.spent,
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceXl),
          const Text(
            'Informes del Proyecto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spaceMd),
          if (reports.isEmpty)
            const EmptyState(icon: Icons.assessment, title: 'Sin informes')
          else
            Column(
              children: reports.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimens.spaceMd),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(AppDimens.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.summary,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${r.authorName} - ${Helpers.timeAgo(r.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppDimens.spaceSm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.checklist_rtl,
        title: 'Sin tareas',
        message: 'Aún no se han creado tareas para este proyecto.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.spaceSm),
      itemBuilder: (_, i) {
        return TaskCard(
          task: tasks[i],
          onStatusChanged: (status) async {
            await _taskService.updateTaskStatus(tasks[i].id, status);
            setState(() {});
          },
        );
      },
    );
  }

  void _showAddMemberQuickAction(ProjectModel project) {
    _showAddMemberDialog(project);
  }

  Widget _buildMembersTab(ProjectModel project) {
    final currentUser = AuthService.instance.currentUser;
    final memberIds = project.memberIds;
    final leadId = project.leadId;

    List<(String, String, bool)> buildMembers() {
      final list = <(String, String, bool)>[];
      final seen = <String>{};
      // Current user first
      if (currentUser != null && memberIds.contains(currentUser.id)) {
        list.add((currentUser.id, '${currentUser.name} (Tú)', currentUser.id == leadId));
        seen.add(currentUser.id);
      }
      // Other members
      for (final mid in memberIds) {
        if (seen.contains(mid)) continue;
        final name = mid == 'u1' ? 'Usuario Principal' : 'Miembro $mid';
        list.add((mid, name, mid == leadId));
        seen.add(mid);
      }
      return list;
    }

    final members = buildMembers();

    return ListView(
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${members.length} miembro${members.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddMemberDialog(project),
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text('Añadir'),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.spaceLg),
        if (members.isEmpty)
          const EmptyState(
            icon: Icons.people_outline,
            title: 'Sin miembros',
            message: 'Añade miembros al proyecto para empezar a colaborar.',
          )
        else
          ...members.map((m) => _buildMemberTile(project, m.$1, m.$2, m.$3, members)),
      ],
    );
  }

  Widget _buildMemberTile(
    ProjectModel project,
    String memberId,
    String name,
    bool isLeader,
    List<(String, String, bool)> allMembers,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimens.spaceMd),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              Helpers.initialsFromName(name.replaceAll(' (Tú)', '')),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isLeader)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: AppColors.warning),
                        SizedBox(width: 4),
                        Text(
                          'Líder',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
            onSelected: (value) async {
              if (value == 'leader') {
                final updated = project.copyWith(leadId: memberId);
                await _projectService.updateProject(updated);
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name asignado como líder'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } else if (value == 'remove') {
                final newMembers = project.memberIds.where((id) => id != memberId).toList();
                final updated = project.copyWith(memberIds: newMembers);
                await _projectService.updateProject(updated);
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name removido del proyecto'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            itemBuilder: (_) => [
              if (!isLeader)
                const PopupMenuItem(value: 'leader', child: Text('Asignar como líder')),
              if (allMembers.length > 1)
                PopupMenuItem(
                  value: 'remove',
                  child: Text('Remover', style: TextStyle(color: AppColors.error)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(ProjectModel project) {
    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Añadir Miembro'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del miembro',
                    hintText: 'Ej: Dra. María Pérez',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Escribe un nombre' : null,
                ),
                const SizedBox(height: AppDimens.spaceMd),
                TextFormField(
                  controller: idCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID del miembro (opcional)',
                    hintText: 'Se genera automáticamente si se deja vacío',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final memberId = idCtrl.text.trim().isEmpty
                    ? 'm${DateTime.now().millisecondsSinceEpoch}'
                    : idCtrl.text.trim();
                if (project.memberIds.contains(memberId)) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ese miembro ya está en el proyecto'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                  return;
                }
                final newMembers = [...project.memberIds, memberId];
                final updated = project.copyWith(memberIds: newMembers);
                await _projectService.updateProject(updated);
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${nameCtrl.text.trim()} añadido al proyecto'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocumentsTab(List<DocumentModel> documents) {
    if (documents.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_off,
        title: 'Sin documentos',
        message: 'No hay documentos compartidos en este proyecto.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      itemCount: documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.spaceSm),
      itemBuilder: (_, i) {
        return DocumentCard(document: documents[i]);
      },
    );
  }

  Widget _buildObjectivesTab(List<ObjectiveModel> objectives) {
    return Stack(
      children: [
        objectives.isEmpty
            ? const EmptyState(
                icon: Icons.flag_outlined,
                title: 'Sin objetivos',
                message: 'No se han definido objetivos para este proyecto.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppDimens.spaceLg),
                itemCount: objectives.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppDimens.spaceMd),
                itemBuilder: (_, i) => _buildObjectiveCard(objectives[i]),
              ),
        Positioned(
          bottom: AppDimens.spaceLg,
          right: AppDimens.spaceLg,
          child: FloatingActionButton(
            heroTag: 'add_objective',
            mini: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: () => _showObjectiveDialog(projectId: widget.projectId),
            tooltip: 'Crear objetivo',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildObjectiveCard(ObjectiveModel obj) {
    final tasks = _taskService.getTasksByObjective(obj.id);
    final linkedTaskCount = tasks.length;
    final completedTasks = tasks.where((t) => t.status == TaskStatus.done).length;

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
              Icon(Icons.flag, size: 18, color: _objectiveColor(obj.status)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  obj.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showObjectiveDialog(objective: obj);
                  } else if (value == 'complete') {
                    _toggleCompleteObjective(obj);
                  } else if (value == 'delete') {
                    _confirmDeleteObjective(obj);
                  } else if (value == 'link_task') {
                    _showLinkTaskDialog(obj);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  if (obj.status != ObjectiveStatus.achieved)
                    const PopupMenuItem(value: 'complete', child: Text('Marcar como completado'))
                  else
                    const PopupMenuItem(value: 'complete', child: Text('Reabrir objetivo')),
                  const PopupMenuItem(value: 'link_task', child: Text('Relacionar tarea')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Eliminar', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
          if (obj.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              obj.description,
              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppDimens.spaceSm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _objectiveColor(obj.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: Text(
                  obj.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _objectiveColor(obj.status),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(obj.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _objectiveColor(obj.status),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceSm),
          Row(
            children: [
              Text(
                '${obj.completedMilestones}/${obj.milestones.length} hitos',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(width: AppDimens.spaceSm),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: obj.progress,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_objectiveColor(obj.status)),
                  ),
                ),
              ),
            ],
          ),
          if (obj.milestones.isNotEmpty) ...[
            const SizedBox(height: AppDimens.spaceSm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(obj.milestones.length, (mi) {
                final completed = mi < obj.completedMilestones;
                return GestureDetector(
                  onTap: () => _toggleMilestone(obj, mi),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: completed
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                      border: Border.all(
                        color: completed ? AppColors.success : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          completed ? Icons.check_circle : Icons.circle_outlined,
                          size: 12,
                          color: completed ? AppColors.success : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          obj.milestones[mi],
                          style: TextStyle(
                            fontSize: 11,
                            color: completed ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
          if (obj.targetDate != null) ...[
            const SizedBox(height: AppDimens.spaceSm),
            Row(
              children: [
                Icon(Icons.event, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Meta: ${Helpers.formatDateShort(obj.targetDate!)}',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
          if (linkedTaskCount > 0) ...[
            const SizedBox(height: AppDimens.spaceSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '$completedTasks/$linkedTaskCount tareas completadas',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showObjectiveDialog({String? projectId, ObjectiveModel? objective}) {
    final isEditing = objective != null;
    final titleCtrl = TextEditingController(text: objective?.title ?? '');
    final descCtrl = TextEditingController(text: objective?.description ?? '');
    final milestonesCtrl = TextEditingController(text: objective?.milestones.join('\n') ?? '');
    final formKey = GlobalKey<FormState>();
    ObjectiveStatus status = objective?.status ?? ObjectiveStatus.notStarted;
    DateTime? targetDate = objective?.targetDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Objetivo' : 'Nuevo Objetivo'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Título del objetivo',
                            hintText: 'Ej: Publicar 3 artículos científicos',
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Escribe un título' : null,
                        ),
                        const SizedBox(height: AppDimens.spaceMd),
                        TextFormField(
                          controller: descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppDimens.spaceMd),
                        TextFormField(
                          controller: milestonesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Hitos (uno por línea)',
                            hintText: 'Recolección de datos\nAnálisis\nPublicación',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppDimens.spaceMd),
                        DropdownButtonFormField<ObjectiveStatus>(
                          value: status,
                          decoration: const InputDecoration(labelText: 'Estado'),
                          items: ObjectiveStatus.values
                              .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                              .toList(),
                          onChanged: (v) => setDialogState(() => status = v ?? ObjectiveStatus.notStarted),
                        ),
                        const SizedBox(height: AppDimens.spaceMd),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: targetDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setDialogState(() => targetDate = picked);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppDimens.radiusM),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  targetDate != null
                                      ? 'Meta: ${targetDate!.day}/${targetDate!.month}/${targetDate!.year}'
                                      : 'Fecha meta (opcional)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: targetDate != null ? AppColors.textPrimary : AppColors.textMuted,
                                  ),
                                ),
                                if (targetDate != null)
                                  GestureDetector(
                                    onTap: () => setDialogState(() => targetDate = null),
                                    child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    final milestoneList = milestonesCtrl.text
                        .split('\n')
                        .map((m) => m.trim())
                        .where((m) => m.isNotEmpty)
                        .toList();

                    if (isEditing) {
                      final completed = milestoneList.length < objective!.completedMilestones
                          ? milestoneList.length
                          : objective.completedMilestones;
                      final updated = objective.copyWith(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        status: status,
                        targetDate: targetDate,
                        milestones: milestoneList,
                        completedMilestones: completed,
                      );
                      _projectService.updateObjective(updated);
                    } else {
                      final newObj = ObjectiveModel(
                        id: 'obj_${DateTime.now().millisecondsSinceEpoch}',
                        projectId: projectId!,
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        status: status,
                        targetDate: targetDate,
                        milestones: milestoneList,
                        createdAt: DateTime.now(),
                      );
                      _projectService.addObjective(newObj);
                    }
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Objetivo actualizado' : 'Objetivo creado'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: Text(isEditing ? 'Guardar' : 'Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleCompleteObjective(ObjectiveModel obj) {
    final newStatus = obj.status == ObjectiveStatus.achieved
        ? ObjectiveStatus.inProgress
        : ObjectiveStatus.achieved;
    final newCompleted = newStatus == ObjectiveStatus.achieved ? obj.milestones.length : obj.completedMilestones;
    final updated = obj.copyWith(status: newStatus, completedMilestones: newCompleted);
    _projectService.updateObjective(updated);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newStatus == ObjectiveStatus.achieved
            ? 'Objetivo "${obj.title}" completado'
            : 'Objetivo reabierto'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _confirmDeleteObjective(ObjectiveModel obj) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar objetivo'),
        content: Text('¿Seguro que quieres eliminar "${obj.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _projectService.deleteObjective(obj.id);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Objetivo "${obj.title}" eliminado'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _toggleMilestone(ObjectiveModel obj, int milestoneIndex) {
    final isCompleted = milestoneIndex < obj.completedMilestones;
    int newCompleted;
    if (isCompleted) {
      newCompleted = milestoneIndex;
    } else {
      newCompleted = milestoneIndex + 1;
    }
    final allDone = newCompleted == obj.milestones.length;
    final newStatus = allDone ? ObjectiveStatus.achieved : (newCompleted > 0 ? ObjectiveStatus.inProgress : obj.status);
    final updated = obj.copyWith(completedMilestones: newCompleted, status: newStatus);
    _projectService.updateObjective(updated);
    setState(() {});
  }

  void _showLinkTaskDialog(ObjectiveModel obj) {
    final projectTasks = _taskService.getTasksForProject(widget.projectId);
    final linkedTasks = _taskService.getTasksByObjective(obj.id);
    final linkedIds = linkedTasks.map((t) => t.id).toSet();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Relacionar tareas'),
              content: SizedBox(
                width: double.maxFinite,
                child: projectTasks.isEmpty
                    ? const Text('No hay tareas en este proyecto para relacionar.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: projectTasks.length,
                        itemBuilder: (_, i) {
                          final task = projectTasks[i];
                          final isLinked = linkedIds.contains(task.id);
                          return CheckboxListTile(
                            value: isLinked,
                            title: Text(task.title, style: const TextStyle(fontSize: 14)),
                            subtitle: Text(
                              task.status.label,
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            onChanged: (checked) async {
                              if (checked == true) {
                                final updated = task.copyWith(objectiveId: obj.id);
                                await _taskService.updateTask(updated);
                              } else {
                                final updated = task.copyWith(objectiveId: null);
                                await _taskService.updateTask(updated);
                              }
                              setDialogState(() {
                                if (checked == true) {
                                  linkedIds.add(task.id);
                                } else {
                                  linkedIds.remove(task.id);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _objectiveColor(ObjectiveStatus status) {
    switch (status) {
      case ObjectiveStatus.achieved:
        return AppColors.success;
      case ObjectiveStatus.inProgress:
        return AppColors.info;
      case ObjectiveStatus.notStarted:
        return AppColors.textMuted;
      case ObjectiveStatus.deferred:
        return AppColors.warning;
    }
  }
}
