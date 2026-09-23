import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/project_model.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../utils/constants.dart';
import '../../widgets/project_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/connection_error_widget.dart';
import '../app_scaffold.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _projectService = ProjectService();
  final _taskService = TaskService();
  String _searchQuery = '';
  ProjectStatus? _filterStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _projectService.refresh(),
        _taskService.refresh(),
      ]).timeout(const Duration(seconds: 8));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ProjectModel> get _filteredProjects {
    var projects = _projectService.getAllProjects();
    if (_filterStatus != null) {
      projects = projects.where((p) => p.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      projects = projects.where((p) {
        return p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (p.area?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    return projects;
  }

  Future<bool> _confirmDelete(BuildContext context, ProjectModel project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text(
          '¿Seguro que quieres eliminar "${project.title}"? '
          'Se borrarán también sus tareas y objetivos.',
        ),
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
      await _projectService.deleteProject(project.id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Proyecto "${project.title}" eliminado'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Proyectos',
        currentIndex: 1,
        floatingActionButton: _buildCreateProjectButton(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_projectService.connectionFailed) {
      return AppScaffold(
        title: 'Proyectos',
        currentIndex: 1,
        floatingActionButton: _buildCreateProjectButton(),
        body: ConnectionErrorWidget(
          onRetry: () {
            setState(() => _loading = true);
            _loadData();
          },
        ),
      );
    }

    final projects = _filteredProjects;

    return AppScaffold(
      title: 'Proyectos',
      currentIndex: 1,
      floatingActionButton: _buildCreateProjectButton(),
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
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar proyectos...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: AppDimens.spaceMd),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', null),
                    const SizedBox(width: AppDimens.spaceSm),
                    _buildFilterChip('Activos', ProjectStatus.active),
                    const SizedBox(width: AppDimens.spaceSm),
                    _buildFilterChip('Planificación', ProjectStatus.planning),
                    const SizedBox(width: AppDimens.spaceSm),
                    _buildFilterChip('En Pausa', ProjectStatus.onHold),
                    const SizedBox(width: AppDimens.spaceSm),
                    _buildFilterChip('Completados', ProjectStatus.completed),
                    const SizedBox(width: AppDimens.spaceSm),
                    _buildFilterChip('Cancelados', ProjectStatus.cancelled),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.spaceLg),
              Text(
                '${projects.length} proyecto${projects.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimens.spaceMd),
              if (projects.isEmpty)
                EmptyState(
                  icon: Icons.folder_off,
                  title: 'Sin proyectos',
                  message: 'No se encontraron proyectos con los filtros actuales.',
                  actionLabel: 'Crear Proyecto',
                  onAction: _openCreateProject,
                )
              else
                LayoutBuilder(builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                  final spacing = AppDimens.spaceMd;
                  final itemWidth =
                      (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: projects.map((p) {
                      return SizedBox(
                        width: itemWidth,
                        child: Dismissible(
                          key: Key(p.id),
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
                          confirmDismiss: (_) => _confirmDelete(context, p),
                          onDismissed: (_) => setState(() {}),
                          child: ProjectCard(
                            project: p,
                            memberCount: p.memberIds.length,
                            taskCount: _taskService.getTasksForProject(p.id).length,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.projectWorkspace,
                              arguments: p.id,
                            ),
                            onEdit: () => Navigator.pushNamed(
                              context,
                              AppRoutes.editProject,
                              arguments: p.id,
                            ),
                            onDelete: () => _confirmDelete(context, p),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateProjectButton() {
    return FloatingActionButton(
      onPressed: _openCreateProject,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      tooltip: 'Crear proyecto',
      child: const Icon(Icons.add),
    );
  }

  void _openCreateProject() {
    Navigator.pushNamed(context, AppRoutes.createProject);
  }

  Widget _buildFilterChip(String label, ProjectStatus? status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
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
}
