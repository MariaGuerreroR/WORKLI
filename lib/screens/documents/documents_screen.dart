import 'package:flutter/material.dart';

import '../../models/document_model.dart';
import '../../services/document_service.dart';
import '../../services/project_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/document_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/connection_error_widget.dart';
import '../app_scaffold.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _documentService = DocumentService();
  final _projectService = ProjectService();
  DocumentType? _filterType;
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _documentService.refresh();
    await _projectService.refresh();
    if (mounted) setState(() => _loading = false);
  }

  List<DocumentModel> get _filteredDocuments {
    var docs = _documentService.getAllDocuments();
    if (_filterType != null) {
      docs = docs.where((d) => d.type == _filterType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      docs = docs.where((d) {
        return d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            d.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Documentos',
        currentIndex: 3,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_documentService.connectionFailed) {
      return AppScaffold(
        title: 'Documentos',
        currentIndex: 3,
        body: ConnectionErrorWidget(
          onRetry: () {
            setState(() => _loading = true);
            _loadData();
          },
        ),
      );
    }

    final docs = _filteredDocuments;

    return AppScaffold(
      title: 'Documentos',
      currentIndex: 3,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDocumentDialog,
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
                        label: 'Total Documentos',
                        value: '${_documentService.totalDocuments}',
                        icon: Icons.description,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: MetricCard(
                        label: 'Almacenamiento',
                        value: '${_documentService.totalSizeMb.toStringAsFixed(0)}MB',
                        icon: Icons.cloud_outlined,
                        color: AppColors.info,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: MetricCard(
                        label: 'Artículos',
                        value: '${_documentService.getDocumentsByType(DocumentType.paper).length}',
                        icon: Icons.article,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: AppDimens.spaceXl),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar documentos...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: AppDimens.spaceMd),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', null),
                    const SizedBox(width: AppDimens.spaceSm),
                    ...DocumentType.values.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppDimens.spaceSm),
                        child: _buildFilterChip(type.label, type),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.spaceLg),
              if (docs.isEmpty)
                const EmptyState(
                  icon: Icons.folder_off,
                  title: 'Sin documentos',
                  message: 'No se encontraron documentos con los filtros actuales.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppDimens.spaceSm),
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final project = _projectService.getProjectById(doc.projectId);
                    return Dismissible(
                      key: Key(doc.id),
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
                      onDismissed: (_) async {
                        await _documentService.deleteDocument(doc.id);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Documento "${doc.title}" eliminado'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      },
                      child: DocumentCard(
                        document: doc,
                        projectTitle: project?.title,
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

  Widget _buildFilterChip(String label, DocumentType? type) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
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

  void _showCreateDocumentDialog() {
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
    final tagsCtrl = TextEditingController();
    String selectedProjectId = projects.first.id;
    DocumentType selectedType = DocumentType.other;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo Documento'),
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
                        decoration: const InputDecoration(
                          labelText: 'Nombre del documento',
                          hintText: 'Ej: Protocolo_v3.pdf',
                        ),
                        validator: (v) => Validators.required(v, field: 'El nombre'),
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      DropdownButtonFormField<DocumentType>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: DocumentType.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label),
                                ))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedType = v!),
                      ),
                      const SizedBox(height: AppDimens.spaceMd),
                      TextFormField(
                        controller: tagsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Etiquetas (separadas por comas)',
                          hintText: 'Protocolo, Campo',
                        ),
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
                    final tags = tagsCtrl.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();
                    final now = DateTime.now();
                    final doc = DocumentModel(
                      id: 'temp',
                      projectId: selectedProjectId,
                      title: titleCtrl.text.trim(),
                      type: selectedType,
                      uploadedById: 'u1',
                      tags: tags,
                      createdAt: now,
                      updatedAt: now,
                    );
                    await _documentService.addDocument(doc);
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Documento "${doc.title}" agregado'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
