import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 3),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start animation and session loading in parallel
    final animationFuture = _controller.forward();
    final sessionFuture = ref.read(authServiceProvider).loadSession();

    // Wait for BOTH (minimum animation time of 3 seconds)
    final results = await Future.wait<dynamic>([animationFuture, sessionFuture]);
    final user = results[1] as UserModel?;

    if (mounted) {
      // Update the auth state provider and initialization status
      ref.read(authStateProvider.notifier).state = user;
      ref.read(appInitializedProvider.notifier).state = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B6CA8), Color(0xFF0D4A7A), Color(0xFF0A3A60)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            const Icon(
              Icons.water_drop,
              color: Color(0xFF0E6E8A),
              size: 100,
            ),
            const SizedBox(height: 16),
            const Text(
              'AquaSense',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tagline
            const Text(
              'Tech Beneath the Surface',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading Bar
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Column(
                  children: [
                    SizedBox(
                      width: 220,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Initializing...', 
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          Text(
                            '${(_animation.value * 100).toInt()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 220,
                      height: 4,
                      child: LinearProgressIndicator(
                        value: _animation.value,
                        backgroundColor: const Color(0xFF2A5A8A),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0E6E8A)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
