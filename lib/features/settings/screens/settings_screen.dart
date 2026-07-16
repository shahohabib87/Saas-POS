import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/auth/models/app_permission.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/features/locations/models/location.dart';
import 'package:easycasher/features/locations/providers/locations_provider.dart';
import 'package:easycasher/features/settings/models/app_settings.dart';
import 'package:easycasher/features/settings/providers/settings_provider.dart';
import 'package:easycasher/core/sync/cloud_sync.dart';
import 'package:easycasher/features/tables/models/restaurant_table.dart';
import 'package:easycasher/features/tables/providers/tables_provider.dart';

enum _Section { restaurant, serviceMode, tax, receipt, staff, tables, locations, permissions, cloud }

extension _SectionX on _Section {
  String get label => switch (this) {
        _Section.restaurant  => 'Restaurant',
        _Section.serviceMode => 'Service Mode',
        _Section.tax         => 'Tax',
        _Section.receipt     => 'Receipt',
        _Section.staff       => 'Staff',
        _Section.tables      => 'Tables',
        _Section.locations   => 'Locations',
        _Section.permissions => 'Permissions',
        _Section.cloud       => 'Cloud Sync',
      };
  IconData get icon => switch (this) {
        _Section.restaurant  => Icons.storefront_rounded,
        _Section.serviceMode => Icons.restaurant_rounded,
        _Section.tax         => Icons.percent_rounded,
        _Section.receipt     => Icons.receipt_long_rounded,
        _Section.staff       => Icons.people_rounded,
        _Section.tables      => Icons.table_restaurant_rounded,
        _Section.locations   => Icons.location_on_rounded,
        _Section.permissions => Icons.shield_rounded,
        _Section.cloud       => Icons.cloud_rounded,
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

class _SettingsNav extends ConsumerWidget {
  final _Section active;
  final ValueChanged<_Section> onSelect;

  const _SettingsNav({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff       = ref.watch(currentStaffProvider);
    final permissions = ref.watch(currentPermissionsProvider);
    final isAdmin     = staff?.role == StaffRole.admin;
    final canManageTables = permissions.contains(AppPermission.tableManagement);

    final visible = _Section.values.where((s) {
      if (s == _Section.permissions) return isAdmin;
      if (s == _Section.tables) return canManageTables;
      return true;
    }).toList();

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
          for (final s in visible)
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
        _Section.restaurant  => _RestaurantSection(settings: settings),
        _Section.serviceMode => _ServiceModeSection(settings: settings),
        _Section.tax         => _TaxSection(settings: settings),
        _Section.receipt     => _ReceiptSection(settings: settings),
        _Section.staff       => const _StaffSection(),
        _Section.tables      => const _TablesSection(),
        _Section.locations   => const _LocationsSection(),
        _Section.permissions => const _PermissionsSection(),
        _Section.cloud       => const _CloudSection(),
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
        StaffRole.admin   => const Color(0xFFDC2626),
        StaffRole.manager => const Color(0xFF7C3AED),
        StaffRole.cashier => const Color(0xFF0369A1),
        StaffRole.waiter  => const Color(0xFF065F46),
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

// ─── Permissions section (admin only) ────────────────────────────────────────

class _PermissionsSection extends ConsumerStatefulWidget {
  const _PermissionsSection();

  @override
  ConsumerState<_PermissionsSection> createState() =>
      _PermissionsSectionState();
}

class _PermissionsSectionState extends ConsumerState<_PermissionsSection> {
  // Admin permissions are fixed — exclude from editor
  static const _editableRoles = [
    StaffRole.manager,
    StaffRole.cashier,
    StaffRole.waiter,
    StaffRole.kitchen,
  ];

  StaffRole _selectedRole = StaffRole.cashier;

  @override
  Widget build(BuildContext context) {
    final rolePerms = ref.watch(rolePermissionsProvider);
    final perms = rolePerms[_selectedRole] ?? {};

    return _SectionShell(
      title: 'Permissions',
      subtitle: 'Control which sections each role can access',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role selector
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECT ROLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _editableRoles.map((role) {
                    final isSelected = role == _selectedRole;
                    final color = _roleColor(role);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRole = role),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.12)
                              : AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? color : AppColors.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          role.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? color : AppColors.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Permission toggles
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERMISSIONS FOR ${_selectedRole.label.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Toggle which sections this role can see in the sidebar.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < AppPermission.values.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.outlineVariant),
                  _PermissionTile(
                    permission: AppPermission.values[i],
                    enabled: perms.contains(AppPermission.values[i]),
                    onChanged: (val) => ref
                        .read(rolePermissionsProvider.notifier)
                        .setPermission(_selectedRole, AppPermission.values[i], val),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(StaffRole role) => switch (role) {
        StaffRole.admin   => const Color(0xFFDC2626),
        StaffRole.manager => const Color(0xFF7C3AED),
        StaffRole.cashier => const Color(0xFF0369A1),
        StaffRole.waiter  => const Color(0xFF065F46),
        StaffRole.kitchen => const Color(0xFFB45309),
      };
}

class _PermissionTile extends StatelessWidget {
  final AppPermission permission;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _PermissionTile({
    required this.permission,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  permission.description,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Tables section ───────────────────────────────────────────────────────────

class _TablesSection extends ConsumerWidget {
  const _TablesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tablesProvider);

    return _SectionShell(
      title: 'Tables',
      subtitle: 'Add, edit, or remove dining tables',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showDialog(context, ref, null),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Table'),
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
            child: tables.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No tables yet. Tap "Add Table" to get started.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < tables.length; i++) ...[
                        if (i > 0)
                          const Divider(
                              height: 1, color: AppColors.outlineVariant),
                        _TableRow(
                          table: tables[i],
                          onEdit: () => _showDialog(context, ref, tables[i]),
                          onDelete: () =>
                              _confirmDelete(context, ref, tables[i]),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, RestaurantTable? existing) {
    showDialog(
      context: context,
      builder: (_) => _TableDialog(
        existing: existing,
        suggestedNumber:
            ref.read(tablesProvider.notifier).nextSuggestedNumber(),
        onSave: (number, capacity) {
          if (existing == null) {
            ref.read(tablesProvider.notifier).add(number, capacity);
          } else {
            ref
                .read(tablesProvider.notifier)
                .update(existing.id, number: number, capacity: capacity);
          }
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, RestaurantTable table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Table?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text(
          'Remove Table ${table.number}? This cannot be undone.',
          style: const TextStyle(
              fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref.read(tablesProvider.notifier).remove(table.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TableRow(
      {required this.table, required this.onEdit, required this.onDelete});

  Color get _statusColor => switch (table.status) {
        TableStatus.available => AppColors.success,
        TableStatus.occupied  => AppColors.warning,
        TableStatus.reserved  => AppColors.outline,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.table_restaurant_rounded,
                color: _statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Table ${table.number}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text('${table.capacity} seats  •  ${table.status.name}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant)),
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
            onPressed: table.status == TableStatus.occupied ? null : onDelete,
            tooltip: table.status == TableStatus.occupied
                ? 'Cannot delete occupied table'
                : 'Delete',
          ),
        ],
      ),
    );
  }
}

class _TableDialog extends StatefulWidget {
  final RestaurantTable? existing;
  final int suggestedNumber;
  final void Function(int number, int capacity) onSave;

  const _TableDialog({
    required this.existing,
    required this.suggestedNumber,
    required this.onSave,
  });

  @override
  State<_TableDialog> createState() => _TableDialogState();
}

class _TableDialogState extends State<_TableDialog> {
  late final TextEditingController _number;
  late int _capacity;

  static const _capacities = [2, 4, 6, 8, 10, 12];

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(
      text: (widget.existing?.number ?? widget.suggestedNumber).toString(),
    );
    _capacity = widget.existing?.capacity ?? 4;
    if (!_capacities.contains(_capacity)) _capacity = 4;
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _save() {
    final number = int.tryParse(_number.text.trim());
    if (number == null || number < 1) return;
    widget.onSave(number, _capacity);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 340,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Table' : 'Add Table',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('TABLE NUMBER'),
              const SizedBox(height: 6),
              TextField(
                controller: _number,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDec('e.g. 1'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('CAPACITY (SEATS)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _capacities.map((c) {
                  final sel = c == _capacity;
                  return GestureDetector(
                    onTap: () => setState(() => _capacity = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 52,
                      height: 44,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel
                              ? AppColors.primary
                              : AppColors.outlineVariant,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$c',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: sel ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: _save,
                    child: Text(isEdit ? 'Save' : 'Add Table'),
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

// ─── Locations section (delivery neighbourhoods) ─────────────────────────────

class _LocationsSection extends ConsumerWidget {
  const _LocationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationsProvider);

    return _SectionShell(
      title: 'Locations',
      subtitle: 'Delivery neighbourhoods customers can choose from',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showDialog(context, ref, null),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Location'),
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
            child: locations.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No locations yet. Tap "Add Location" to get started.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < locations.length; i++) ...[
                        if (i > 0)
                          const Divider(
                              height: 1, color: AppColors.outlineVariant),
                        _LocationRow(
                          location: locations[i],
                          onEdit: () =>
                              _showDialog(context, ref, locations[i]),
                          onDelete: () =>
                              _confirmDelete(context, ref, locations[i]),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, Location? existing) {
    showDialog(
      context: context,
      builder: (_) => _LocationDialog(
        existing: existing,
        onSave: (name) {
          if (existing == null) {
            ref.read(locationsProvider.notifier).add(name);
          } else {
            ref.read(locationsProvider.notifier).update(existing.id, name);
          }
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Location location) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Location?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text(
          'Remove "${location.name}"? This cannot be undone.',
          style: const TextStyle(
              fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref.read(locationsProvider.notifier).remove(location.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final Location location;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LocationRow(
      {required this.location,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(location.name,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface)),
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
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _LocationDialog extends StatefulWidget {
  final Location? existing;
  final void Function(String name) onSave;

  const _LocationDialog({required this.existing, required this.onSave});

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    widget.onSave(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 340,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Location' : 'Add Location',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('LOCATION NAME'),
              const SizedBox(height: 6),
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDec('e.g. Downtown'),
                style: const TextStyle(fontSize: 14),
                onSubmitted: (_) => _save(),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: _save,
                    child: Text(isEdit ? 'Save' : 'Add Location'),
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

// ─── Cloud Sync ────────────────────────────────────────────────────────────────

class _CloudSection extends ConsumerStatefulWidget {
  const _CloudSection();

  @override
  ConsumerState<_CloudSection> createState() => _CloudSectionState();
}

class _CloudSectionState extends ConsumerState<_CloudSection> {
  late final TextEditingController _server;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _server = TextEditingController(
        text: ref.read(cloudSyncProvider).baseUrl);
  }

  @override
  void dispose() {
    _server.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final ok = await ref.read(cloudSyncProvider.notifier).connect(
          _server.text.trim(),
          _email.text.trim(),
          _password.text,
        );
    if (ok && mounted) {
      _password.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connected — menu, tables and staff downloaded ✓')));
    }
  }

  Future<void> _pullNow() async {
    final ok = await ref.read(cloudSyncProvider.notifier).pullNow();
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catalog refreshed from the cloud ✓')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloud = ref.watch(cloudSyncProvider);

    return _SectionShell(
      title: 'Cloud Sync',
      subtitle:
          'Connect this device to your EasyCasher cloud account — the POS keeps working offline, data syncs when online',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cloud.error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.4)),
              ),
              child: Text(cloud.error!,
                  style:
                      const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
          ],
          if (cloud.connected)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.cloud_done_rounded,
                        color: AppColors.success, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cloud.tenantName.isEmpty
                                ? 'Connected'
                                : 'Connected to ${cloud.tenantName}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cloud.lastPullAt == null
                                ? 'Catalog not downloaded yet'
                                : 'Last download: ${cloud.lastPullAt!.substring(0, 16).replaceFirst('T', ' ')}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    FilledButton.icon(
                      onPressed: cloud.busy ? null : _pullNow,
                      icon: cloud.busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                          cloud.busy ? 'Downloading…' : 'Download catalog'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: cloud.busy
                          ? null
                          : () => ref
                              .read(cloudSyncProvider.notifier)
                              .disconnect(),
                      icon: const Icon(Icons.link_off_rounded, size: 18),
                      label: const Text('Disconnect'),
                    ),
                  ]),
                ],
              ),
            )
          else
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('SERVER ADDRESS'),
                  TextField(
                    controller: _server,
                    decoration:
                        _inputDec('https://app.easycasherorder.online'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('OWNER / MANAGER EMAIL'),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDec('you@example.com'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('PASSWORD'),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: _inputDec('••••••••'),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (_) => _connect(),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: cloud.busy ? null : _connect,
                    icon: cloud.busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.cloud_rounded, size: 18),
                    label:
                        Text(cloud.busy ? 'Connecting…' : 'Connect to Cloud'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Connecting downloads your menu, tables and staff to this device. '
                    'After that the POS works fully offline.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
