import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/auth/presentation/screens/LoginScreen.dart';
import 'package:restaurantdashboard/features/auth/presentation/screens/PendingApprovalScreen.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_brand_mark.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:restaurantdashboard/features/sidebar/presentation/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();

    try {
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 1400)),
        authProvider.checkAuthStatus(),
      ]);

      if (!mounted) return;

      if (authProvider.isLoggedIn && authProvider.restaurant != null) {
        final accountStatus =
            authProvider.restaurant!.accountStatus.toLowerCase();

        if (accountStatus == 'active') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (_) => PendingApprovalScreen(
                    accountStatus: authProvider.restaurant!.accountStatus,
                  ),
            ),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AuthScaffold(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthBrandMark(
                enableShimmer: true,
                showOuterHalo: true,
              ),
              const SizedBox(height: 40),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final statusText =
                      auth.hasCheckedAuth
                          ? (auth.isLoggedIn
                              ? 'جار تحميل البيانات...'
                              : 'جار التحقق من البيانات...')
                          : 'جار التحقق من المصادقة...';

                  return Column(
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'حدث خطأ في التحقق',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.error),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              Text(
                'Powered by OrdersTech',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
