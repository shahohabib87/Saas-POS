class ModifierOption {
  final String id;
  final String name;
  final double price;

  const ModifierOption({
    required this.id,
    required this.name,
    required this.price,
  });

  ModifierOption copyWith({String? id, String? name, double? price}) =>
      ModifierOption(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
      );
}

class ModifierGroup {
  final String name;
  final bool multiSelect;
  final List<ModifierOption> options;

  ModifierGroup({
    required this.name,
    required this.multiSelect,
    required this.options,
  });

  ModifierGroup copyWith({
    String? name,
    bool? multiSelect,
    List<ModifierOption>? options,
  }) =>
      ModifierGroup(
        name: name ?? this.name,
        multiSelect: multiSelect ?? this.multiSelect,
        options: options ?? this.options,
      );
}
