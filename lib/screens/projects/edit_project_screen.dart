import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/project_model.dart';
import '../../services/project_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../app_scaffold.dart';

class EditProjectScreen extends StatefulWidget {
  final String projectId;

  const EditProjectScreen({super.key, required this.projectId});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _areaController = TextEditingController();
  final _budgetController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _leadId = 'u1';
  List<String> _memberIds = [];
  ProjectStatus _status = ProjectStatus.planning;
  final _projectService = ProjectService();
  bool _saving = false;
  bool _loading = true;
  ProjectModel? _project;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    await _projectService.refresh();
    final project = _projectService.getProjectById(widget.projectId);
    if (project != null && mounted) {
      _titleController.text = project.title;
      _descriptionController.text = project.description;
      _areaController.text = project.area ?? '';
      _budgetController.text = project.budget == 0 ? '' : project.budget.toStringAsFixed(0);
      _tagsController.text = project.tags.join(', ');
      setState(() {
        _leadId = project.leadId;
        _memberIds = List<String>.from(project.memberIds);
        _startDate = project.startDate;
        _endDate = project.endDate;
        _status = project.status;
        _project = project;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _budgetController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String _memberName(String memberId) {
    final user = AuthService.instance.currentUser;
    if (user != null && user.id == memberId) return '${user.name} (Tú)';
    return memberId == 'u1' ? 'Usuario Principal' : 'Miembro $memberId';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Editar Proyecto',
        currentIndex: 1,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_project == null) {
      return AppScaffold(
        title: 'Editar Proyecto',
        currentIndex: 1,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
              const SizedBox(height: AppDimens.spaceMd),
              const Text(
                'Proyecto no encontrado',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimens.spaceMd),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Editar Proyecto',
      currentIndex: 1,
      actions: [
        TextButton.icon(
          onPressed: _saving ? null : _submitForm,
          icon: const Icon(Icons.check, color: Colors.white),
          label: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('Información General'),
              const SizedBox(height: AppDimens.spaceMd),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del proyecto',
                  hintText: 'Ej: Estudio de biodiversidad...',
                ),
                validator: (v) => Validators.required(v, field: 'El título'),
              ),
              const SizedBox(height: AppDimens.spaceMd),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe los objetivos y alcance del proyecto...',
                ),
                maxLines: 4,
                validator: (v) => Validators.required(v, field: 'La descripción'),
              ),
              const SizedBox(height: AppDimens.spaceMd),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Área de investigación',
                  hintText: 'Ej: Ecología, Nanotecnología...',
                ),
              ),
              const SizedBox(height: AppDimens.spaceXl),
              _buildSectionLabel('Planificación'),
              const SizedBox(height: AppDimens.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Fecha de inicio',
                      date: _startDate,
                      onPicked: (d) => setState(() => _startDate = d),
                    ),
                  ),
                  const SizedBox(width: AppDimens.spaceMd),
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Fecha de fin (opcional)',
                      date: _endDate,
                      onPicked: (d) => setState(() => _endDate = d),
                      canClear: true,
                      onClear: () => setState(() => _endDate = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spaceMd),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Presupuesto estimado (\$)',
                  hintText: '0',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: Validators.budget,
              ),
              const SizedBox(height: AppDimens.spaceXl),
              _buildSectionLabel('Estado y Etiquetas'),
              const SizedBox(height: AppDimens.spaceMd),
              _buildStatusSelector(),
              const SizedBox(height: AppDimens.spaceMd),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Etiquetas (separadas por comas)',
                  hintText: 'Clima, Biodiversidad, Andes',
                ),
              ),
              const SizedBox(height: AppDimens.spaceXl),
              _buildSectionLabel('Equipo y Liderazgo'),
              const SizedBox(height: AppDimens.spaceMd),
              _buildLeaderSelector(),
              const SizedBox(height: AppDimens.spaceMd),
              _buildMembersList(),
              const SizedBox(height: AppDimens.spaceMd),
              OutlinedButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.person_add, size: 20),
                label: const Text('Añadir miembro'),
              ),
              const SizedBox(height: AppDimens.spaceXl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submitForm,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Guardando...' : 'Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onPicked,
    bool canClear = false,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                if (canClear && date != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Sin fecha',
              style: TextStyle(
                fontSize: 15,
                color: date != null ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Wrap(
      spacing: AppDimens.spaceSm,
      children: ProjectStatus.values.map((status) {
        final isSelected = _status == status;
        return GestureDetector(
          onTap: () => setState(() => _status = status),
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
              status.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeaderSelector() {
    if (_memberIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimens.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Añade miembros primero para asignar un líder.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      value: _memberIds.contains(_leadId) ? _leadId : _memberIds.first,
      decoration: const InputDecoration(labelText: 'Líder del proyecto'),
      items: _memberIds
          .map((mid) => DropdownMenuItem(value: mid, child: Text(_memberName(mid))))
          .toList(),
      onChanged: (v) => setState(() => _leadId = v ?? _memberIds.first),
    );
  }

  Widget _buildMembersList() {
    if (_memberIds.isEmpty) {
      return Text(
        'Sin miembros. Añade miembros al proyecto.',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceSm),
      child: Column(
        children: _memberIds.map((mid) {
          final isLeader = mid == _leadId;
          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(
                _memberName(mid).replaceAll(' (Tú)', '')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            title: Text(
              _memberName(mid),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLeader)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    ),
                    child: const Text(
                      'Líder',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning),
                    ),
                  ),
                if (_memberIds.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, size: 20, color: AppColors.error),
                    onPressed: () {
                      setState(() {
                        _memberIds.remove(mid);
                        if (_leadId == mid) {
                          _leadId = _memberIds.isNotEmpty ? _memberIds.first : 'u1';
                        }
                      });
                    },
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _addMember() {
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
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final memberId = idCtrl.text.trim().isEmpty
                    ? 'm${DateTime.now().millisecondsSinceEpoch}'
                    : idCtrl.text.trim();
                if (_memberIds.contains(memberId)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ese miembro ya está en el proyecto'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }
                setState(() => _memberIds.add(memberId));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${nameCtrl.text.trim()} añadido'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final updated = _project!.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      area: _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
      status: _status,
      leadId: _leadId,
      memberIds: _memberIds,
      endDate: _endDate,
      budget: double.tryParse(_budgetController.text.trim()) ?? 0,
      tags: tags,
    );

    try {
      await _projectService.updateProject(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Proyecto "${updated.title}" actualizado'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.projectWorkspace,
          arguments: widget.projectId,
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
