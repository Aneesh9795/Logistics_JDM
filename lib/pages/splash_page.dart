import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _footerFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Staggered smooth animations
    _logoFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack),
      ),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _footerFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.60, 1.0, curve: Curves.easeIn),
    );

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    // Keep splash visible long enough for smooth entrance animation
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    await ref.read(authProvider.notifier).checkAuthStatus();
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background ambient soft glowing accents
          Positioned(
            top: -size.width * 0.35,
            right: -size.width * 0.35,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryNavy.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.3,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 0.85,
              height: size.width * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandRed.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Animated Polished Logo Box
                  FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 22,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryNavy.withValues(alpha: 0.06),
                              blurRadius: 32,
                              offset: const Offset(0, 14),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: AppColors.brandRed.withValues(alpha: 0.03),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFF1F5F9),
                            width: 1.5,
                          ),
                        ),
                        child: Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            AppConstants.logoAsset,
                            width: 190,
                            height: 95,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 90,
                                height: 90,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryNavy,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    'JMD',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App Title & Badge Section
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: SlideTransition(
                      position: _textSlideAnimation,
                      child: Column(
                        children: [
                          // App Title
                          const Text(
                            AppConstants.appName,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                              letterSpacing: 0.6,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Partner Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryNavy.withValues(alpha: 0.10),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.brandRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Text(
                                  'DELIVERY PARTNER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Tagline
                          const Text(
                            AppConstants.appTagline,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Bottom Loader & Footer Section
                  FadeTransition(
                    opacity: _footerFadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Subtle stylized progress indicator
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.brandRed,
                                ),
                                backgroundColor:
                                    AppColors.primaryNavy.withValues(alpha: 0.08),
                              ),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryNavy,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'Initializing workspace...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Version & Security footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 13,
                              color: AppColors.textMuted.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'v1.0.0 • Secured Delivery Network',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
