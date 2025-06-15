import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_collab_app/models/task.dart';
import 'package:task_collab_app/services/auth_service.dart';
import 'package:task_collab_app/services/socket_service.dart';
import 'package:task_collab_app/services/task_service.dart';
import 'package:task_collab_app/widgets/task_dialog.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  void _initializeServices() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final taskService = Provider.of<TaskService>(context, listen: false);
    final socketService = Provider.of<SocketService>(context, listen: false);

    if (authService.token != null) {
      taskService.fetchTasks(authService.getAuthHeaders());
      socketService.connect(authService.token!);
      
      socketService.onTaskUpdated((data) {
        taskService.updateTaskFromSocket(
          data['taskId'],
          data['title'],
          data['description'],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Tasks'),
        actions: [
          Consumer<SocketService>(
            builder: (context, socketService, child) {
              return Icon(
                socketService.isConnected ? Icons.wifi : Icons.wifi_off,
                color: socketService.isConnected ? Colors.green : Colors.red,
              );
            },
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              final authService = Provider.of<AuthService>(context, listen: false);
              final socketService = Provider.of<SocketService>(context, listen: false);
              socketService.disconnect();
              authService.logout();
            },
          ),
        ],
      ),
      body: Consumer<TaskService>(
        builder: (context, taskService, child) {
          if (taskService.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (taskService.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tasks yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first task',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await taskService.fetchTasks(authService.getAuthHeaders());
            },
            child: ListView.builder(
              itemCount: taskService.tasks.length,
              itemBuilder: (context, index) {
                final task = taskService.tasks[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      task.title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description.isNotEmpty)
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        SizedBox(height: 4),
                        Text(
                          'Updated: ${_formatDate(task.updatedAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'collaborate',
                          child: Row(
                            children: [
                              Icon(Icons.group_add),
                              SizedBox(width: 8),
                              Text('Add Collaborator'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showTaskDialog(context, task);
                        } else if (value == 'collaborate') {
                          _showCollaboratorDialog(context, task);
                        }
                      },
                    ),
                    onTap: () => _showTaskDialog(context, task),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(context, null),
        child: Icon(Icons.add),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  void _showTaskDialog(BuildContext context, Task? task) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(text: task?.description ?? '');
    
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        task: task,
        titleController: titleController,
        descriptionController: descriptionController,
      ),
    );
  }

  void _showCollaboratorDialog(BuildContext context, Task task) {
    final userIdController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Collaborator'),
        content: TextField(
          controller: userIdController,
          decoration: InputDecoration(
            labelText: 'User ID',
            hintText: 'Enter user ID to add as collaborator',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final userId = int.tryParse(userIdController.text);
              if (userId != null) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final taskService = Provider.of<TaskService>(context, listen: false);
                
                final success = await taskService.addCollaborator(
                  task.id,
                  userId,
                  authService.getAuthHeaders(),
                );
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Collaborator added successfully' : 'Failed to add collaborator'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}