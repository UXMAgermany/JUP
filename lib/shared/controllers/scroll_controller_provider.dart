import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scrollControllerProvider =
    NotifierProvider<ScrollControllerNotifier, Map<int, ScrollController>>(
      ScrollControllerNotifier.new,
    );

class ScrollControllerNotifier extends Notifier<Map<int, ScrollController>> {
  @override
  Map<int, ScrollController> build() {
    return {};
  }

  void registerController(int tabIndex, ScrollController controller) {
    state = {...state, tabIndex: controller};
  }

  void unregisterController(int tabIndex) {
    final newState = {...state};
    newState.remove(tabIndex);
    state = newState;
  }

  ScrollController? getController(int tabIndex) {
    return state[tabIndex];
  }

  void scrollToTop(int tabIndex) {
    final controller = getController(tabIndex);
    if (controller != null && controller.hasClients) {
      // Only scroll if not already at the top
      if (controller.position.pixels > 0) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }
}
