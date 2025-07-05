import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crane/models/task.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user tasks
  Future<void> saveTasks(String userId, List<String> tasks) async {
    await _firestore.collection("users").doc(userId).set({
      "tasks": tasks,
      "last_updated": FieldValue.serverTimestamp(),
    },SetOptions(merge: true));
  }

  // Fetch user tasks
   Future<List<Task>> getTasks(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    if (snapshot.exists) {
      final data = snapshot.data()!;
      return (data['tasks'] as List).map((e) => Task.fromJson(e)).toList();
    }
    return [];
  }
}