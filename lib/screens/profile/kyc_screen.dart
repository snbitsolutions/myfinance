import 'package:flutter/material.dart';
import '../../core/app_scaffold.dart';

class KycScreen extends StatelessWidget {
  const KycScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'KYC Verification',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'ID Number (Ghana Card)',
              ),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Date of Birth'),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('KYC submitted for review')),
                );
                Navigator.pop(context);
              },
              child: const Text('Submit KYC'),
            ),
          ],
        ),
      ),
    );
  }
}
