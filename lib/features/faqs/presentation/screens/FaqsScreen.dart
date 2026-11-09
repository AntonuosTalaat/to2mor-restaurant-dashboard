import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurantdashboard/Models/SettingModel.dart';
import 'package:restaurantdashboard/Providers/SettingProvider.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ استخدم addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      settingsProvider.loadSettings();
      settingsProvider.listenToSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = settingsProvider.settings;

          if (settings == null || settings.faqs.restaurantFAQs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد أسئلة شائعة حالياً',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final faqs = settings.faqs.userFAQs;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _showContactSupport(),
                            icon: const Icon(Icons.headset_mic),
                            tooltip: 'اتصل بالدعم الفني',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.goldLight20.withOpacity(0.2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => _showTipOfTheDay(),
                            icon: const Icon(Icons.lightbulb),
                            tooltip: 'نصيحة اليوم',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.amber.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'الأسئلة الشائعة',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'عدد النتائج: ${faqs.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.builder(
                      itemCount: faqs.length,
                      itemBuilder: (context, index) {
                        return _buildFaqCard(faqs[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFaqCard(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.help_outline, color: Colors.blue, size: 20),
        ),
        title: Text(
          faq.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          textAlign: TextAlign.right,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Text(
                faq.answer,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'اتصل بالدعم الفني',
          textAlign: TextAlign.right,
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('يمكنك التواصل معنا عبر:'),
              const SizedBox(height: 16),
              _buildContactOption(Icons.phone, 'الهاتف', '01234567890', Colors.green),
              const SizedBox(height: 12),
              _buildContactOption(Icons.email, 'البريد الإلكتروني', 'support@restaurant.com', Colors.blue),
              const SizedBox(height: 12),
              _buildContactOption(Icons.chat, 'الدردشة المباشرة', 'متاح 24/7', Colors.purple),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: color),
        ],
      ),
    );
  }

  void _showTipOfTheDay() {
    final tips = [
      'احرص على الرد السريع على الطلبات لزيادة رضا العملاء',
      'قم بتحديث صور أصناف القائمة بانتظام لتبدو أكثر جاذبية',
      'راجع التقارير اليومية لتتبع أداء مطعمك',
      'استجب لتقييمات العملاء لبناء سمعة إيجابية',
      'قدم عروض خاصة في الأوقات الهادئة لزيادة المبيعات',
      'تأكد من تحديث ساعات العمل في حالة تغييرها',
    ];

    final randomTip = tips[DateTime.now().millisecond % tips.length];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('نصيحة اليوم'),
            const SizedBox(width: 8),
            Icon(Icons.lightbulb, color: Colors.amber[700]),
          ],
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              randomTip,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('شكراً'),
          ),
        ],
      ),
    );
  }
}