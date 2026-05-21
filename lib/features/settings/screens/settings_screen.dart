import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/settings/models/app_settings.dart';
import 'package:easycasher/features/settings/providers/settings_provider.dart';

enum _Section { restaurant, serviceMode, tax, receipt, staff }

extension _SectionX on _Section {
  String get label => switch (this) {
        _Section.restaurant => 'Restaurant',
        _Section.serviceMode => 'Service Mode',
        _Section.tax => 'Tax',
        _Section.receipt => 'Receipt',
        _Section.staff => 'Staff',
      };
  IconData get icon => switch (this) {
        _Section.restaurant => Icons.storefront_rounded,
        _Section.serviceMode => Icons.restaurant_rounded,
        _Section.tax => Icons.percent_rounded,
        _Section.receipt => Icons.receipt_long_rounded,
        _Section.staff => Icons.people_rounded,
      };
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _Section _active = _Section.restaurant;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Row(
      children: [
        _SettingsNav(
          active: _active,
          onSelect: (s) => setState(() => _active = s),
        ),
        Container(width: 1, color: AppColors.outlineVariant),
        Expanded(
          child: _SectionContent(
            section: _active,
            settings: settings,
          ),
        ),
      ],
    );
  }
}

// ─── Left navigation ────────────────────────────────────────────────────────

class _SettingsNav extends StatelessWidget {
  final _Section active;
  final ValueChanged<_Section> onSelect;

  const _SettingsNav({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.settings_rounded,
                    color: Colors.white70, size: 22),
                const SizedBox(height: 8),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Configure your restaurant',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 8),
          for (final s in _Section.values)
            _NavItem(
              section: s,
              isActive: s == active,
              onTap: () => onSelect(s),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _Section section;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem(
      {required this.section,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              section.icon,
              size: 18,
              color: isActive ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 10),
            Text(
              section.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Right content ───────────────────────────────────────────────────────────

class _SectionContent extends ConsumerWidget {
  final _Section section;
  final AppSettings settings;

  const _SectionContent(
      {required this.section, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: AppColors.background,
      child: switch (section) {
        _Section.restaurant =>
          _RestaurantSection(settings: settings),
        _Section.serviceMode =>
          _ServiceModeSection(settings: settings),
        _Section.tax => _TaxSection(settings: settings),
        _Section.receipt => _ReceiptSection(settings: settings),
        _Section.staff => const _StaffSection(),
      },
    );
  }
}

// ─── Shared layout helpers ───────────────────────────────────────────────────

class _SectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionShell(
      {required this.title,
      required this.subtitle,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.4)),
    );
  }
}

InputDecoration _inputDec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
      filled: true,
      fillColor: AppColors.surfaceLow,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );

// ─── Restaurant section ───────────────────────────────────────────────────────

class _RestaurantSection extends ConsumerStatefulWidget {
  final AppSettings settings;

  const _RestaurantSection({required this.settings});

  @override
  ConsumerState<_RestaurantSection> createState() =>
      _RestaurantSectionState();
}

class _RestaurantSectionState
    extends ConsumerState<_RestaurantSection> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.settings.restaurantName);
    _addressCtrl =
        TextEditingController(text: widget.settings.restaurantAddress);
    _phoneCtrl =
        TextEditingController(text: widget.settings.restaurantPhone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(settingsProvider.notifier).update(
          widget.settings.copyWith(
            restaurantName: _nameCtrl.text.trim(),
            restaurantAddress: _addressCtrl.text.trim(),
            restaurantPhone: _phoneCtrl.text.trim(),
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Restaurant info saved'),
          duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'Restaurant Info',
      subtitle: 'Basic details shown on receipts and screens',
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('RESTAURANT NAME'),
            TextField(
                controller: _nameCtrl,
                decoration: _inputDec('My Restaurant'),
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            const _FieldLabel('ADDRESS'),
            TextField(
                controller: _addressCtrl,
                decoration: _inputDec('123 Main Street'),
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            const _FieldLabel('PHONE'),
            TextField(
                controller: _phoneCtrl,
                decoration: _inputDec('+964 750 000 0000'),
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Save Changes',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Service mode section ─────────────────────────────────────────────────────

class _ServiceModeSection extends ConsumerWidget {
  final AppSettings settings;

  const _ServiceModeSection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionShell(
      title: 'Service Mode',
      subtitle: 'Choose how customers order and pay',
      child: Column(
        children: ServiceMode.values
            .map(
              (mode) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ServiceModeCard(
                  mode: mode,
                  isSelected: settings.serviceMode == mode,
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .update(settings.copyWith(serviceMode: mode)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ServiceModeCard extends StatelessWidget {
  final ServiceMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceModeCard(
      {required this.mode,
      required this.isSelected,
      required this.onTap});

  IconData get _icon => switch (mode) {
        ServiceMode.fullService => Icons.table_restaurant_rounded,
        ServiceMode.quickService => Icons.fastfood_rounded,
        ServiceMode.both => Icons.swap_horiz_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryFixed
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon,
                  size: 22,
                  color: isSelected
                      ? Colors.white
                      : AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurface,
                      )),
                  const SizedBox(height: 3),
                  Text(mode.description,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Tax section ──────────────────────────────────────────────────────────────

class _TaxSection extends ConsumerStatefulWidget {
  final AppSettings settings;

  const _TaxSection({required this.settings});

  @override
  ConsumerState<_TaxSection> createState() => _TaxSectionState();
}

class _TaxSectionState extends ConsumerState<_TaxSection> {
  late bool _enabled;
  late final TextEditingController _rateCtrl;

  @override
  void initState() {
    super.initState();
    _enabled = widget.settings.taxEnabled;
    _rateCtrl = TextEditingController(
        text: widget.settings.taxRate == 0
            ? ''
            : widget.settings.taxRate.toString());
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final rate = double.tryParse(_rateCtrl.text) ?? 0.0;
    ref.read(settingsProvider.notifier).update(
          widget.settings.copyWith(
            taxEnabled: _enabled,
            taxRate: rate.clamp(0.0, 100.0),
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Tax settings saved'),
          duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'Tax',
      subtitle: 'Configure tax applied to orders',
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Enable Tax',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface)),
                      const SizedBox(height: 2),
                      Text(
                          _enabled
                              ? 'Tax will be added to all orders'
                              : 'No tax applied to orders',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _enabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),
            if (_enabled) ...[
              const SizedBox(height: 20),
              const _FieldLabel('TAX RATE (%)'),
              TextField(
                controller: _rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDec('e.g. 15'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a percentage, e.g. 15 for 15%',
                style: TextStyle(
                    fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Save Changes',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Receipt section ──────────────────────────────────────────────────────────

class _ReceiptSection extends ConsumerStatefulWidget {
  final AppSettings settings;

  const _ReceiptSection({required this.settings});

  @override
  ConsumerState<_ReceiptSection> createState() =>
      _ReceiptSectionState();
}

class _ReceiptSectionState extends ConsumerState<_ReceiptSection> {
  late final TextEditingController _footerCtrl;

  @override
  void initState() {
    super.initState();
    _footerCtrl =
        TextEditingController(text: widget.settings.receiptFooter);
  }

  @override
  void dispose() {
    _footerCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(settingsProvider.notifier).update(
          widget.settings.copyWith(receiptFooter: _footerCtrl.text),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Receipt settings saved'),
          duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'Receipt',
      subtitle: 'Customize what appears on printed receipts',
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('FOOTER MESSAGE'),
            TextField(
              controller: _footerCtrl,
              maxLines: 3,
              decoration: _inputDec(
                  'Thank you for your visit! Come back again 😊'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Shown at the bottom of every printed receipt.',
              style: TextStyle(
                  fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Save Changes',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Staff section ────────────────────────────────────────────────────────────

class _StaffSection extends ConsumerWidget {
  const _StaffSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffList = ref.watch(staffListProvider);

    return _SectionShell(
      title: 'Staff',
      subtitle: 'Manage staff accounts and PINs',
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showStaffDialog(context, ref, null),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Staff'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              children: [
                for (int i = 0; i < staffList.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1, color: AppColors.outlineVariant),
                  _StaffRow(
                    staff: staffList[i],
                    onEdit: () =>
                        _showStaffDialog(context, ref, staffList[i]),
                    onDelete: () =>
                        _confirmDelete(context, ref, staffList[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStaffDialog(
      BuildContext context, WidgetRef ref, Staff? existing) {
    showDialog(
      context: context,
      builder: (_) => _StaffDialog(existing: existing, ref: ref),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Staff staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Staff'),
        content: Text(
            'Remove ${staff.name} from the staff list? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(staffListProvider.notifier).remove(staff.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(
                foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  final Staff staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffRow(
      {required this.staff,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryFixed,
            child: Text(staff.avatar,
                style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _RoleBadge(role: staff.role),
                    const SizedBox(width: 8),
                    Text('PIN: ${'•' * staff.pin.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                size: 18, color: AppColors.onSurfaceVariant),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.danger),
            onPressed: onDelete,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final StaffRole role;

  const _RoleBadge({required this.role});

  Color get _color => switch (role) {
        StaffRole.manager => const Color(0xFF7C3AED),
        StaffRole.cashier => const Color(0xFF0369A1),
        StaffRole.waiter => const Color(0xFF065F46),
        StaffRole.kitchen => const Color(0xFFB45309),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

// ─── Add / Edit staff dialog ──────────────────────────────────────────────────

class _StaffDialog extends StatefulWidget {
  final Staff? existing;
  final WidgetRef ref;

  const _StaffDialog({required this.existing, required this.ref});

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  StaffRole _role = StaffRole.waiter;
  String _avatar = '👤';
  bool _showPin = false;

  static const _avatars = [
    '👨‍🍳', '👩‍🍳', '🧑‍🍳', '👨‍💼', '👩‍💼', '🧑‍💼',
    '👮', '👷', '🧑', '👦', '👧', '🙂',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _pinCtrl.text = widget.existing!.pin;
      _role = widget.existing!.role;
      _avatar = widget.existing!.avatar;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (name.isEmpty || pin.isEmpty) return;

    final notifier = widget.ref.read(staffListProvider.notifier);

    if (widget.existing != null) {
      notifier.update(widget.existing!.copyWith(
        name: name,
        role: _role,
        pin: pin,
        avatar: _avatar,
      ));
    } else {
      notifier.add(Staff(
        id: notifier.nextId(),
        name: name,
        role: _role,
        pin: pin,
        avatar: _avatar,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Staff' : 'Add Staff'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar picker
            const Text('Avatar',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _avatars
                  .map(
                    (a) => GestureDetector(
                      onTap: () => setState(() => _avatar = a),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _avatar == a
                              ? AppColors.primaryFixed
                              : AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _avatar == a
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                            child: Text(a,
                                style: const TextStyle(fontSize: 20))),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            // Name
            const Text('Name',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: _inputDec('Full name'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            // Role
            const Text('Role',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            DropdownButtonFormField<StaffRole>(
              initialValue: _role,
              decoration: _inputDec('').copyWith(hintText: null),
              items: StaffRole.values
                  .map((r) => DropdownMenuItem(
                      value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (v) => setState(() => _role = v!),
              style: const TextStyle(
                  fontSize: 14, color: AppColors.onSurface),
            ),
            const SizedBox(height: 14),
            // PIN
            const Text('PIN',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _pinCtrl,
              obscureText: !_showPin,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: _inputDec('4-digit PIN').copyWith(
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPin
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed: () =>
                      setState(() => _showPin = !_showPin),
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
