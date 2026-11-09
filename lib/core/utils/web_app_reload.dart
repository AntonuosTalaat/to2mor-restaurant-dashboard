import 'web_app_reload_stub.dart'
    if (dart.library.html) 'web_app_reload_web.dart';

Future<void> reloadWebAppToLatest() => reloadWebAppToLatestImpl();
