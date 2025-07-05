import 'package:flutter/material.dart';

class InviteAcceptScreen extends StatelessWidget {
  final String invitedEmail;

  const InviteAcceptScreen({required this.invitedEmail, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("You're Invited!")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("You've been invited to join CirroCloudApp."),
            Text("Email: $invitedEmail"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup', arguments: invitedEmail);
              },
              child:  const Text("Accept & Sign Up"),
            )
          ],
        ),
      ),
    );
  }
}