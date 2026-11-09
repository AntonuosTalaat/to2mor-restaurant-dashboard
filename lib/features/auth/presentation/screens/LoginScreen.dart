import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:restaurantdashboard/Providers/SettingProvider.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/core/utils/firebase_auth_ready.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/auth/presentation/screens/ForgotPassword.dart';
import 'package:restaurantdashboard/features/auth/presentation/screens/PendingApprovalScreen.dart';
import 'package:restaurantdashboard/features/auth/presentation/screens/SignUpScreen.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_brand_mark.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:restaurantdashboard/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:restaurantdashboard/features/sidebar/presentation/screens/main_screen.dart';
import 'package:restaurantdashboard/shared/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isCompanySignupEnabled = true;

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.loadSettings();
      if (!mounted) return;
      setState(() {
        _isCompanySignupEnabled =
            settingsProvider.settings?.isRestaurantSignupEnabled ?? true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCompanySignupEnabled = true);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (authProvider.isLoggedIn && authProvider.restaurant != null) {
        final accountStatus =
            authProvider.restaurant!.accountStatus.toLowerCase();

        if (accountStatus == 'active') {
          await ensureFirebaseAuthReady();
          if (!mounted) return;
          final restaurantId = authProvider.restaurant!.id;
          await context.read<NotificationCubit>().initialize(
            restaurantId,
            force: true,
          );
          if (!mounted) return;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تسجيل الدخول. تحقق من البيانات المدخلة.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthScaffold(
        centerContent: !isDesktop,
        maxContentWidth: isDesktop ? double.infinity : 420,
        padding: EdgeInsets.zero,
        child:
            isDesktop
                ? SizedBox.expand(child: _buildDesktopLayout())
                : FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                      child: Column(
                        children: [
                          const AuthBrandMark(
                            compact: true,
                            size: 68,
                            subtitle: 'إدارة المطعم والطلبات',
                          ),
                          const SizedBox(height: 24),
                          AuthFormCard(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            child: _buildLoginForm(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      // Brand left / form right regardless of RTL text.
      textDirection: TextDirection.ltr,
      children: [
        Expanded(
          flex: 11,
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: const AuthBrandMark(
                    size: 104,
                    alignment: CrossAxisAlignment.center,
                    subtitle:
                        'النظام الأمثل لإدارة المطعم والطلبات\nتابع مبيعاتك وقائمتك بكفاءة',
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 10,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.withOpacity(
                isDark ? AppColors.darkSurface : AppColors.white,
                isDark ? 0.45 : 0.35,
              ),
              border: Border(
                left: BorderSide(
                  color: AppColors.withOpacity(
                    AppColors.primary,
                    isDark ? 0.18 : 0.12,
                  ),
                ),
              ),
            ),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AuthFormCard(
                      padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
                      child: _buildLoginForm(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 22),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildLoginForm() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تسجيل الدخول',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل بياناتك للوصول إلى لوحة التحكم',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            decoration: _fieldDecoration(
              label: 'البريد الإلكتروني',
              hint: 'restaurant@example.com',
              icon: Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال البريد الإلكتروني';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'البريد الإلكتروني غير صحيح';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            decoration: _fieldDecoration(
              label: 'كلمة المرور',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'إظهار' : 'إخفاء',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 22,
                ),
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال كلمة المرور';
              }
              if (value.length < 6) {
                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
              }
              return null;
            },
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPassword()),
                );
              },
              child: const Text(
                'نسيت كلمة المرور؟',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            labelAr: 'تسجيل الدخول',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleLogin,
          ),
          if (_isCompanySignupEnabled) ...[
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'ليس لديك حساب؟',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: const Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
