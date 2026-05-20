import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';

/// Wraps [AsyncValue.when] with default loading and error widgets so screens
/// don't have to repeat the `Center(CircularProgressIndicator)` /
/// `Center(ConnectionErrorWidget)` boilerplate.
class AsyncStateBuilder<T> extends StatelessWidget {
  const AsyncStateBuilder({
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
    this.error,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final WidgetBuilder? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () =>
          loading?.call(context) ??
          const Center(child: CircularProgressIndicator()),
      error: (e, s) {
        if (error != null) return error!(e, s);
        return Center(
          child: ConnectionErrorWidget(
            errorMessage: e.toString(),
            onRetry: onRetry ?? () {},
          ),
        );
      },
      data: data,
    );
  }
}
