import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crane/models/task.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:provider/provider.dart';
import 'package:crane/models/task_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crane/services/database_service.dart';

class TaskListScreen extends StatefulWidget {
  final int initialTab;
  const TaskListScreen({super.key, this.initialTab = 0});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseService _databaseService;
  String _searchQuery = '';
  TaskPriority? _selectedPriorityFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _databaseService = DatabaseService();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateTask(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFilteredTaskList(TaskStatus.pending),
          _buildFilteredTaskList(TaskStatus.completed),
        ],
      ),
    );
  }

  Widget _buildFilteredTaskList(TaskStatus status) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        List<Task> tasks = status == TaskStatus.pending
            ? taskProvider.pendingTasks
            : taskProvider.completedTasks;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          tasks = tasks
              .where(
                (task) =>
                    task.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (task.description?.toLowerCase() ?? '').contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
        }

        // Apply priority filter
        if (_selectedPriorityFilter != null) {
          tasks = tasks
              .where((task) => task.priority == _selectedPriorityFilter)
              .toList();
        }

        return _buildTaskList(tasks, status);
      },
    );
  }

  Widget _buildTaskList(List<Task> tasks, TaskStatus status) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == TaskStatus.pending
                  ? Icons.hourglass_empty
                  : Icons.check_circle_outline,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              status == TaskStatus.pending
                  ? 'No pending tasks'
                  : 'No completed tasks',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (_searchQuery.isNotEmpty || _selectedPriorityFilter != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedPriorityFilter = null;
                  });
                },
                child: const Text('Clear filters'),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_searchQuery.isNotEmpty || _selectedPriorityFilter != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                if (_searchQuery.isNotEmpty)
                  Chip(
                    label: Text('Search: "$_searchQuery"'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _searchQuery = ''),
                  ),
                if (_selectedPriorityFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Chip(
                      label: Text(
                        'Priority: ${_selectedPriorityFilter!.displayName}',
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () =>
                          setState(() => _selectedPriorityFilter = null),
                      backgroundColor: _selectedPriorityFilter!.color
                          .withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskListItem(task);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskListItem(Task task) {
    return Dismissible(
      key: Key(task.id),
      direction: task.status == TaskStatus.pending
          ? DismissDirection.horizontal
          : DismissDirection.endToStart,
      background: _buildDismissibleBackground(task.status),
      secondaryBackground: _buildCompleteBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right to complete
          if (task.status == TaskStatus.pending) {
            await _updateTaskStatus(context, task);
            return false; // Don't dismiss - let the provider handle it
          }
          return false;
        }
        return true; // Allow delete on swipe left
      },
      onDismissed: (_) => _deleteTask(context, task),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: () => _showTaskDetails(context, task),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: task.status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (task.priority != null)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: task.priority!.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (task.description?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      task.description!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        decoration: task.status == TaskStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: task.isOverdue ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, y • h:mm a').format(task.dueDate!),
                      style: TextStyle(
                        color: task.isOverdue ? Colors.red : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (task.tags.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.label, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            task.tags.take(2).join(', '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (task.tags.length > 2)
                            const Text(
                              ' + more',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleBackground(TaskStatus status) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: status == TaskStatus.pending ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: status == TaskStatus.pending
          ? Alignment.centerLeft
          : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        status == TaskStatus.pending ? Icons.check : Icons.delete,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCompleteBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.check, color: Colors.white),
    );
  }

  Future<void> _showSearchDialog() async {
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Tasks'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter search term'),
          onChanged: (value) => _searchQuery = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _searchQuery),
            child: const Text('Search'),
          ),
        ],
      ),
    );

    if (query != null) {
      setState(() => _searchQuery = query);
    }
  }

  Future<void> _deleteTask(BuildContext context, Task task) async {
    try {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      await provider.removeTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${task.title}"'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showFilterDialog() async {
    final priority = await showDialog<TaskPriority>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Priority'),
        children: [
          ...TaskPriority.values.map(
            (priority) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, priority),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: priority.color,
                      shape: BoxShape.circle,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Text(priority.displayName),
                ],
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Clear filter'),
          ),
        ],
      ),
    );

    setState(() => _selectedPriorityFilter = priority);
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(task.title, style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToEditTask(context, task);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (task.description?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(task.description!),
              ),
            _buildDetailRow(
              Icons.calendar_today,
              DateFormat('MMM d, y • h:mm a').format(task.dueDate!),
            ),
            if (task.priority != null)
              _buildDetailRow(
                Icons.flag,
                'Priority: ${task.priority!.displayName}',
              ),
            if (task.tags.isNotEmpty)
              _buildDetailRow(Icons.label, 'Tags: ${task.tags.join(', ')}'),
            _buildDetailRow(
              Icons.timelapse,
              'Created: ${DateFormat('MMM d, y').format(task.createdAt)}',
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (task.status == TaskStatus.pending)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Mark Complete'),
                    onPressed: () => _updateTaskStatus(context, task),
                  ),
                ElevatedButton(
                  child: const Text('Close'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _navigateToCreateTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TasksScreen()),
    );
  }

  void _navigateToEditTask(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TasksScreen(task: task)),
    );
  }

  Future<void> _updateTaskStatus(BuildContext context, Task task) async {
    try {
      final updatedTask = task.copyWith(status: TaskStatus.completed);
      final provider = Provider.of<TaskProvider>(context, listen: false);

      await _databaseService.updateTask(updatedTask);
      await provider.toggleTaskCompletion(task.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task marked as complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: ${e.toString()}')),
        );
      }
    }
  }
}

class TasksScreen extends StatefulWidget {
  final Task? task;
  final int initialTab;

  const TasksScreen({super.key, this.task, this.initialTab = 0});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  TaskPriority? _selectedPriority;
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'work',
    'personal',
    'urgent',
    'shopping',
    'health',
    'finance',
  ];

  @override
  void initState() {
    super.initState();
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
    _selectedPriority = widget.task?.priority;
    if (widget.task?.tags != null) {
      _selectedTags.addAll(widget.task!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
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
              onPressed: _confirmDeleteTask,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem<TaskPriority>(
                    value: priority,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: priority.color,
                            shape: BoxShape.circle,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                        ),
                        Text(priority.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (priority) {
                  setState(() {
                    _selectedPriority = priority;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: _availableTags.map((tag) {
                  return FilterChip(
                    label: Text(tag),
                    selected: _selectedTags.contains(tag),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Due Date & Time*',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Date is required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: _selectTime,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Time is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveTask,
                  child: Text(
                    widget.task == null ? 'Create Task' : 'Update Task',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
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
  }

  Future<void> _selectTime() async {
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
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (*)')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        return;
      }

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
        id:
            widget.task?.id ??
            '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: dueDateTime,
        status: widget.task?.status ?? TaskStatus.pending,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        priority: _selectedPriority,
        tags: _selectedTags,
        assigneeId: user.uid,
        assignerId: user.uid,
      );

      if (widget.task == null) {
        await DatabaseService().addTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully')),
        );
      } else {
        await DatabaseService().updateTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
      }

      if (dueDateTime.isAfter(DateTime.now())) {
        await _scheduleNotification(task.title, dueDateTime);
      }

      if (mounted) {
        Navigator.pop(context, task);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving task: ${e.toString()}')),
      );
    }
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

  Future<void> _confirmDeleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.task != null) {
      await _deleteTask();
    }
  }

  Future<void> _deleteTask() async {
    try {
      await DatabaseService().deleteTask(widget.task!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: ${e.toString()}')),
        );
      }
    }
  }
}
