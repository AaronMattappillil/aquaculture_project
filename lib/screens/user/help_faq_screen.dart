import 'package:flutter/material.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFaqItem(
            'How to add a pond?',
            'Navigate to the "Ponds" screen and tap the "+" button at the bottom right. Fill in the required details and save.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            'How to view reports?',
            'Select a pond from your list to enter its dashboard. Tap on the "Reports" tab to view historical data and generated analysis.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            'How alerts work?',
            'Our system monitors water quality sensors in real-time. If any parameter (pH, Oxygen, Temperature) goes outside the safe range, you will receive an instant alert.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF112236),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        iconColor: const Color(0xFF0E6E8A),
        collapsedIconColor: Colors.white,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
