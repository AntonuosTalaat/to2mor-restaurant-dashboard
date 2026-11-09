import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/auth/presentation/screens/LoginScreen.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:restaurantdashboard/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:restaurantdashboard/shared/widgets/primary_button.dart';

class PendingApprovalScreen extends StatefulWidget {
  final String accountStatus;

  const PendingApprovalScreen({super.key, required this.accountStatus});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  IconData get _statusIcon => switch (widget.accountStatus.toLowerCase()) {
    'pending' => Icons.hourglass_top_rounded,
    'suspended' => Icons.pause_circle_outline,
    'blocked' => Icons.block_outlined,
    'under_review' => Icons.rate_review_outlined,
    _ => Icons.warning_amber_rounded,
  };

  Color get _statusColor => switch (widget.accountStatus.toLowerCase()) {
    'pending' => AppColors.warning,
    'suspended' => AppColors.error,
    'blocked' => AppColors.error,
    'under_review' => AppColors.info,
    _ => AppColors.primary,
  };

  String get _statusTitle => switch (widget.accountStatus.toLowerCase()) {
    'pending' => 'حسابك قيد المراجعة',
    'suspended' => 'تم تعليق حسابك مؤقتاً',
    'blocked' => 'تم حظر حسابك',
    'under_review' => 'حسابك قيد المراجعة',
    _ => 'حالة الحساب غير محددة',
  };

  String get _statusMessage => switch (widget.accountStatus.toLowerCase()) {
    'pending' =>
      'نحن نراجع معلومات مطعمك حالياً. ستتلقى إشعاراً عند تفعيل حسابك.',
    'suspended' =>
      'تم تعليق حسابك مؤقتاً. يرجى التواصل مع الدعم الفني لمعرفة السبب.',
    'blocked' =>
      'تم حظر حسابك. للمزيد من المعلومات، يرجى التواصل مع فريق الدعم.',
    'under_review' =>
      'حسابك قيد المراجعة بسبب تحديثات حديثة. عادةً خلال 24-48 ساعة.',
    _ => 'حالة حسابك غير واضحة. يرجى التواصل مع الدعم الفني.',
  };

  List<String> get _actionSteps => switch (widget.accountStatus
      .toLowerCase()) {
    'pending' => [
      'تأكد من صحة جميع المعلومات المدخلة',
      'انتظر رسالة التأكيد عبر البريد الإلكتروني',
      'قد تستغرق المراجعة حتى 48 ساعة',
    ],
    'suspended' => [
      'راجع شروط الاستخدام والسياسات',
      'تواصل مع فريق الدعم الفني',
      'قدم المستندات المطلوبة إن وجدت',
    ],
    'blocked' => [
      'راجع شروط الاستخدام',
      'يمكنك تقديم طعن عبر فريق الدعم',
      'قدم توضيحات أو أدلة داعمة',
    ],
    'under_review' => [
      'لا حاجة لأي إجراء من جانبك',
      'ستتلقى إشعاراً عند انتهاء المراجعة',
      'تحقق من بريدك الإلكتروني بانتظام',
    ],
    _ => [
      'تواصل مع فريق الدعم الفني',
      'قدم رقم مطعمك ومعلومات الاتصال',
      'اشرح المشكلة بوضوح',
    ],
  };

  Future<void> _signOut() async {
    try {
      await context.read<AuthProvider>().signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تسجيل الخروج: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showContactSupportDialog() {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تواصل مع الدعم', textAlign: TextAlign.center),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('يمكنك التواصل معنا عبر:', textAlign: TextAlign.center),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.email, color: AppColors.info),
                  title: Text('support@orderstech.com'),
                  subtitle: Text('البريد الإلكتروني'),
                ),
                ListTile(
                  leading: Icon(Icons.phone, color: AppColors.success),
                  title: Text('+20 123 456 789'),
                  subtitle: Text('الهاتف'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = _statusColor;

    return AuthScaffold(
      maxContentWidth: 560,
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.withOpacity(statusColor, 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(_statusIcon, size: 48, color: AppColors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _statusTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 20),
          AuthFormCard(
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: statusColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'الخطوات التالية',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._actionSteps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            labelAr: 'تواصل مع الدعم',
            onPressed: _showContactSupportDialog,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('تسجيل خروج'),
            style: TextButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final restaurant = auth.restaurant;
              if (restaurant == null) return const SizedBox.shrink();

              return AuthFormCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      'معلومات المطعم',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoItem(
                            label: 'اسم المطعم',
                            value: restaurant.resturantName,
                            icon: Icons.restaurant,
                          ),
                        ),
                        Expanded(
                          child: _InfoItem(
                            label: 'المالك',
                            value: restaurant.ownerName,
                            icon: Icons.person,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, color: scheme.onSurfaceVariant, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
