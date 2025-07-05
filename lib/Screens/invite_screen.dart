import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final emailController = TextEditingController();
  final taskController = TextEditingController();
  final dueDateController = TextEditingController();
  bool isLoading = false;
  DateTime? dueDate;
  List<Map<String, dynamic>> assignedTasks = [];
  bool showTaskForm = false;

  @override
  void initState() {
    super.initState();
    _loadAssignedTasks();
  }

  Future<void> _loadAssignedTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assigneeEmail', isEqualTo: user.email)
          .orderBy('dueDate', descending: false)
          .get();

      setState(() {
        assignedTasks = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'],
            'description': data['description'],
            'dueDate': (data['dueDate'] as Timestamp).toDate(),
            'status': data['status'],
            'assignerName': data['assignerName'],
            'createdAt': (data['createdAt'] as Timestamp).toDate(),
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load tasks")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> sendInvite(String email) async {
    setState(() => isLoading = true);
    final callable = FirebaseFunctions.instance.httpsCallable('sendInviteEmail');

    try {
      final result = await callable.call({
        'email': email,
        'inviterName': 'Akampa Amos',
      });

      if (!mounted) return;

      if (result.data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invite sent!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${result.data['error']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send invite")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> assignTask(String email) async {
    if (taskController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a task title")));
      return;
    }

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        'title': taskController.text,
        'description': 'Task description', // You can add another field for this
        'assigneeEmail': email,
        'assignerId': user?.uid,
        'assignerName': user?.displayName ?? 'Akampa Amos',
        'status': 'pending',
        'dueDate': dueDate ?? DateTime.now().add(const Duration(days: 7)),
        'createdAt': DateTime.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task assigned successfully!")));
      
      // Reset form
      taskController.clear();
      dueDateController.clear();
      setState(() {
        dueDate = null;
        showTaskForm = false;
      });
      
      // Reload tasks
      await _loadAssignedTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to assign task")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    setState(() => isLoading = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'status': newStatus});
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task status updated!")));
      
      await _loadAssignedTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update task status")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != dueDate) {
      setState(() {
        dueDate = picked;
        dueDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invite & Assign Tasks")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Invite Section
              const Text("Invite User", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Enter email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => sendInvite(emailController.text.trim()),
                child: const Text("Send Invite"),
              ),
              
              const Divider(height: 40),
              
              // Task Assignment Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Assign Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(showTaskForm ? Icons.close : Icons.add),
                    onPressed: () => setState(() => showTaskForm = !showTaskForm),
                  ),
                ],
              ),
              
              if (showTaskForm) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(
                    labelText: "Task Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dueDateController,
                  decoration: InputDecoration(
                    labelText: "Due Date",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDueDate(context),
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () => assignTask(emailController.text.trim()),
                  child: const Text("Assign Task"),
                ),
                const SizedBox(height: 20),
              ],
              
              // Assigned Tasks List
              const Text("Your Assigned Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : assignedTasks.isEmpty
                      ? const Text("No tasks assigned yet")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: assignedTasks.length,
                          itemBuilder: (context, index) {
                            final task = assignedTasks[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                title: Text(task['title']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Due: ${task['dueDate'].toString().split(' ')[0]}"),
                                    Text("Status: ${task['status']}"),
                                    Text("From: ${task['assignerName']}"),
                                  ],
                                ),
                                trailing: task['status'] == 'pending'
                                    ? IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () => updateTaskStatus(task['id'], 'completed'),
                                      )
                                    : const Icon(Icons.check_circle, color: Colors.green),
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
}