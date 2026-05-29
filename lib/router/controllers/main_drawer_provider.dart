import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [GlobalKey] of the root [Scaffold] in [MainPage].
///
/// Top-level pages now have their own scaffold, so `Scaffold.of(context)`
/// no longer reaches the main scaffold that owns the drawer. Pages use this
/// key to open the drawer from any nested context.
final mainScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});
