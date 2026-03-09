enum NavigationType { go, push, pop }

class NavigationEvent {
  final String routeName;
  final NavigationType type;
  final Map<String, String>? pathParameters;
  final Object? extra;
  final DateTime timestamp;

  NavigationEvent({
    required this.routeName,
    required this.type,
    this.pathParameters,
    this.extra,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NavigationEvent.go(String routeName, {Map<String, String>? pathParameters, Object? extra}) =>
      NavigationEvent(routeName: routeName, type: NavigationType.go, pathParameters: pathParameters, extra: extra);

  factory NavigationEvent.push(String routeName, {Map<String, String>? pathParameters, Object? extra}) =>
      NavigationEvent(routeName: routeName, type: NavigationType.push, pathParameters: pathParameters, extra: extra);

  factory NavigationEvent.pop(String routeName) =>
      NavigationEvent(routeName: routeName, type: NavigationType.pop);

  @override
  String toString() => '[NAV] ${type.name} -> $routeName${pathParameters != null ? ' | params: $pathParameters' : ''}';
}
