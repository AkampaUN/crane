import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nationalityContoller = TextEditingController();
  final institutionController = TextEditingController();
  final nameController = TextEditingController();
  final logger = Logger();

  DateTime? dob;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your name' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value != null && value.contains('@') ? null : 'Enter valid email',
              ),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) =>
                    value != null && value.length >= 6 ? null : 'Min 6 characters',
              ),
              TextFormField(
                controller: institutionController,
                decoration: const InputDecoration(labelText: 'Institution'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter institution' : null,
              ),
              
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dob == null
                          ? 'Date of Birth: Not selected'
                          : 'DOB: ${dob!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  TextButton(
                    onPressed: _selectDate,
                    child: const Text('Select DOB'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: signup, child: const Text('Sign Up')),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }


   void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dob = pickedDate;
      });
    }
  }

  void signup() async {
    if (_formKey.currentState!.validate()) {
        try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
   
       logger.i('Name: ${nameController.text}');
      logger.i('Email: ${emailController.text}');
      logger.i('Password: ${passwordController.text}');
      logger.i('Institution: ${institutionController.text}');
      logger.i('DOB: ${dob.toString()}');

      if (!mounted) return;

       Navigator.pushReplacementNamed(context, '/welcome');
  } on FirebaseAuthException catch (e) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signup failed: ${e.message}')),
    );
  }
}
    }
  

    @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    institutionController.dispose();
    nationalityContoller.dispose();
    super.dispose();
  }
}
  