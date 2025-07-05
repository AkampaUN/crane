import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crane/models/task_provider.dart';
import 'package:crane/Screens/createtask_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:crane/models/task.dart';
import 'package:crane/Screens/invite_screen.dart';
import 'package:crane/Screens/setting_screen.dart';
import 'package:crane/Screens/mymanager_screen.dart';
import 'package:crane/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedTaskType = 'Pending';
  late DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _db = DatabaseService();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    await taskProvider.loadTasks(prefs);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firestoreTasks = await _db.getTasks(user.uid);
      if (firestoreTasks.isEmpty) {
        taskProvider.replaceAllTasks(firestoreTasks);
        // Update last sync time
        await prefs.setString('last_firestore_sync', DateTime.now().toString());
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await FirebaseAuth.instance.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final pendingTasks = taskProvider.pendingTasks;
        final completedTasks = taskProvider.completedTasks;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          drawer: Drawer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue, Color.fromARGB(255, 128, 24, 55)],
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Colors.blue.shade800),
                    child: const Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.white),
                    title: const Text(
                      'Home',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.task, color: Colors.white),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tasks',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: selectedTaskType,
                            dropdownColor: Colors.blue.shade700,
                            underline: Container(),
                            isExpanded: true,
                            hint: const Text(
                              'Select Task Type',
                              style: TextStyle(color: Colors.white70),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'Pending',
                                child: Text(
                                  'Pending (${pendingTasks.length})',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Completed',
                                child: Text(
                                  'Completed (${completedTasks.length})',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => selectedTaskType = value);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskListScreen(
                                    initialTab: value == 'Pending' ? 0 : 1,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info, color: Colors.white),
                    title: const Text(
                      '15 time management guide',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyManagerScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info, color: Colors.white),
                    title: const Text(
                      'Invite',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InviteScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.white),
                    title: const Text(
                      'Settings',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      logout(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildTaskSection(
                            title:
                                'Pending (${taskProvider.pendingTasks.length})',
                            tasks: taskProvider.pendingTasks,
                            emptyMessage: 'No pending tasks',
                          ),
                          const SizedBox(height: 20),
                          _buildTaskSection(
                            title:
                                'Completed (${taskProvider.completedTasks.length})',
                            tasks: taskProvider.completedTasks,
                            emptyMessage: 'No completed tasks',
                            isCompleted: true,
                          ),
                          const SizedBox(height: 20),
                          _buildPrioritySection(taskProvider),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Opacity(
                    opacity: 0.1,
                    child: Text(
                      'Akampa',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TasksScreen()),
            ),
            backgroundColor: Colors.blue.shade700,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildTaskSection({
    required String title,
    required List<Task> tasks,
    required String emptyMessage,
    bool isCompleted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, isCompleted),
        const SizedBox(height: 8),
        tasks.isEmpty
            ? _buildEmptyState(emptyMessage)
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) => _buildTaskItem(tasks[index]),
              ),
      ],
    );
  }

  Widget _buildPrioritySection(TaskProvider taskProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Priority Tasks', false),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TaskPriority.values.map((priority) {
              final tasks = taskProvider.tasksByPriority(priority);
              final priorityColor = priority.color;
              final backgroundColor = Color.fromRGBO(
                (priorityColor.red * 255.0).round() & 0xff,
                (priorityColor.green * 255.0).round() & 0xff,
                (priorityColor.blue * 255.0).round() & 0xff,
                0.5,
              );
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  label: Text('${priority.displayName} (${tasks.length})'),
                  color: WidgetStatePropertyAll(backgroundColor),
                  labelStyle: TextStyle(color: priority.color),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCompleted ? Colors.green.shade800 : Colors.blue.shade800,
            ),
          ),
          const Spacer(),
          if (isCompleted)
            TextButton(
              onPressed: () => _clearCompletedTasks(context),
              child: const Text('Clear All'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Dismissible(
      key: Key(task.id),
      background: _buildDismissibleBackground(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteTask(context, task),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _editTask(context, task),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _buildCompletionCheckbox(task),
                const SizedBox(width: 8),
                _buildTaskDetails(task),
                if (task.priority != null) _buildPriorityBadge(task.priority!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _buildCompletionCheckbox(Task task) {
    return Checkbox(
      value: task.isCompleted,
      onChanged: (_) => _toggleTaskCompletion(context, task),
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        return states.contains(WidgetState.selected)
            ? Colors.green
            : Colors.grey;
      }),
    );
  }

  Widget _buildTaskDetails(Task task) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : Colors.black87,
            ),
          ),
          if (task.description?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                task.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          if (task.dueDate != null) _buildDueDate(task),
        ],
      ),
    );
  }

  Widget _buildDueDate(Task task) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 14,
            color: task.isOverdue ? Colors.red : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            'Due: ${task.formattedDueDate}',
            style: TextStyle(
              color: task.isOverdue ? Colors.red : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        priority.uppercaseName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Future<void> _editTask(BuildContext context, Task task) async {
    final updatedTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (context) => TasksScreen(task: task)),
    );
    if (updatedTask != null && context.mounted) {
      Provider.of<TaskProvider>(context, listen: false).updateTask(updatedTask);
    }
  }

  Future<void> _toggleTaskCompletion(BuildContext context, Task task) async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    await provider.toggleTaskCompletion(task.id);
  }

  Future<void> _deleteTask(BuildContext context, Task task) async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    await provider.removeTask(task.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${task.title}"'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _clearCompletedTasks(BuildContext context) async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final completedIds = provider.completedTasks.map((t) => t.id).toList();
    for (final id in completedIds) {
      await provider.removeTask(id);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cleared all completed tasks')),
      );
    }
  }
}
