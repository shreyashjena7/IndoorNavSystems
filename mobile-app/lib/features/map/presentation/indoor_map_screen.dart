import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/full_state_view.dart';
import '../../floors/domain/floor.dart';
import '../../routing/domain/route_outcome.dart';
import '../../routing/domain/route_preference.dart';
import '../application/map_session_notifier.dart';
import '../domain/floor_map.dart';

class IndoorMapScreen extends ConsumerStatefulWidget {
  const IndoorMapScreen({required this.buildingId, super.key});

  final int buildingId;

  @override
  ConsumerState<IndoorMapScreen> createState() => _IndoorMapScreenState();
}

class _IndoorMapScreenState extends ConsumerState<IndoorMapScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () =>
          ref.read(mapSessionProvider.notifier).openBuilding(widget.buildingId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapSessionProvider);
    return switch (state) {
      MapSessionLoading() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      MapSessionReady(
        :final building,
        :final floors,
        :final floorMap,
        :final destination,
        :final start,
        :final preference,
        :final route,
        :final routeFailure,
        :final isCalculating,
      ) =>
        _MapShell(
          buildingName: building.name,
          buildingId: building.id,
          floors: floors,
          floorMap: floorMap,
          destinationName: destination?.name,
          startName: start?.label,
          preference: preference,
          route: route,
          routeFailureMessage: routeFailure?.message,
          isCalculating: isCalculating,
        ),
      MapSessionFailure(:final failure) => Scaffold(
        body: FullStateView(
          icon: Icons.cloud_off_outlined,
          title: failure.title,
          message: failure.message,
          primaryAction: () => ref
              .read(mapSessionProvider.notifier)
              .openBuilding(widget.buildingId),
          primaryActionLabel: 'Retry',
        ),
      ),
    };
  }
}

class _MapShell extends ConsumerWidget {
  const _MapShell({
    required this.buildingName,
    required this.buildingId,
    required this.floors,
    required this.floorMap,
    required this.destinationName,
    required this.startName,
    required this.preference,
    required this.route,
    required this.routeFailureMessage,
    required this.isCalculating,
  });

  final String buildingName;
  final int buildingId;
  final List<Floor> floors;
  final FloorMap floorMap;
  final String? destinationName;
  final String? startName;
  final RoutePreference preference;
  final RouteOutcome? route;
  final String? routeFailureMessage;
  final bool isCalculating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderedFloors = List<Floor>.of(floors)
      ..sort((first, second) => second.level.compareTo(first.level));
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: _MapCanvas(floorMap: floorMap)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: Row(
                children: <Widget>[
                  Material(
                    color: AppColors.surface,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.x4,
                          vertical: AppSpacing.x2,
                        ),
                        child: Text(
                          buildingName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 96,
            right: AppSpacing.x4,
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: orderedFloors
                    .map((floor) {
                      final selected = floor.id == floorMap.floor.id;
                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: selected
                              ? FilledButton(
                                  onPressed: null,
                                  child: Text(floor.displayName),
                                )
                              : OutlinedButton(
                                  onPressed: () => ref
                                      .read(mapSessionProvider.notifier)
                                      .selectFloor(floor.id),
                                  child: Text(floor.displayName),
                                ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            left: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.x4),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _PanelHeading(
                      destinationName: destinationName,
                      route: route,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      startName == null
                          ? 'Choose a destination and start location to plan a route.'
                          : 'Start: $startName',
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/buildings/$buildingId/start'),
                      icon: const Icon(Icons.my_location_outlined),
                      label: Text(
                        startName == null ? 'Choose start' : 'Change start',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    FilledButton.icon(
                      onPressed: () =>
                          context.push('/buildings/$buildingId/destinations'),
                      icon: const Icon(Icons.search),
                      label: Text(
                        destinationName == null
                            ? 'Choose a destination'
                            : 'Change destination',
                      ),
                    ),
                    if (destinationName != null &&
                        startName != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.x2),
                      OutlinedButton.icon(
                        onPressed: isCalculating
                            ? null
                            : () => _showPreferenceSelector(context, ref),
                        icon: const Icon(Icons.tune),
                        label: Text('Preference: ${preference.label}'),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      FilledButton(
                        onPressed: isCalculating
                            ? null
                            : () => ref
                                  .read(mapSessionProvider.notifier)
                                  .calculateRoute(),
                        child: isCalculating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Get route'),
                      ),
                    ],
                    if (routeFailureMessage case final message?) ...<Widget>[
                      const SizedBox(height: AppSpacing.x2),
                      Text(message),
                    ],
                    if (route case final NoRouteOutcome noRoute) ...<Widget>[
                      const SizedBox(height: AppSpacing.x2),
                      Text(noRoute.message),
                    ],
                    if (route case final FoundRoute found) ...<Widget>[
                      const SizedBox(height: AppSpacing.x2),
                      for (final warning in found.warnings)
                        Text(warning.message),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPreferenceSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Route preferences',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x2),
              RadioGroup<RoutePreference>(
                groupValue: preference,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  Navigator.of(sheetContext).pop();
                  ref.read(mapSessionProvider.notifier).setPreference(value);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: RoutePreference.values
                      .map(
                        (option) => RadioListTile<RoutePreference>(
                          value: option,
                          title: Text(option.label),
                          subtitle: Text(option.description),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({required this.destinationName, required this.route});

  final String? destinationName;
  final RouteOutcome? route;

  @override
  Widget build(BuildContext context) {
    if (route case final FoundRoute found) {
      return Text(
        'Est. ${_formatDuration(found.estimatedDurationSeconds)} · ${found.distanceMeters.toStringAsFixed(0)} m',
        style: Theme.of(context).textTheme.titleMedium,
      );
    }
    return Text(
      destinationName == null
          ? 'Explore this floor'
          : 'Destination: $destinationName',
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds s';
    }
    return '${(seconds / 60).ceil()} min walk';
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({required this.floorMap});

  final FloorMap floorMap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEFEBE2),
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        constrained: false,
        child: SizedBox(
          width: floorMap.plan.width,
          height: floorMap.plan.height,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ExcludeSemantics(
                child: SvgPicture.string(floorMap.svgContent, fit: BoxFit.fill),
              ),
              CustomPaint(
                painter: _MarkerPainter(
                  nodes: floorMap.nodes,
                  pointsOfInterest: floorMap.pointsOfInterest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  const _MarkerPainter({required this.nodes, required this.pointsOfInterest});

  final List<MapNode> nodes;
  final List<MapPointOfInterest> pointsOfInterest;

  @override
  void paint(Canvas canvas, Size size) {
    final nodesById = <int, MapNode>{for (final node in nodes) node.id: node};
    final markerPaint = Paint()..color = AppColors.primary;
    for (final point in pointsOfInterest) {
      final node = nodesById[point.nodeId];
      if (node == null) {
        continue;
      }
      canvas.drawCircle(Offset(node.x, node.y), 12, markerPaint);
    }
  }

  @override
  bool shouldRepaint(_MarkerPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.pointsOfInterest != pointsOfInterest;
  }
}
