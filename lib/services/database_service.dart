import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:crane/models/task.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Task>> getTasksStream(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Task.fromJson({
              ...data,
              'id': doc.id, // Include the document ID
            });
          }).toList(),
        );
  }

  Future<void> addTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).set({
      ...task.toJson(),
      'userId': task.id.split('_').first, // Assuming ID contains user ID
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).update({
      ...task.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  Future<void> clearCompletedTasks(List<String> taskIds) async {
    final batch = _firestore.batch();
    for (final id in taskIds) {
      batch.delete(_firestore.collection('tasks').doc(id));
    }
    await batch.commit();
  }

  Future<List<Task>> searchTasks(String userId, String query) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs.map((doc) {
      return Task.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Task>> getTasksByPriority(String userId, TaskPriority priority) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('priority', isEqualTo: priority.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return Task.fromJson({...doc.data(), 'id': doc.id});
          }).toList(),
        );
  }

  Future<List<Task>> getTasks(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting tasks: $e');
      rethrow;
    }
  }

  // Additional method to get pending tasks
  Stream<List<Task>> getPendingTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: TaskStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  // Additional method to get completed tasks
  Stream<List<Task>> getCompletedTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: TaskStatus.completed.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }
}