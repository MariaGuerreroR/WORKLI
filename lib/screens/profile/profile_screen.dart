import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../services/user_service.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/report_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/connection_error_widget.dart';
import '../app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _projectService = ProjectService();
  final _taskService = TaskService();
  final _reportService = ReportService();
  bool _loading = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _userService.refresh(),
        _projectService.refresh(),
        _taskService.refresh(),
        _reportService.refresh(),
      ]);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _user = _userService.currentUser;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Perfil',
        currentIndex: 8,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userService.connectionFailed) {
      return AppScaffold(
        title: 'Perfil',
        currentIndex: 8,
        body: ConnectionErrorWidget(
          onRetry: () {
            setState(() => _loading = true);
            _loadData();
          },
        ),
      );
    }

    final user = _user;
    if (user == null) {
      return AppScaffold(
        title: 'Perfil',
        currentIndex: 8,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
              const SizedBox(height: AppDimens.spaceMd),
              const Text(
                'No se pudo cargar el perfil',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimens.spaceMd),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _loading = true);
                  _loadData();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final myTasks = _taskService.getTasksByAssignee(user.id);
    final myReports =
        _reportService.getAllReports().where((r) => r.authorId == user.id).toList();
    final myProjects =
        _projectService.getAllProjects().where((p) => p.leadId == user.id).toList();

    return AppScaffold(
      title: 'Perfil',
      currentIndex: 8,
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
              _buildProfileHeader(user),
              const SizedBox(height: AppDimens.spaceLg),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _showEditDialog,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Editar Perfil'),
                ),
              ),
              const SizedBox(height: AppDimens.spaceXl),
              LayoutBuilder(builder: (context, constraints) {
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
                        label: 'Proyectos Liderados',
                        value: '${myProjects.length}',
                        icon: Icons.folder_open,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: MetricCard(
                        label: 'Tareas Asignadas',
                        value: '${myTasks.length}',
                        icon: Icons.checklist_rtl,
                        color: AppColors.info,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: MetricCard(
                        label: 'Informes Creados',
                        value: '${myReports.length}',
                        icon: Icons.assessment,
                        color: AppColors.accent,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: MetricCard(
                        label: 'Tareas Completadas',
                        value:
                            '${myTasks.where((t) => t.status == TaskStatus.done).length}',
                        icon: Icons.task_alt,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: AppDimens.spaceXl),
              const Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimens.spaceMd),
              _buildInfoCard(user),
              const SizedBox(height: AppDimens.spaceXl),
              const Text(
                'Configuración',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimens.spaceMd),
              _buildSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: Text(
                    user.role.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.institution ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline, 'Nombre', user.name),
          const Divider(height: AppDimens.spaceXl),
          _buildInfoRow(Icons.email_outlined, 'Correo', user.email),
          const Divider(height: AppDimens.spaceXl),
          _buildInfoRow(
              Icons.school_outlined, 'Institución', user.institution ?? 'No especificada'),
          const Divider(height: AppDimens.spaceXl),
          _buildInfoRow(Icons.badge_outlined, 'Rol', user.role.label),
          const Divider(height: AppDimens.spaceXl),
          _buildInfoRow(
              Icons.folder_outlined, 'Proyectos', '${user.projectIds.length} proyectos'),
          const Divider(height: AppDimens.spaceXl),
          _buildInfoRow(Icons.calendar_today_outlined, 'Miembro desde',
              Helpers.formatDate(user.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppDimens.spaceMd),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceSm),
      child: Column(
        children: [
          _buildSettingItem(Icons.notifications_outlined, 'Notificaciones', 'Configurar alertas'),
          _buildSettingItem(Icons.lock_outline, 'Privacidad', 'Gestionar permisos'),
          _buildSettingItem(Icons.palette_outlined, 'Apariencia', 'Tema claro/oscuro'),
          _buildSettingItem(Icons.language_outlined, 'Idioma', 'Español'),
          _buildSettingItem(Icons.help_outline, 'Ayuda', 'Soporte y documentación'),
          _buildSettingItem(Icons.logout, 'Cerrar Sesión', null, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String? subtitle,
      {bool isDestructive = false}) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceLg,
            vertical: AppDimens.spaceMd + 2,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 22,
                  color: isDestructive ? AppColors.error : AppColors.textSecondary),
              const SizedBox(width: AppDimens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              if (!isDestructive)
                Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog() {
    final user = _user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final institutionCtrl = TextEditingController(text: user.institution ?? '');
    UserRole selectedRole = user.role;
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Perfil'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (v) => Validators.required(v, field: 'El nombre'),
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Correo'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final req = Validators.required(v, field: 'El correo');
                          if (req != null) return req;
                          return Validators.email(v);
                        },
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      TextFormField(
                        controller: institutionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Institución',
                          hintText: 'Universidad u organismo',
                        ),
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      DropdownButtonFormField<UserRole>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: UserRole.values
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r.label),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedRole = v ?? user.role),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          final updated = await _userService.updateProfile(
                            name: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            institution: institutionCtrl.text.trim().isEmpty
                                ? null
                                : institutionCtrl.text.trim(),
                            role: selectedRole,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (updated != null && mounted) {
                            setState(() => _user = updated);
                            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Perfil actualizado'),
                backgroundColor: AppColors.success,
              ),
            );
                          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo actualizar el perfil'),
                backgroundColor: AppColors.error,
              ),
            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
