import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crane/models/task.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:provider/provider.dart';
import 'package:crane/models/task_provider.dart';

class TaskListScreen extends StatefulWidget {
  final int initialTab;
  const TaskListScreen({super.key, this.initialTab = 0});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Consumer<TaskProvider>(
            builder: (context, taskProvider, _) {
              return _buildTaskList(taskProvider.pendingTasks, 'No pending tasks');
            },
          ),
          Consumer<TaskProvider>(
            builder: (context, taskProvider, _) {
              return _buildTaskList(taskProvider.completedTasks, 'No completed tasks');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String emptyMessage) {
    if (tasks.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(task.title),
          subtitle: Text(task.description ?? ''),
          trailing: Chip(
            label: Text(task.status.name.toUpperCase()),
            backgroundColor: task.status == TaskStatus.completed
                ? Colors.green
                : Colors.orange,
          ),
          onTap: () => _showTaskDetails(context, task),
        );
      },
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description ?? 'No description'),
            const SizedBox(height: 16),
            Text(
              'Due: ${DateFormat('yyyy-MM-dd HH:mm').format(task.dueDate!)}',
            ),
            Text('Status: ${task.status.name}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class TasksScreen extends StatefulWidget {
  final Task? task;
  final int initialTab;

  const TasksScreen({super.key, this.task, this.initialTab = 0});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    // Initialize controllers with task data if editing
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _dateController = TextEditingController(
      text: widget.task?.dueDate != null
          ? DateFormat('yyyy-MM-dd').format(widget.task!.dueDate!)
          : '',
    );
    _timeController = TextEditingController(
      text: widget.task?.dueDate != null
          ? DateFormat('HH:mm').format(widget.task!.dueDate!)
          : '',
    );
  }

  void _initializeNotifications() {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'task_reminders',
          channelName: 'Task Reminders',
          channelDescription: 'Notifications for task deadlines',
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
          importance: NotificationImportance.High,
        ),
      ],
    );
  }

  Future<void> _scheduleNotification(String title, DateTime dueDate) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: dueDate.millisecondsSinceEpoch ~/ 1000,
        channelKey: 'task_reminders',
        title: 'Task Reminder',
        body: 'Your task "$title" is due now!',
      ),
      schedule: NotificationCalendar.fromDate(
        date: dueDate,
        allowWhileIdle: true,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Create Task' : 'Edit Task'),
        actions: [
          if (widget.task != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                if (mounted) {
                  Navigator.pop(context, null);
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date (yyyy-mm-dd)',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: widget.task?.dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null && mounted) {
                        setState(() {
                          _dateController.text = DateFormat('yyyy-MM-dd').format(date);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Time (hh:mm)',
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: widget.task?.dueDate != null
                            ? TimeOfDay.fromDateTime(widget.task!.dueDate!)
                            : TimeOfDay.now(),
                      );
                      if (time != null && mounted) {
                        setState(() {
                          _timeController.text =
                              "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isNotEmpty &&
                    _dateController.text.isNotEmpty &&
                    _timeController.text.isNotEmpty) {
                  try {
                    final dueDate = DateTime.parse(_dateController.text);
                    final timeParts = _timeController.text.split(':');
                    final dueDateTime = DateTime(
                      dueDate.year,
                      dueDate.month,
                      dueDate.day,
                      int.parse(timeParts[0]),
                      int.parse(timeParts[1]),
                    );

                    final task = Task(
                      id: widget.task?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _titleController.text,
                      description: _descriptionController.text,
                      dueDate: dueDateTime,
                      status: widget.task?.status ?? TaskStatus.pending,
                      createdAt: widget.task?.createdAt ?? DateTime.now(),
                    );

                    await _scheduleNotification(task.title, task.dueDate!);
                    if (mounted) {
                      Navigator.pop(context, task);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid date or time format'),
                        ),
                      );
                    }
                  }
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                }
              },
              child: Text(widget.task == null ? 'Create Task' : 'Update Task'),
            ),
          ],
        ),
      ),
    );
  }
}