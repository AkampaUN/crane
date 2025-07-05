import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EnhancedProfileScreen extends StatefulWidget {
  const EnhancedProfileScreen({Key? key}) : super(key: key);
  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Unique profile data not covered elsewhere
  String _name = "Alex Johnson";
  String _bio = "Productivity enthusiast | Time management guru";
  String _currentGoal = "Complete project milestone by Friday";
  String _weeklyTarget = "40 focused hours";
  String _timeManagementStyle = "Pomodoro + Time Blocking";
  final List<String> _productivityTools = [
    "Notion",
    "Forest App",
    "Google Calendar",
  ];
  String _quote =
      "Productivity is never an accident. It's always the result of commitment to excellence.";

  // Statistics specific to profile
  final Map<String, String> _weeklyStats = {
    "Focus Sessions": "28",
    "Distractions Blocked": "42",
    "Peak Hours": "10AM-12PM",
    "Task Completion Rate": "88%",
  };

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _editField(String field, String currentValue) {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update your $field"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter new $field"),
          maxLines: field == "Bio" || field == "Quote" ? 3 : 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (field == "Name") {
                  _name = controller.text;
                }
                if (field == "Bio") {
                  _bio = controller.text;
                }
                if (field == "Current Goal") {
                  _currentGoal = controller.text;
                }
                if (field == "Weekly Target") {
                  _weeklyTarget = controller.text;
                }
                if (field == "Time Management Style") {
                  _timeManagementStyle = controller.text;
                }
                if (field == "Quote") {
                  _quote = controller.text;
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _addProductivityTool() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Productivity Tool"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "e.g. Trello, Todoist"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _productivityTools.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: -20,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 58,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : const AssetImage('assets/default_avatar.png')
                                      as ImageProvider,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 40),

              // Name and Bio
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _editField("Name", _name),
                    child: Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _editField("Bio", _bio),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly Stats
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "This Week's Performance",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _weeklyStats.entries.map((entry) {
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Personal Productivity Profile
              _buildSection(
                title: "My Productivity Profile",
                children: [
                  _buildEditableItem(
                    icon: Icons.flag,
                    title: "Current Goal",
                    value: _currentGoal,
                    onTap: () => _editField("Current Goal", _currentGoal),
                  ),
                  _buildEditableItem(
                    icon: Icons.timeline,
                    title: "Weekly Target",
                    value: _weeklyTarget,
                    onTap: () => _editField("Weekly Target", _weeklyTarget),
                  ),
                  _buildEditableItem(
                    icon: Icons.schedule,
                    title: "Time Management Style",
                    value: _timeManagementStyle,
                    onTap: () => _editField(
                      "Time Management Style",
                      _timeManagementStyle,
                    ),
                  ),
                ],
              ),

              // Productivity Tools
              _buildSection(
                title: "My Productivity Tools",
                action: IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: _addProductivityTool,
                ),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _productivityTools
                        .map(
                          (tool) => Chip(
                            label: Text(tool),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _productivityTools.remove(tool);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),

              // Motivational Quote
              _buildSection(
                title: "My Motivation",
                children: [
                  GestureDetector(
                    onTap: () => _editField("Quote", _quote),
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.format_quote,
                              color: Colors.blue.shade300,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _quote,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    List<Widget>? children,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 8),
          if (children != null) ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEditableItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.edit, size: 18, color: Colors.blue),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
