class Category {
  final String id;
  final String name;
  final String emoji;

  const Category({
    required this.id,
    required this.name,
    this.emoji = '🍽️',
  });

  Category copyWith({String? id, String? name, String? emoji}) => Category(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
      );
}
