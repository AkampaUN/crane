import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { pending, completed }

enum TaskPriority { low, medium, high, critical }

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String assigneeId;
  final String assignerId;
  TaskStatus status;
  final DateTime createdAt;
  final TaskPriority? priority;
  final List<String> tags;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.status = TaskStatus.pending,
    DateTime? createdAt,
    required this.assigneeId,
    required this.assignerId,
    this.priority,
    this.tags = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  // Factory constructor for Firestore documents
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      dueDate: data['dueDate']?.toDate(),
      assigneeId: data['assigneeId'],
      assignerId: data['assignerId'],
      createdAt: data['createdAt']?.toDate(),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: data['priority'] != null
          ? TaskPriority.values.firstWhere(
              (e) => e.toString().split('.').last == data['priority'],
            )
          : null,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'assigneeId': assigneeId,
      'assignerId': assignerId,
      'createdAt': createdAt,
      'status': status.toString().split('.').last,
      'priority': priority?.toString().split('.').last,
      'tags': tags,
    };
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'assigneeId': assigneeId,
      'assignerId': assignerId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority?.name,
      'tags': tags,
    };
  }

  // Factory constructor from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      assigneeId: json['assigneeId'],
      assignerId: json['assignerId'],
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      priority: json['priority'] != null
          ? TaskPriority.values.byName(json['priority'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  // Helper getters
  bool get isCompleted => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;
  bool get isOverdue =>
      !isCompleted && dueDate != null && dueDate!.isBefore(DateTime.now());
  bool get hasDueDate => dueDate != null;

  String get formattedDueDate => hasDueDate
      ? DateFormat('yyyy-MM-dd HH:mm').format(dueDate!)
      : 'No due date';

  String get formattedCreatedDate => DateFormat('yyyy-MM-dd').format(createdAt);

  String get priorityLabel => priority?.name.toUpperCase() ?? 'NONE';

  // Copy with method for updates
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    DateTime? createdAt,
    String? assigneeId,
    String? assignerId,
    TaskPriority? priority,
    List<String>? tags,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      assigneeId: assigneeId ?? this.assigneeId,
      assignerId: assignerId ?? this.assignerId,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// TaskPriority extension for additional functionality
extension TaskPriorityExtension on TaskPriority {
  String get uppercaseName => name.toUpperCase();

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low Priority';
      case TaskPriority.medium:
        return 'Medium Priority';
      case TaskPriority.high:
        return 'High Priority';
      case TaskPriority.critical:
        return 'Critical Priority';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.critical:
        return Colors.purple;
    }
  }
}
