import 'package:jup/features/events/models/event_model.dart';

class FiltersHelper {
  static String getCategoryFilterLabel(EventCategory filter) {
    switch (filter) {
      case EventCategory.sport:
        return 'Sport';
      case EventCategory.music:
        return 'Musik';
      case EventCategory.food:
        return 'Essen';
      case EventCategory.gaming:
        return 'Gaming';
      case EventCategory.diy:
        return 'DIY';
      case EventCategory.other:
        return 'Sonstiges';
    }
  }
}
