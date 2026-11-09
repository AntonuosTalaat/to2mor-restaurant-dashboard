import 'dart:html' as html;

Future<void> reloadWebAppToLatestImpl() async {
  final current = Uri.parse(html.window.location.href);
  final query = Map<String, String>.from(current.queryParameters);
  query['_v'] = DateTime.now().millisecondsSinceEpoch.toString();
  final target = current.replace(queryParameters: query).toString();
  html.window.location.assign(target);
}
