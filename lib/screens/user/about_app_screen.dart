import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About AquaSense'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Center(
              child: Icon(
                Icons.water_rounded,
                size: 80,
                color: Color(0xFF0E6E8A),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'AquaSense',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Center(
              child: Text(
                'v2.4.1',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'AquaSense helps farmers monitor and manage aquaculture ponds efficiently using smart insights and real-time data. Our platform provides comprehensive tools for water quality monitoring, predictive analytics, and automated reporting.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),
            _buildInfoSection('Terms & Privacy', 'Our primary goal is to provide a secure and efficient way to manage your aquaculture operations. By using our platform, you agree to our privacy policy and terms of service. All data collected is stored securely and used only for providing you with the best features and support.'),
            const SizedBox(height: 48),
            const Center(
              child: Text(
                'Contact us: admin@123.com',
                style: TextStyle(color: Color(0xFF0E6E8A), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Text(
          content,
          textAlign: TextAlign.justify,
          style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }
}
