import 'package:flutter/material.dart';

/// Builds [child] only after [tab] is visited, then keeps it alive offstage.
class LazyTabScope<T> extends StatefulWidget {
  const LazyTabScope({
    super.key,
    required this.tab,
    required this.activeTab,
    required this.child,
  });

  final T tab;
  final T activeTab;
  final Widget child;

  @override
  State<LazyTabScope<T>> createState() => _LazyTabScopeState<T>();
}

class _LazyTabScopeState<T> extends State<LazyTabScope<T>>
    with AutomaticKeepAliveClientMixin {
  bool _visited = false;

  @override
  bool get wantKeepAlive => _visited;

  @override
  void initState() {
    super.initState();
    _markVisitedIfActive();
  }

  @override
  void didUpdateWidget(covariant LazyTabScope<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _markVisitedIfActive();
  }

  void _markVisitedIfActive() {
    if (_visited || widget.tab != widget.activeTab) return;
    _visited = true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_visited) return const SizedBox.shrink();
    return RepaintBoundary(child: widget.child);
  }
}
