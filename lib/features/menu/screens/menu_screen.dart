import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/cashier/models/category.dart';
import 'package:easycasher/features/cashier/models/menu_item.dart';
import 'package:easycasher/features/cashier/models/modifier.dart';
import 'package:easycasher/features/cashier/providers/menu_provider.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(tab: _tab, onTab: (i) => setState(() => _tab = i)),
        Expanded(
          child: _tab == 0 ? const _CategoriesTab() : const _ProductsTab(),
        ),
      ],
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTab;
  const _Header({required this.tab, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          const Text(
            'Menu Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 24),
          _TabChip(label: 'Categories', selected: tab == 0, onTap: () => onTab(0)),
          const SizedBox(width: 8),
          _TabChip(label: 'Products', selected: tab == 1, onTap: () => onTab(1)),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORIES TAB
// ─────────────────────────────────────────────────────────────────────────────

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider)
        .where((c) => c.id != 'all')
        .toList();

    return Stack(
      children: [
        categories.isEmpty
            ? const _EmptyState(message: 'No categories yet. Add one!')
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _CategoryTile(
                  category: categories[i],
                  onEdit: () => _showCategoryDialog(context, ref, categories[i]),
                  onDelete: () => _confirmDelete(
                    context,
                    label: categories[i].name,
                    onConfirm: () =>
                        ref.read(categoriesProvider.notifier).remove(categories[i].id),
                  ),
                ),
              ),
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton.extended(
            heroTag: 'add_cat',
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Category'),
            onPressed: () => _showCategoryDialog(context, ref, null),
          ),
        ),
      ],
    );
  }

  void _showCategoryDialog(
      BuildContext context, WidgetRef ref, Category? existing) {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(
        existing: existing,
        onSave: (cat) {
          if (existing == null) {
            ref.read(categoriesProvider.notifier).add(cat);
          } else {
            ref.read(categoriesProvider.notifier).update(cat);
          }
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CategoryTile(
      {required this.category, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(category.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppColors.onSurfaceVariant,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final Category? existing;
  final ValueChanged<Category> onSave;
  const _CategoryDialog({required this.existing, required this.onSave});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _name;
  late final TextEditingController _emoji;

  static const _emojiSuggestions = [
    '🍔', '🍕', '🍣', '🍜', '🍗', '🥩', '🥗', '🍰', '🎂', '🍦',
    '🥤', '☕', '🧃', '🍷', '🍺', '🥐', '🌮', '🍱', '🥙', '🍛',
    '🥘', '🍲', '🥞', '🧆', '🌯', '🍟', '🍤', '🦐', '🥚', '🧀',
  ];

  @override
  void initState() {
    super.initState();
    _name  = TextEditingController(text: widget.existing?.name ?? '');
    _emoji = TextEditingController(text: widget.existing?.emoji ?? '🍽️');
  }

  @override
  void dispose() {
    _name.dispose();
    _emoji.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    widget.onSave(Category(
      id: widget.existing?.id ?? '',
      name: name,
      emoji: _emoji.text.trim().isEmpty ? '🍽️' : _emoji.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'New Category' : 'Edit Category',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface),
              ),
              const SizedBox(height: 20),
              _FormField(label: 'Name', controller: _name, hint: 'e.g. Burgers'),
              const SizedBox(height: 16),
              _FormField(
                label: 'Emoji',
                controller: _emoji,
                hint: 'Paste emoji',
                maxLength: 4,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojiSuggestions.map((e) => GestureDetector(
                  onTap: () => setState(() => _emoji.text = e),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _emoji.text == e
                          ? AppColors.primaryFixed
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _emoji.text == e
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 18)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCTS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ProductsTab extends ConsumerStatefulWidget {
  const _ProductsTab();

  @override
  ConsumerState<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<_ProductsTab> {
  String _filterCategoryId = 'all';

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final allItems   = ref.watch(menuItemsProvider);

    final items = _filterCategoryId == 'all'
        ? allItems
        : allItems.where((i) => i.categoryId == _filterCategoryId).toList();

    final catMap = {for (final c in categories) c.id: c};

    return Stack(
      children: [
        Column(
          children: [
            // Category filter chips
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final sel = cat.id == _filterCategoryId;
                  return GestureDetector(
                    onTap: () => setState(() => _filterCategoryId = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                              color: sel ? Colors.white : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(height: 1, color: AppColors.outlineVariant),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyState(message: 'No products in this category.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final cat = catMap[item.categoryId];
                        return _ProductTile(
                          item: item,
                          categoryName: cat?.name ?? '',
                          onEdit: () => _showProductDialog(context, ref, categories, item),
                          onDelete: () => _confirmDelete(
                            context,
                            label: item.name,
                            onConfirm: () =>
                                ref.read(menuItemsProvider.notifier).remove(item.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton.extended(
            heroTag: 'add_prod',
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Product'),
            onPressed: () => _showProductDialog(context, ref, categories, null),
          ),
        ),
      ],
    );
  }

  void _showProductDialog(BuildContext context, WidgetRef ref,
      List<Category> categories, MenuItem? existing) {
    showDialog(
      context: context,
      builder: (_) => _ProductDialog(
        existing: existing,
        categories: categories.where((c) => c.id != 'all').toList(),
        defaultCategoryId: _filterCategoryId == 'all'
            ? (categories.length > 1 ? categories[1].id : '')
            : _filterCategoryId,
        onSave: (item) {
          if (existing == null) {
            ref.read(menuItemsProvider.notifier).add(item);
          } else {
            ref.read(menuItemsProvider.notifier).update(item);
          }
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final MenuItem item;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProductTile({
    required this.item,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    if (item.hasModifiers) ...[
                      const Text('  •  ',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant)),
                      Text(
                        '${item.modifierGroups.length} modifier groups',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            _formatPrice(item.price),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppColors.onSurfaceVariant,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return '${price.toInt()} IQD';
    }
    return '${price.toStringAsFixed(0)} IQD';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _ProductDialog extends StatefulWidget {
  final MenuItem? existing;
  final List<Category> categories;
  final String defaultCategoryId;
  final ValueChanged<MenuItem> onSave;

  const _ProductDialog({
    required this.existing,
    required this.categories,
    required this.defaultCategoryId,
    required this.onSave,
  });

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _emoji;
  late String _categoryId;
  late List<ModifierGroup> _groups;

  static const _emojiSuggestions = [
    '🍔', '🍕', '🍣', '🍜', '🍗', '🥩', '🥗', '🍰', '🎂', '🍦',
    '🥤', '☕', '🧃', '🍟', '🌮', '🥐', '🍱', '🥙', '🍛', '🥘',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name       = TextEditingController(text: e?.name ?? '');
    _price      = TextEditingController(text: e != null ? e.price.toStringAsFixed(0) : '');
    _emoji      = TextEditingController(text: e?.emoji ?? '🍽️');
    _categoryId = e?.categoryId ?? widget.defaultCategoryId;
    _groups     = e?.modifierGroups.map((g) => ModifierGroup(
          name: g.name,
          multiSelect: g.multiSelect,
          options: g.options.map((o) => ModifierOption(id: o.id, name: o.name, price: o.price)).toList(),
        )).toList() ?? [];
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _emoji.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim()) ?? 0;
    if (name.isEmpty || price <= 0) return;
    widget.onSave(MenuItem(
      id: widget.existing?.id ?? '',
      categoryId: _categoryId,
      name: name,
      price: price,
      emoji: _emoji.text.trim().isEmpty ? '🍽️' : _emoji.text.trim(),
      modifierGroups: _groups,
    ));
    Navigator.pop(context);
  }

  void _addGroup() {
    setState(() {
      _groups = [..._groups, ModifierGroup(name: '', multiSelect: false, options: [])];
    });
  }

  void _removeGroup(int index) {
    setState(() {
      _groups = [..._groups]..removeAt(index);
    });
  }

  void _updateGroup(int index, ModifierGroup g) {
    setState(() {
      final list = [..._groups];
      list[index] = g;
      _groups = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Text(
                    widget.existing == null ? 'New Product' : 'Edit Product',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.outlineVariant),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Emoji preview + picker
                        Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primaryFixed,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.outlineVariant),
                              ),
                              alignment: Alignment.center,
                              child: Text(_emoji.text, style: const TextStyle(fontSize: 32)),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 64,
                              child: TextField(
                                controller: _emoji,
                                textAlign: TextAlign.center,
                                maxLength: 4,
                                decoration: const InputDecoration(
                                  counterText: '',
                                  hintText: '😀',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 18),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _FormField(label: 'Product Name', controller: _name, hint: 'e.g. Classic Burger'),
                              const SizedBox(height: 12),
                              _FormField(
                                label: 'Price (IQD)',
                                controller: _price,
                                hint: 'e.g. 5500',
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Emoji suggestions
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _emojiSuggestions.map((e) => GestureDetector(
                        onTap: () => setState(() => _emoji.text = e),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _emoji.text == e
                                ? AppColors.primaryFixed
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _emoji.text == e
                                  ? AppColors.primary
                                  : AppColors.outlineVariant,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(e, style: const TextStyle(fontSize: 16)),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Category
                    _FieldLabel(label: 'Category'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: widget.categories.any((c) => c.id == _categoryId)
                          ? _categoryId
                          : (widget.categories.isNotEmpty ? widget.categories.first.id : null),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.outlineVariant),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        isDense: true,
                      ),
                      items: widget.categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Row(
                                  children: [
                                    Text(c.emoji, style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Text(c.name),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
                    ),
                    const SizedBox(height: 20),
                    // Modifier groups
                    Row(
                      children: [
                        const Text(
                          'Modifier Groups',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addGroup,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Group'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    if (_groups.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: const Center(
                          child: Text(
                            'No modifier groups. Tap "Add Group" to add options like size or extras.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_groups.length, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ModifierGroupEditor(
                          group: _groups[i],
                          index: i,
                          onUpdate: (g) => _updateGroup(i, g),
                          onRemove: () => _removeGroup(i),
                        ),
                      )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const Divider(color: AppColors.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _save,
                    child: const Text('Save Product'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODIFIER GROUP EDITOR
// ─────────────────────────────────────────────────────────────────────────────

class _ModifierGroupEditor extends StatefulWidget {
  final ModifierGroup group;
  final int index;
  final ValueChanged<ModifierGroup> onUpdate;
  final VoidCallback onRemove;

  const _ModifierGroupEditor({
    required this.group,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_ModifierGroupEditor> createState() => _ModifierGroupEditorState();
}

class _ModifierGroupEditorState extends State<_ModifierGroupEditor> {
  late final TextEditingController _groupName;
  late List<_OptionRow> _rows;
  late bool _multiSelect;
  int _optionCounter = 0;

  @override
  void initState() {
    super.initState();
    _groupName  = TextEditingController(text: widget.group.name);
    _multiSelect = widget.group.multiSelect;
    _rows = widget.group.options
        .map((o) => _OptionRow(
              id: o.id,
              name: TextEditingController(text: o.name),
              price: TextEditingController(text: o.price > 0 ? o.price.toStringAsFixed(0) : ''),
            ))
        .toList();
    _optionCounter = _rows.length;
  }

  @override
  void dispose() {
    _groupName.dispose();
    for (final r in _rows) {
      r.name.dispose();
      r.price.dispose();
    }
    super.dispose();
  }

  void _notify() {
    widget.onUpdate(ModifierGroup(
      name: _groupName.text.trim(),
      multiSelect: _multiSelect,
      options: _rows
          .map((r) => ModifierOption(
                id: r.id,
                name: r.name.text.trim(),
                price: double.tryParse(r.price.text.trim()) ?? 0,
              ))
          .where((o) => o.name.isNotEmpty)
          .toList(),
    ));
  }

  void _addOption() {
    setState(() {
      _rows = [..._rows, _OptionRow(id: 'opt_${_optionCounter++}')];
    });
    _notify();
  }

  void _removeOption(int i) {
    setState(() {
      _rows[i].name.dispose();
      _rows[i].price.dispose();
      _rows = [..._rows]..removeAt(i);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _groupName,
                  decoration: const InputDecoration(
                    hintText: 'Group name (e.g. Size)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Text('Multi-select', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  Switch(
                    value: _multiSelect,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) {
                      setState(() => _multiSelect = v);
                      _notify();
                    },
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.error,
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_rows.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _rows[i].name,
                    decoration: InputDecoration(
                      hintText: 'Option name',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                      prefixText: '  ${i + 1}. ',
                      prefixStyle: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) => _notify(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _rows[i].price,
                    decoration: const InputDecoration(
                      hintText: '+price',
                      suffixText: 'IQD',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _notify(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: AppColors.onSurfaceVariant,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () => _removeOption(i),
                ),
              ],
            ),
          )),
          TextButton.icon(
            onPressed: _addOption,
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text('Add Option', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow {
  final String id;
  final TextEditingController name;
  final TextEditingController price;
  _OptionRow({required this.id, TextEditingController? name, TextEditingController? price})
      : name  = name  ?? TextEditingController(),
        price = price ?? TextEditingController();
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            filled: true,
            fillColor: AppColors.background,
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.restaurant_menu_rounded,
              size: 48, color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

void _confirmDelete(
  BuildContext context, {
  required String label,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Delete?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      content: Text('Remove "$label"? This cannot be undone.',
          style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
