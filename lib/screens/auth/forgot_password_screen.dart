import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54, // Modal dark overlay feeling
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF112236),
            borderRadius: BorderRadius.circular(16)
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.water_drop, color: Color(0xFF0E6E8A), size: 48),
              const SizedBox(height: 16),
              const Text('Reset Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Email or Username',
                  filled: true,
                  fillColor: Colors.black12,
                  border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link sent!')));
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E6E8A), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Send Reset Link'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back to login', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 10),
              const Text('We will send a reset instruction link to your registered email.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))
            ],
          ),
        ),
      )
    );
  }
}
