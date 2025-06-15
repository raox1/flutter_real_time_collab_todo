import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:task_collab_app/models/task.dart';

class TaskService extends ChangeNotifier {
  static const String baseUrl = 'https://stripe.lalit.pro';
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> fetchTasks(Map<String, String> headers) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _tasks = data.map((json) => Task.fromJson(json)).toList();
      }
    } catch (e) {
      print('Fetch tasks error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTask(String title, String description, Map<String, String> headers) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: json.encode({
          'title': title,
          'description': description,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Create task error: $e');
      return false;
    }
  }

  Future<bool> updateTask(int taskId, String title, String description, Map<String, String> headers) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: headers,
        body: json.encode({
          'title': title,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        // Update local task
        final index = _tasks.indexWhere((task) => task.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(
            title: title,
            description: description,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Update task error: $e');
      return false;
    }
  }

  Future<bool> addCollaborator(int taskId, int userId, Map<String, String> headers) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/collaborators'),
        headers: headers,
        body: json.encode({
          'userId': userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Add collaborator error: $e');
      return false;
    }
  }

  void updateTaskFromSocket(int taskId, String title, String description) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        title: title,
        description: description,
      );
      notifyListeners();
    }
  }
}