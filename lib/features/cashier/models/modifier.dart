class ModifierOption {
  final String id;
  final String name;
  final double price;

  const ModifierOption({
    required this.id,
    required this.name,
    required this.price,
  });
}

class ModifierGroup {
  final String name;
  final bool multiSelect;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.name,
    required this.multiSelect,
    required this.options,
  });
}
