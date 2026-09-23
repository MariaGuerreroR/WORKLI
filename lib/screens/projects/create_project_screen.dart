import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/project_model.dart';
import '../../services/auth_service.dart';
import '../../services/project_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../app_scaffold.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _areaController = TextEditingController();
  final _budgetController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  ProjectStatus _status = ProjectStatus.planning;
  final _projectService = ProjectService();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _budgetController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nuevo Proyecto',
      currentIndex: 1,
      actions: [
        TextButton.icon(
          onPressed: _saving ? null : _submitForm,
          icon: const Icon(Icons.check, color: Colors.white),
          label: const Text(
            'Guardar',
            style: TextStyle(color: Colors.white),
          ),
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
                  label: Text(_saving ? 'Guardando...' : 'Crear Proyecto'),
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
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final user = AuthService.instance.currentUser;
    final userId = user?.id ?? 'u1';

    final project = ProjectModel(
      id: 'temp',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      area: _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
      status: _status,
      leadId: userId,
      memberIds: [userId],
      startDate: _startDate,
      endDate: _endDate,
      budget: double.tryParse(_budgetController.text.trim()) ?? 0,
      progress: 0,
      tags: tags,
      createdAt: DateTime.now(),
    );

    try {
      await _projectService.addProject(project);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Proyecto "${project.title}" creado'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.projects);
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
