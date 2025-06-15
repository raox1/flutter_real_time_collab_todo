import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_collab_app/models/task.dart';
import 'package:task_collab_app/services/auth_service.dart';
import 'package:task_collab_app/services/socket_service.dart';
import 'package:task_collab_app/services/task_service.dart';

class TaskDialog extends StatefulWidget {
  final Task? task;
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  TaskDialog({
    this.task,
    required this.titleController,
    required this.descriptionController,
  });

  @override
  _TaskDialogState createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.joinTask(widget.task!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'Edit Task' : 'Create Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            onChanged: isEditing ? _onTaskEdit : null,
          ),
          SizedBox(height: 16),
          TextField(
            controller: widget.descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: isEditing ? _onTaskEdit : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _saveTask,
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  void _onTaskEdit(String value) {
    if (widget.task != null) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.editTask(
        widget.task!.id,
        widget.titleController.text,
        widget.descriptionController.text,
      );
    }
  }

  Future<void> _saveTask() async {
    if (widget.titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final taskService = Provider.of<TaskService>(context, listen: false);
    
    bool success;
    
    if (widget.task != null) {
      success = await taskService.updateTask(
        widget.task!.id,
        widget.titleController.text.trim(),
        widget.descriptionController.text.trim(),
        authService.getAuthHeaders(),
      );
    } else {
      success = await taskService.createTask(
        widget.titleController.text.trim(),
        widget.descriptionController.text.trim(),
        authService.getAuthHeaders(),
      );
    }

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      await taskService.fetchTasks(authService.getAuthHeaders());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save task'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}