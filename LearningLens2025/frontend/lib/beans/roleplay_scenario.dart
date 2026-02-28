class RoleplayScenario {
  final String id;
  final String title;
  final String personaRole;
  final String personaTraits;
  final String personaGoals;
  final String scenarioContext;
  final DateTime createdAt;

  const RoleplayScenario({
    required this.id,
    required this.title,
    required this.personaRole,
    required this.personaTraits,
    required this.personaGoals,
    required this.scenarioContext,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'personaRole': personaRole,
        'personaTraits': personaTraits,
        'personaGoals': personaGoals,
        'scenarioContext': scenarioContext,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory RoleplayScenario.fromJson(Map<String, dynamic> json) {
    return RoleplayScenario(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      personaRole: (json['personaRole'] ?? '').toString(),
      personaTraits: (json['personaTraits'] ?? '').toString(),
      personaGoals: (json['personaGoals'] ?? '').toString(),
      scenarioContext: (json['scenarioContext'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now().toUtc(),
    );
  }
}
