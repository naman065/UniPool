import 'package:flutter/widgets.dart';
import 'package:unipool/repositories/user_repository.dart';

class UserRepositoryScope extends InheritedWidget {
  const UserRepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final UserRepository repository;

  static UserRepository of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<UserRepositoryScope>();
    assert(scope != null, 'UserRepositoryScope is missing above this widget.');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(UserRepositoryScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
