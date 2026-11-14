import 'package:flutter_test/flutter_test.dart';
import 'package:indoor_nav_mobile/features/routing/domain/route_outcome.dart';
import 'package:indoor_nav_mobile/features/routing/domain/route_preference.dart';

void main() {
  test('parses a found route with its preview data', () {
    final route = RouteOutcome.fromJson(const <String, Object?>{
      'status': 'FOUND',
      'preference': 'FASTEST',
      'distanceMeters': 145.4,
      'estimatedDurationSeconds': 182,
      'instructions': <Object?>[
        <String, Object?>{'type': 'START', 'text': 'Start at the entrance.'},
        <String, Object?>{'type': 'ARRIVE', 'text': 'Arrive at the desk.'},
      ],
      'warnings': <Object?>[
        <String, Object?>{'code': 'DETOUR', 'message': 'A corridor is closed.'},
      ],
    });

    expect(route, isA<FoundRoute>());
    final found = route as FoundRoute;
    expect(found.preference, RoutePreference.fastest);
    expect(found.distanceMeters, 145.4);
    expect(found.instructions, hasLength(2));
    expect(found.warnings.single.message, 'A corridor is closed.');
  });

  test('parses no-route as a normal route outcome', () {
    final route = RouteOutcome.fromJson(const <String, Object?>{
      'status': 'NO_ROUTE',
      'preference': 'ACCESSIBLE',
      'noRoute': <String, Object?>{
        'reasonCode': 'ACCESSIBILITY_CONSTRAINT',
        'message': 'No step-free route is available.',
        'obstacles': <Object?>[],
      },
    });

    expect(route, isA<NoRouteOutcome>());
    final noRoute = route as NoRouteOutcome;
    expect(noRoute.preference, RoutePreference.accessible);
    expect(noRoute.message, 'No step-free route is available.');
  });
}
