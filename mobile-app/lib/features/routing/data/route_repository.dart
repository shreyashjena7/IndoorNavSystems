import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/route_outcome.dart';
import '../domain/route_preference.dart';

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository(ref.watch(apiClientProvider));
});

class RouteRepository {
  RouteRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Result<RouteOutcome>> calculateRoute({
    required int startNodeId,
    required int destinationNodeId,
    required RoutePreference preference,
  }) async {
    try {
      final data = await _apiClient.postObject(
        '/api/navigation/route',
        data: <String, Object?>{
          'startNodeId': startNodeId,
          'destinationNodeId': destinationNodeId,
          'preference': preference.code,
        },
      );
      return Success(RouteOutcome.fromJson(data));
    } on AppFailure catch (failure) {
      return Failure(failure);
    } on FormatException {
      return const Failure(InvalidResponseFailure());
    }
  }
}
