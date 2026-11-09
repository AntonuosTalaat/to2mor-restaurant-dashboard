import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:restaurantdashboard/shared/widgets/primary_button.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_emailSent && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
      _controller
        ..reset()
        ..forward();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final errorMessage = switch (e.code) {
        'user-not-found' => 'لا يوجد حساب بهذا البريد الإلكتروني',
        'invalid-email' => 'البريد الإلكتروني غير صالح',
        'too-many-requests' => 'تم إرسال طلبات كثيرة، حاول مرة أخرى لاحقاً',
        _ => 'حدث خطأ: ${e.message}',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ غير متوقع: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthScaffold(
      showBackButton: true,
      maxContentWidth: 440,
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.withOpacity(AppColors.primary, 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Icon(
                _emailSent ? Icons.mark_email_read_rounded : Icons.lock_reset,
                size: 40,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _emailSent ? 'تم إرسال الرابط!' : 'نسيت كلمة المرور؟',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _emailSent
                  ? 'تحقق من بريدك الإلكتروني لإعادة تعيين كلمة المرور'
                  : 'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            AuthFormCard(
              child:
                  _emailSent
                      ? _buildSuccessContent(theme, scheme)
                      : _buildFormContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              hintText: 'أدخل بريدك الإلكتروني',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال بريدك الإلكتروني';
              }
              if (!value.contains('@')) {
                return 'البريد الإلكتروني غير صالح';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            labelAr: 'إرسال رابط إعادة التعيين',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _sendResetEmail,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'العودة لتسجيل الدخول',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.withOpacity(AppColors.success, 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.withOpacity(AppColors.success, 0.3),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'تم إرسال الرابط إلى:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _emailController.text,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('إعادة إرسال الرابط'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'العودة لتسجيل الدخول',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
