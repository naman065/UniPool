import 'package:flutter/widgets.dart';
import 'package:unipool/repositories/ride_repository.dart';

class RideRepositoryScope extends InheritedWidget {
  const RideRepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final RideRepository repository;

  static RideRepository of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<RideRepositoryScope>();
    assert(scope != null, 'RideRepositoryScope is missing above this widget.');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(RideRepositoryScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
