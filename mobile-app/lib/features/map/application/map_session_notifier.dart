import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/result.dart';
import '../../buildings/data/building_repository.dart';
import '../../buildings/domain/building.dart';
import '../../floors/data/floor_repository.dart';
import '../../floors/domain/floor.dart';
import '../../search/domain/destination.dart';
import '../../search/domain/start_location.dart';
import '../../routing/data/route_repository.dart';
import '../../routing/domain/route_outcome.dart';
import '../../routing/domain/route_preference.dart';
import '../data/floor_map_repository.dart';
import '../domain/floor_map.dart';

final mapSessionProvider =
    NotifierProvider<MapSessionNotifier, MapSessionState>(
      MapSessionNotifier.new,
    );

class MapSessionNotifier extends Notifier<MapSessionState> {
  @override
  MapSessionState build() => const MapSessionLoading();

  Future<void> openBuilding(int buildingId) async {
    state = const MapSessionLoading();
    final buildingResult = await ref
        .read(buildingRepositoryProvider)
        .fetchBuilding(buildingId);
    final floorsResult = await ref
        .read(floorRepositoryProvider)
        .fetchFloors(buildingId);

    switch ((buildingResult, floorsResult)) {
      case (
        Success<BuildingDetail>(value: final building),
        Success<List<Floor>>(value: final floors),
      ):
        final defaultFloor = _floorForId(building.defaultFloorId, floors);
        if (defaultFloor == null) {
          state = const MapSessionFailure(InvalidResponseFailure());
          return;
        }
        await _loadFloor(building, floors, defaultFloor);
      case (Failure<BuildingDetail>(error: final error), _):
        state = MapSessionFailure(_asFailure(error));
      case (_, Failure<List<Floor>>(error: final error)):
        state = MapSessionFailure(_asFailure(error));
    }
  }

  Future<void> selectFloor(int floorId) async {
    final current = state;
    if (current is! MapSessionReady || current.floorMap.floor.id == floorId) {
      return;
    }
    final floor = _floorForId(floorId, current.floors);
    if (floor == null) {
      return;
    }
    await _loadFloor(
      current.building,
      current.floors,
      floor,
      destination: current.destination,
      start: current.start,
      preference: current.preference,
      route: current.route,
    );
  }

  void setDestination(Destination destination) {
    final current = state;
    if (current is! MapSessionReady) {
      return;
    }
    state = MapSessionReady(
      building: current.building,
      floors: current.floors,
      floorMap: current.floorMap,
      destination: destination,
      start: current.start,
      preference: current.preference,
    );
  }

  void setStart(StartLocation start) {
    final current = state;
    if (current is! MapSessionReady) {
      return;
    }
    state = MapSessionReady(
      building: current.building,
      floors: current.floors,
      floorMap: current.floorMap,
      destination: current.destination,
      start: start,
      preference: current.preference,
    );
  }

  Future<void> setPreference(RoutePreference preference) async {
    final current = state;
    if (current is! MapSessionReady) {
      return;
    }
    state = MapSessionReady(
      building: current.building,
      floors: current.floors,
      floorMap: current.floorMap,
      destination: current.destination,
      start: current.start,
      preference: preference,
    );
    if (current.start != null && current.destination != null) {
      await calculateRoute();
    }
  }

  Future<void> calculateRoute() async {
    final current = state;
    if (current is! MapSessionReady ||
        current.start == null ||
        current.destination == null ||
        current.isCalculating) {
      return;
    }
    state = MapSessionReady(
      building: current.building,
      floors: current.floors,
      floorMap: current.floorMap,
      destination: current.destination,
      start: current.start,
      preference: current.preference,
      isCalculating: true,
    );
    final result = await ref
        .read(routeRepositoryProvider)
        .calculateRoute(
          startNodeId: current.start!.id,
          destinationNodeId: current.destination!.nodeId,
          preference: current.preference,
        );
    state = switch (result) {
      Success<RouteOutcome>(value: final route) => MapSessionReady(
        building: current.building,
        floors: current.floors,
        floorMap: current.floorMap,
        destination: current.destination,
        start: current.start,
        preference: current.preference,
        route: route,
      ),
      Failure<RouteOutcome>(error: final error) => MapSessionReady(
        building: current.building,
        floors: current.floors,
        floorMap: current.floorMap,
        destination: current.destination,
        start: current.start,
        preference: current.preference,
        routeFailure: _asFailure(error),
      ),
    };
  }

  Future<void> _loadFloor(
    BuildingDetail building,
    List<Floor> floors,
    Floor floor, {
    Destination? destination,
    StartLocation? start,
    RoutePreference preference = RoutePreference.shortest,
    RouteOutcome? route,
  }) async {
    state = const MapSessionLoading();
    final mapResult = await ref
        .read(floorMapRepositoryProvider)
        .fetchFloorMap(floor.id);
    state = switch (mapResult) {
      Success<FloorMap>(value: final floorMap) => MapSessionReady(
        building: building,
        floors: floors,
        floorMap: floorMap,
        destination: destination,
        start: start,
        preference: preference,
        route: route,
      ),
      Failure<FloorMap>(error: final error) => MapSessionFailure(
        _asFailure(error),
      ),
    };
  }

  Floor? _floorForId(int floorId, List<Floor> floors) {
    for (final floor in floors) {
      if (floor.id == floorId) {
        return floor;
      }
    }
    return null;
  }

  AppFailure _asFailure(Exception error) {
    return error is AppFailure ? error : const InvalidResponseFailure();
  }
}

sealed class MapSessionState {
  const MapSessionState();
}

class MapSessionLoading extends MapSessionState {
  const MapSessionLoading();
}

class MapSessionReady extends MapSessionState {
  const MapSessionReady({
    required this.building,
    required this.floors,
    required this.floorMap,
    this.destination,
    this.start,
    this.preference = RoutePreference.shortest,
    this.route,
    this.routeFailure,
    this.isCalculating = false,
  });

  final BuildingDetail building;
  final List<Floor> floors;
  final FloorMap floorMap;
  final Destination? destination;
  final StartLocation? start;
  final RoutePreference preference;
  final RouteOutcome? route;
  final AppFailure? routeFailure;
  final bool isCalculating;
}

class MapSessionFailure extends MapSessionState {
  const MapSessionFailure(this.failure);

  final AppFailure failure;
}
