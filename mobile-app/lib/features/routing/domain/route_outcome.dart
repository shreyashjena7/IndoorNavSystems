import 'route_preference.dart';

sealed class RouteOutcome {
  const RouteOutcome({required this.preference});

  factory RouteOutcome.fromJson(Map<String, Object?> json) {
    final preference = RoutePreference.fromCode(
      _requiredString(json, 'preference'),
    );
    return switch (_requiredString(json, 'status')) {
      'FOUND' => FoundRoute.fromJson(json, preference),
      'NO_ROUTE' => NoRouteOutcome.fromJson(json, preference),
      final status => throw FormatException('Unknown route status: $status.'),
    };
  }

  final RoutePreference preference;
}

class FoundRoute extends RouteOutcome {
  const FoundRoute({
    required super.preference,
    required this.distanceMeters,
    required this.estimatedDurationSeconds,
    required this.instructions,
    required this.warnings,
  });

  factory FoundRoute.fromJson(
    Map<String, Object?> json,
    RoutePreference preference,
  ) {
    return FoundRoute(
      preference: preference,
      distanceMeters: _requiredNumber(json, 'distanceMeters'),
      estimatedDurationSeconds: _requiredInt(json, 'estimatedDurationSeconds'),
      instructions: _objectList(
        json,
        'instructions',
      ).map(RouteInstruction.fromJson).toList(growable: false),
      warnings: _objectList(
        json,
        'warnings',
      ).map(RouteWarning.fromJson).toList(growable: false),
    );
  }

  final double distanceMeters;
  final int estimatedDurationSeconds;
  final List<RouteInstruction> instructions;
  final List<RouteWarning> warnings;
}

class NoRouteOutcome extends RouteOutcome {
  const NoRouteOutcome({required super.preference, required this.message});

  factory NoRouteOutcome.fromJson(
    Map<String, Object?> json,
    RoutePreference preference,
  ) {
    final noRoute = _requiredObject(json, 'noRoute');
    return NoRouteOutcome(
      preference: preference,
      message: _requiredString(noRoute, 'message'),
    );
  }

  final String message;
}

class RouteInstruction {
  const RouteInstruction({required this.type, required this.text});

  factory RouteInstruction.fromJson(Map<String, Object?> json) {
    return RouteInstruction(
      type: _requiredString(json, 'type'),
      text: _requiredString(json, 'text'),
    );
  }

  final String type;
  final String text;
}

class RouteWarning {
  const RouteWarning({required this.message});

  factory RouteWarning.fromJson(Map<String, Object?> json) {
    return RouteWarning(message: _requiredString(json, 'message'));
  }

  final String message;
}

Map<String, Object?> _requiredObject(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map<Object?, Object?>) {
    throw FormatException('$key must be an object.');
  }
  final object = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$key contains a non-string key.');
    }
    object[entry.key as String] = entry.value;
  }
  return object;
}

List<Map<String, Object?>> _objectList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List<Object?>) {
    throw FormatException('$key must be a list.');
  }
  return value
      .map((item) {
        if (item is! Map<Object?, Object?>) {
          throw FormatException('$key contains a non-object value.');
        }
        final object = <String, Object?>{};
        for (final entry in item.entries) {
          if (entry.key is! String) {
            throw FormatException('$key contains a non-string key.');
          }
          object[entry.key as String] = entry.value;
        }
        return object;
      })
      .toList(growable: false);
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('$key must be an integer.');
  }
  return value;
}

double _requiredNumber(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('$key must be a number.');
  }
  return value.toDouble();
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}
