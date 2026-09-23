import 'package:flutter/material.dart';

import '../../models/message_model.dart';
import '../../models/notification_model.dart';
import '../../models/project_model.dart';
import '../../services/chat_service.dart';
import '../../services/project_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';
import '../app_scaffold.dart';

class ProjectChatScreen extends StatefulWidget {
  const ProjectChatScreen({super.key});

  @override
  State<ProjectChatScreen> createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends State<ProjectChatScreen> {
  final _chatService = ChatService();
  final _projectService = ProjectService();
  final _notificationService = NotificationService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedProjectId;
  bool _loadingProjects = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _chatService.setCurrentUserId(user?.id);
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    await _projectService.refresh();
    final projects = _projectService.getAllProjects();
    await Future.wait(projects.map((p) => _chatService.ensureLoaded(p.id)));
    if (mounted) setState(() => _loadingProjects = false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openProject(String projectId) {
    setState(() => _selectedProjectId = projectId);
    _chatService.markAsRead(projectId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _backToList() {
    setState(() => _selectedProjectId = null);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateSeparatorLabel(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(date, now)) return 'Hoy';
    if (_isSameDay(date, yesterday)) return 'Ayer';
    return Helpers.formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProjects) {
      return AppScaffold(
        title: 'Chat de Proyecto',
        currentIndex: 4,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final projects = _projectService.getAllProjects();
    final currentUser = AuthService.instance.currentUser;

    if (_selectedProjectId == null) {
      return AppScaffold(
        title: 'Chat de Proyecto',
        currentIndex: 4,
        body: _buildProjectList(projects, currentUser?.id),
      );
    }

    final selectedProject = _projectService.getProjectById(_selectedProjectId!);
    if (selectedProject == null) {
      return AppScaffold(
        title: 'Chat de Proyecto',
        currentIndex: 4,
        body: _buildProjectList(projects, currentUser?.id),
      );
    }

    final messages = _chatService.getMessagesForProject(_selectedProjectId!);

    return AppScaffold(
      title: Helpers.truncate(selectedProject.title, 30),
      currentIndex: 4,
      body: Column(
        children: [
          _buildChatHeader(selectedProject),
          Expanded(
            child: messages.isEmpty
                ? const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Sin mensajes',
                    message: 'Sé el primero en escribir en este chat.',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppDimens.spaceLg),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final showDateSeparator = i == 0 ||
                          !_isSameDay(messages[i - 1].sentAt, messages[i].sentAt);
                      return Column(
                        children: [
                          if (showDateSeparator)
                            _buildDateSeparator(messages[i].sentAt),
                          _buildMessageBubble(messages[i]),
                        ],
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildProjectList(List<ProjectModel> projects, String? currentUserId) {
    if (projects.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_off,
        title: 'Sin proyectos',
        message: 'No hay proyectos disponibles para chatear.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.spaceSm),
      itemBuilder: (_, i) {
        final p = projects[i];
        final projectMessages = _chatService.getMessagesForProject(p.id);
        final unread = currentUserId != null
            ? _chatService.getUnreadCount(p.id, currentUserId)
            : 0;
        final lastMsg = _chatService.getLastMessage(p.id);

        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openProject(p.id),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.spaceLg),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    ),
                    child: const Icon(Icons.folder, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppDimens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (lastMsg != null)
                          Text(
                            '${lastMsg.senderName}: ${lastMsg.content}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            '${p.memberIds.length} miembros · Sin mensajes aún',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      margin: const EdgeInsets.only(left: AppDimens.spaceSm),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Icon(Icons.chevron_right, color: AppColors.textMuted, size: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDimens.spaceMd),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          _dateSeparatorLabel(date),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader(ProjectModel project) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceLg,
        vertical: AppDimens.spaceMd,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: _backToList,
            tooltip: 'Volver a proyectos',
          ),
          const SizedBox(width: AppDimens.spaceSm),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
            child: const Icon(Icons.folder, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppDimens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${project.memberIds.length} miembros',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.people_outline, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isMe = message.senderId == AuthService.instance.currentUser?.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.spaceMd),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                Helpers.initialsFromName(message.senderName),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.spaceSm),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spaceMd,
                vertical: AppDimens.spaceSm + 2,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppDimens.radiusM),
                  topRight: const Radius.circular(AppDimens.radiusM),
                  bottomLeft: Radius.circular(isMe ? AppDimens.radiusM : 4),
                  bottomRight: Radius.circular(isMe ? 4 : AppDimens.radiusM),
                ),
                border: isMe ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Helpers.formatTime(message.sentAt)}${message.isEdited ? ' · editado' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceMd),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: AppDimens.spaceSm),
          IconButton(
            onPressed: _sending ? null : _sendMessage,
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedProjectId == null) return;

    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final message = MessageModel(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      projectId: _selectedProjectId!,
      senderId: user.id,
      senderName: user.name,
      content: _messageController.text.trim(),
      sentAt: DateTime.now(),
    );

    _messageController.clear();
    setState(() => _sending = true);
    try {
      await _chatService.sendMessage(message);
      _chatService.markAsRead(_selectedProjectId!);

      final project = _projectService.getProjectById(_selectedProjectId!);
      final otherMembers = project?.memberIds.where((id) => id != user.id).toList() ?? [];
      if (otherMembers.isNotEmpty) {
        _notificationService.addLocalNotification(
          NotificationModel(
            id: 'n${DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.messageReceived,
            title: 'Nuevo mensaje en ${project?.title ?? "proyecto"}',
            body: '${user.name}: ${message.content}',
            projectId: _selectedProjectId,
            createdAt: DateTime.now(),
          ),
        );
      }

      setState(() => _sending = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo enviar el mensaje'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
