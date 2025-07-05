import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

enum TaskStatus {
  pending,
  completed,
}

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  TaskStatus status; // Changed from isCompleted to status enum
  final DateTime createdAt;
  final TaskPriority? priority;
  final List<String> tags;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.status = TaskStatus.pending, // Default to pending
    required this.createdAt,
    this.priority,
    this.tags = const [],
  });

  // Helper getters (maintained for backward compatibility)
  bool get isCompleted => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;
  bool get isOverdue =>
      dueDate != null && isPending && dueDate!.isBefore(DateTime.now());
  bool get hasDueDate => dueDate != null;

  String get formattedDueDate => hasDueDate
      ? DateFormat('yyyy-MM-dd HH:mm').format(dueDate!)
      : 'No due date';

  String get formattedCreatedDate => DateFormat('yyyy-MM-dd').format(createdAt);

  String get priorityLabel => priority?.name.toUpperCase() ?? 'NONE';

  // Convert to/from Map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'status': status.name, // Store enum as string
      'createdAt': createdAt.toIso8601String(),
      'priority': priority?.name,
      'tags': tags,
    };
  }

  factory Task.fromJson(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.pending, // Default if not found
      ),
      createdAt: DateTime.parse(map['createdAt']),
      priority: map['priority'] != null
          ? TaskPriority.values.byName(map['priority'])
          : null,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Copy with method for updates
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    DateTime? createdAt,
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
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
    );
  }

  // Override equality comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum TaskPriority {
  low,
  medium,
  high,
  critical;

  String get uppercaseName => name.toUpperCase();
  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case TaskPriority.low: return 'Low Priority';
      case TaskPriority.medium: return 'Medium Priority';
      case TaskPriority.high: return 'High Priority';
      case TaskPriority.critical: return 'Critical Priority';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low: return Colors.green;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.high: return Colors.red;
      case TaskPriority.critical: return Colors.purple;
    }
  }
}