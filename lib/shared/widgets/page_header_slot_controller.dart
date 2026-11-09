import 'package:flutter/widgets.dart';

/// Lets the active page park 1–2 actions next to header refresh/notifications.
class PageHeaderSlotController extends ChangeNotifier {
  Object? _owner;
  List<Widget> _actions = const [];

  Object? get owner => _owner;
  List<Widget> get actions => _actions;

  void setActions(Object owner, List<Widget> actions) {
    _owner = owner;
    _actions = List<Widget>.unmodifiable(actions);
    notifyListeners();
  }

  void clear(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _actions = const [];
    notifyListeners();
  }
}
