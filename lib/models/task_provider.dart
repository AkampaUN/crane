import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crane/models/task.dart';
import 'dart:convert';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get pendingTasks => _tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList();
  List<Task> get highPriorityTasks =>
      _tasks.where((t) => t.priority == TaskPriority.high).toList();
  List<Task> get allTasks => _tasks;

  void replaceAllTasks(List<Task> newTasks) {
    _tasks = newTasks;
    notifyListeners();
  }

  Future<void> loadTasks(SharedPreferences prefs) async {
    try {
      final tasksJson = prefs.getStringList('tasks') ?? [];
      _tasks = tasksJson
          .map((json) {
            try {
              return Task.fromJson(jsonDecode(json));
            } catch (e) {
              debugPrint('Error parsing task: $e');
              return null;
            }
          })
          .whereType<Task>()
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      _tasks = [];
    }
  }

  // Private save method with error handling
  Future<void> _saveTasks(SharedPreferences prefs) async {
    try {
      final tasksJson = _tasks
          .map((task) => jsonEncode(task.toJson()))
          .toList();
      await prefs.setStringList('tasks', tasksJson);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
      rethrow;
    }
  }

  // Add task with validation
  Future<void> addTask(Task task) async {
    if (_tasks.any((t) => t.id == task.id)) {
      throw Exception('Task with same ID already exists');
    }
    _tasks.add(task);
    notifyListeners();
    await _persistTasks();
  }

  // Update task with validation
  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index == -1) throw Exception('Task not found');

    _tasks[index] = updatedTask;
    notifyListeners();
    await _persistTasks();
  }

  // Toggle completion status
  Future<void> toggleTaskCompletion(String taskId) async {
    final task = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Task not found'),
    );

    task.status = task.isCompleted ? TaskStatus.pending : TaskStatus.completed;
    notifyListeners();
    await _persistTasks();
  }

  // Remove task
  Future<void> removeTask(String taskId) async {
    final initialLength = _tasks.length;
    _tasks.removeWhere((t) => t.id == taskId);

    if (_tasks.length == initialLength) {
      throw Exception('Task not found');
    }

    notifyListeners();
    await _persistTasks();
  }

  // Filter tasks by priority
  List<Task> tasksByPriority(TaskPriority priority) {
    return _tasks.where((t) => t.priority == priority).toList();
  }

  // Filter tasks by tag
  List<Task> tasksByTag(String tag) {
    return _tasks.where((t) => t.tags.contains(tag)).toList();
  }

  // Get overdue tasks
  List<Task> get overdueTasks {
    return _tasks.where((t) => t.isOverdue).toList();
  }

  // Private method for persisting tasks
  Future<void> _persistTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await _saveTasks(prefs);
  }

  // Generate a unique ID for new tasks
  String generateTaskId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
