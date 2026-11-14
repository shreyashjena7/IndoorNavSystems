enum RoutePreference {
  shortest('SHORTEST', 'Shortest', 'The shortest walking distance.'),
  fastest('FASTEST', 'Fastest', 'The quickest estimated route.'),
  accessible(
    'ACCESSIBLE',
    'Accessible',
    'Only step-free routes. Stairs are never used.',
  ),
  avoidStairs(
    'AVOID_STAIRS',
    'Avoid stairs',
    'Avoid stairs when another route is available.',
  ),
  preferElevator(
    'PREFER_ELEVATOR',
    'Prefer elevator',
    'Use elevators where practical.',
  );

  const RoutePreference(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  static RoutePreference fromCode(String value) {
    for (final preference in values) {
      if (preference.code == value) {
        return preference;
      }
    }
    throw FormatException('Unknown route preference: $value.');
  }
}
