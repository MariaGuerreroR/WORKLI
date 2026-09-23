import 'package:flutter/material.dart';

import '../../models/task_model.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/project_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/task_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/connection_error_widget.dart';
import '../app_scaffold.dart';

enum _TaskFilter { all, overdue, completed, pending }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _taskService = TaskService();
  final _projectService = ProjectService();
  TaskStatus? _filterStatus;
  _TaskFilter _quickFilter = _TaskFilter.all;
  String? _filterProjectId;
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _taskService.refresh();
    await _projectService.refresh();
    if (mounted) setState(() => _loading = false);
  }

  List<TaskModel> get _filteredTasks {
    var tasks = _taskService.getAllTasks();

    // Quick filter (overdue / completed / pending)
    switch (_quickFilter) {
      case _TaskFilter.overdue:
        tasks = tasks.where((t) => t.isOverdue).toList();
        break;
      case _TaskFilter.completed:
        tasks = tasks.where((t) => t.status == TaskStatus.done).toList();
        break;
      case _TaskFilter.pending:
        tasks = tasks.where((t) => t.status != TaskStatus.done).toList();
        break;
      case _TaskFilter.all:
        break;
    }

    // Status filter
    if (_filterStatus != null) {
      tasks = tasks.where((t) => t.status == _filterStatus).toList();
    }

    // Project filter
    if (_filterProjectId != null) {
      tasks = tasks.where((t) => t.projectId == _filterProjectId).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      tasks = tasks.where((t) {
        return t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return tasks;
  }

  String? _assigneeName(String? assigneeId) {
    if (assigneeId == null) return null;
    final user = AuthService.instance.currentUser;
    if (user != null && user.id == assigneeId) return user.name;
    return assigneeId == 'u1' ? 'Sin asignar' : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Tareas',
        currentIndex: 2,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_taskService.connectionFailed) {
      return AppScaffold(
        title: 'Tareas',
        currentIndex: 2,
        body: ConnectionErrorWidget(
          onRetry: () {
            setState(() => _loading = true);
            _loadData();
          },
        ),
      );
    }

    final tasks = _filteredTasks;
    final projects = _projectService.getAllProjects();

    return AppScaffold(
      title: 'Tareas',
      currentIndex: 2,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
              _buildMetricsRow(),
              const SizedBox(height: AppDimens.spaceXl),
              _buildSearchField(),
              const SizedBox(height: AppDimens.spaceMd),
              _buildQuickFilters(),
              const SizedBox(height: AppDimens.spaceMd),
              _buildProjectFilter(projects),
              const SizedBox(height: AppDimens.spaceMd),
              _buildStatusFilterChips(),
              const SizedBox(height: AppDimens.spaceLg),
              if (tasks.isEmpty)
                EmptyState(
                  icon: Icons.checklist_rtl,
                  title: 'Sin tareas',
                  message: 'No se encontraron tareas con los filtros actuales.',
                  actionLabel: 'Crear Tarea',
                  onAction: () => _showTaskDialog(),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppDimens.spaceSm),
                  itemBuilder: (_, i) {
                    final t = tasks[i];
                    final project = _projectService.getProjectById(t.projectId);
                    return Dismissible(
                      key: Key(t.id),
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
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar tarea'),
                            content: Text('¿Seguro que quieres eliminar "${t.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        await _taskService.deleteTask(t.id);
                        setState(() {});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tarea "${t.title}" eliminada'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      child: TaskCard(
                        task: t,
                        projectTitle: project?.title,
                        assigneeName: _assigneeName(t.assigneeId),
                        onStatusChanged: (status) async {
                          await _taskService.updateTaskStatus(t.id, status);
                          setState(() {});
                        },
                        onEdit: () => _showTaskDialog(task: t),
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar tarea'),
                              content: Text('¿Seguro que quieres eliminar "${t.title}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await _taskService.deleteTask(t.id);
                            setState(() {});
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Tarea "${t.title}" eliminada'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final count = constraints.maxWidth > 700 ? 4 : 2;
      final spacing = AppDimens.spaceMd;
      final w = (constraints.maxWidth - spacing * (count - 1)) / count;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          SizedBox(
            width: w,
            child: MetricCard(
              label: 'Total Tareas',
              value: '${_taskService.totalTasks}',
              icon: Icons.checklist_rtl,
              color: AppColors.primary,
            ),
          ),
          SizedBox(
            width: w,
            child: MetricCard(
              label: 'Completadas',
              value: '${_taskService.completedTasks}',
              icon: Icons.task_alt,
              color: AppColors.success,
            ),
          ),
          SizedBox(
            width: w,
            child: MetricCard(
              label: 'Pendientes',
              value: '${_taskService.totalTasks - _taskService.completedTasks}',
              icon: Icons.pending_actions,
              color: AppColors.info,
            ),
          ),
          SizedBox(
            width: w,
            child: MetricCard(
              label: 'Vencidas',
              value: '${_taskService.overdueCount}',
              icon: Icons.warning_amber,
              color: AppColors.error,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar tareas...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => setState(() => _searchQuery = ''),
              )
            : null,
      ),
      onChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  Widget _buildQuickFilters() {
    final chips = <(String, _TaskFilter, IconData, Color)>[
      ('Todas', _TaskFilter.all, Icons.list, AppColors.primary),
      ('Vencidas', _TaskFilter.overdue, Icons.warning_amber, AppColors.error),
      ('Pendientes', _TaskFilter.pending, Icons.pending_actions, AppColors.info),
      ('Completadas', _TaskFilter.completed, Icons.task_alt, AppColors.success),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final isSelected = _quickFilter == c.$2;
          return Padding(
            padding: const EdgeInsets.only(right: AppDimens.spaceSm),
            child: GestureDetector(
              onTap: () => setState(() => _quickFilter = c.$2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? c.$4 : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  border: Border.all(color: isSelected ? c.$4 : AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(c.$3, size: 14, color: isSelected ? Colors.white : c.$4),
                    const SizedBox(width: 6),
                    Text(
                      c.$1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProjectFilter(List<ProjectModel> projects) {
    if (projects.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildProjectChip('Todos los proyectos', null),
          const SizedBox(width: AppDimens.spaceSm),
          ...projects.map((p) {
            return Padding(
              padding: const EdgeInsets.only(right: AppDimens.spaceSm),
              child: _buildProjectChip(p.title, p.id),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProjectChip(String label, String? projectId) {
    final isSelected = _filterProjectId == projectId;
    return GestureDetector(
      onTap: () => setState(() => _filterProjectId = projectId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        constraints: const BoxConstraints(maxWidth: 200),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Todos los estados', null),
          const SizedBox(width: AppDimens.spaceSm),
          _buildFilterChip('Por Hacer', TaskStatus.todo),
          const SizedBox(width: AppDimens.spaceSm),
          _buildFilterChip('En Progreso', TaskStatus.inProgress),
          const SizedBox(width: AppDimens.spaceSm),
          _buildFilterChip('En Revisión', TaskStatus.review),
          const SizedBox(width: AppDimens.spaceSm),
          _buildFilterChip('Completadas', TaskStatus.done),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TaskStatus? status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
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

  void _showTaskDialog({TaskModel? task}) {
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

    final isEditing = task != null;
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    final descCtrl = TextEditingController(text: task?.description ?? '');
    String selectedProjectId = task?.projectId ?? projects.first.id;
    TaskPriority selectedPriority = task?.priority ?? TaskPriority.medium;
    TaskStatus selectedStatus = task?.status ?? TaskStatus.todo;
    String? selectedAssigneeId = task?.assigneeId;
    DateTime? dueDate = task?.dueDate;
    final formKey = GlobalKey<FormState>();

    // Build member list from all project members + current user
    final memberIds = <String>{};
    for (final p in projects) {
      memberIds.addAll(p.memberIds);
    }
    final currentUser = AuthService.instance.currentUser;
    if (currentUser != null) memberIds.add(currentUser.id);

    // Build simple member list: current user + placeholder members
    final members = <(String, String)>[];
    if (currentUser != null) {
      members.add((currentUser.id, '${currentUser.name} (Yo)'));
    }
    // Add project members that aren't the current user
    for (final mid in memberIds) {
      if (mid == currentUser?.id) continue;
      members.add((mid, mid == 'u1' ? 'Usuario Principal' : 'Miembro $mid'));
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Tarea' : 'Nueva Tarea'),
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
                        onChanged: isEditing
                            ? null
                            : (v) => setDialogState(() => selectedProjectId = v!),
                        disabledHint: isEditing ? const Text('No se puede cambiar de proyecto') : null,
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Título'),
                        validator: (v) => Validators.required(v, field: 'El título'),
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'Descripción'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      DropdownButtonFormField<TaskPriority>(
                        value: selectedPriority,
                        decoration: const InputDecoration(labelText: 'Prioridad'),
                        items: TaskPriority.values
                            .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedPriority = v!),
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      DropdownButtonFormField<TaskStatus>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Estado'),
                        items: TaskStatus.values
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedStatus = v!),
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      DropdownButtonFormField<String>(
                        value: selectedAssigneeId,
                        decoration: const InputDecoration(labelText: 'Asignar a'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                          ...members.map((m) => DropdownMenuItem(value: m.$1, child: Text(m.$2))),
                        ],
                        onChanged: (v) => setDialogState(() => selectedAssigneeId = v),
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          dueDate != null
                              ? 'Vence: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                              : 'Sin fecha límite',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (dueDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setDialogState(() => dueDate = null),
                              ),
                            const Icon(Icons.calendar_today_outlined, size: 20),
                          ],
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => dueDate = picked);
                          }
                        },
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    if (isEditing) {
                      final updated = task.copyWith(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        priority: selectedPriority,
                        status: selectedStatus,
                        assigneeId: selectedAssigneeId,
                        dueDate: dueDate,
                      );
                      await _taskService.updateTask(updated);
                      if (ctx.mounted) Navigator.pop(ctx);
                      setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tarea "${updated.title}" actualizada'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } else {
                      final newTask = TaskModel(
                        id: 'temp',
                        projectId: selectedProjectId,
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        priority: selectedPriority,
                        status: selectedStatus,
                        assigneeId: selectedAssigneeId,
                        dueDate: dueDate,
                        createdAt: DateTime.now(),
                      );
                      await _taskService.addTask(newTask);
                      if (ctx.mounted) Navigator.pop(ctx);
                      setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tarea "${newTask.title}" creada'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
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
}
