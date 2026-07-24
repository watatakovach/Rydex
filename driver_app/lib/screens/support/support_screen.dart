import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RydeX Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose an option below to get assistance.',
          ),

          const SizedBox(height: 24),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.chat_outlined,
              ),
              title: const Text(
                'Contact Support',
              ),
              subtitle: const Text(
                'Chat with RydeX support',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.report_problem_outlined,
              ),
              title: const Text(
                'Report a Problem',
              ),
              subtitle: const Text(
                'Report an issue with a ride',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.help_outline,
              ),
              title: const Text(
                'Help Center',
              ),
              subtitle: const Text(
                'Find answers to common questions',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.emergency_outlined,
              ),
              title: const Text(
                'Emergency',
              ),
              subtitle: const Text(
                'Get emergency assistance',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}