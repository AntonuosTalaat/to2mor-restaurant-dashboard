import 'package:url_launcher/url_launcher.dart';

class LauncherUtils {
  /// Open phone dialer with number
  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    if (!await launchUrl(phoneUri)) {
      throw 'Could not launch phone dialer';
    }
  }

  static Future<void> openGoogleMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final String url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final uri = Uri.parse(url);

    if (!await canLaunchUrl(uri)) {
      throw 'Could not open Google Maps';
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
