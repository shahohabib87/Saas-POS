import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/auth/models/app_permission.dart';
import 'package:easycasher/features/auth/models/staff.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/features/settings/models/app_settings.dart';
import 'package:easycasher/features/settings/providers/settings_provider.dart';
import 'package:easycasher/core/sync/cloud_sync.dart';
import 'package:easycasher/features/kitchen/providers/kitchen_link_provider.dart';

/// Records are created and edited in the web console, not here — the terminal
/// only operates on what the cloud sends down. So there is no table CRUD, and
/// no delivery-area editor: areas carry a fee and are managed centrally, then
/// picked at the till (see delivery_details_card.dart).
enum _Section { restaurant, serviceMode, tax, receipt, staff, permissions, cloud }

extension _SectionX on _Section {
  String get label => switch (this) {
        _Section.restaurant  => 'Restaurant',
        _Section.serviceMode => 'Service Mode',
        _Section.tax         => 'Tax',
        _Section.receipt     => 'Receipt',
        _Section.staff       => 'Staff',
        _Section.permissions => 'Permissions',
        _Section.cloud       => 'Cloud Sync',
      };
  IconData get icon => switch (this) {
        _Section.restaurant  => Icons.storefront_rounded,
        _Section.serviceMode => Icons.restaurant_rounded,
        _Section.tax         => Icons.percent_rounded,
        _Section.receipt     => Icons.receipt_long_rounded,
        _Section.staff       => Icons.people_rounded,
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
    final staff = ref.watch(currentStaffProvider);
    final isAdmin = staff?.role == StaffRole.admin;

    final visible = _Section.values.where((s) {
      if (s == _Section.permissions) return isAdmin;
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
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cloud.pendingSales > 0
                          ? AppColors.warning.withValues(alpha: 0.10)
                          : AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cloud.pendingSales > 0
                          ? '⏳ ${cloud.pendingSales} sale${cloud.pendingSales == 1 ? '' : 's'} waiting to sync'
                          : '✓ All sales synced to the cloud',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cloud.pendingSales > 0
                              ? AppColors.warning
                              : AppColors.success),
                    ),
                  ),
                  if (cloud.branches.length > 1) ...[
                    const SizedBox(height: 16),
                    const _FieldLabel('BRANCH (THIS TERMINAL)'),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      // Keyed by the selection so a re-pull's state change
                      // rebuilds the field with the new value.
                      key: ValueKey('branch-${cloud.branchId}'),
                      initialValue: cloud.branchId,
                      isExpanded: true,
                      decoration: _inputDec('Select this terminal’s branch'),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.onSurface),
                      items: [
                        for (final b in cloud.branches)
                          DropdownMenuItem(
                            value: b['id'] as String,
                            child: Text((b['name'] ?? '') as String),
                          ),
                      ],
                      onChanged: cloud.busy
                          ? null
                          : (id) {
                              if (id == null) return;
                              final b = cloud.branches
                                  .firstWhere((x) => x['id'] == id);
                              ref.read(cloudSyncProvider.notifier).selectBranch(
                                  id, (b['name'] ?? '') as String);
                            },
                    ),
                    if (cloud.needsBranchChoice)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Pick which branch this till operates — its tables, '
                          'drivers and delivery areas load for that branch, and '
                          'its sales are recorded against it.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.warning),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  Row(children: [
                    FilledButton.icon(
                      onPressed: cloud.busy
                          ? null
                          : () => ref
                              .read(cloudSyncProvider.notifier)
                              .flush(),
                      icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: const Text('Sync now'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
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
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('DEVICE MODE'),
                const SizedBox(height: 4),
                Row(children: [
                  ChoiceChip(
                    label: const Text('Full POS'),
                    selected: cloud.deviceMode == DeviceMode.full,
                    onSelected: (_) => ref
                        .read(cloudSyncProvider.notifier)
                        .setDeviceMode(DeviceMode.full),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Kitchen Display only'),
                    selected: cloud.deviceMode == DeviceMode.kds,
                    onSelected: (_) => ref
                        .read(cloudSyncProvider.notifier)
                        .setDeviceMode(DeviceMode.kds),
                  ),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Kitchen Display only: whoever logs in on this device lands on the kitchen board.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                const _KdsLinkSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// LAN kitchen link. On a till this shows the address kitchen devices dial;
/// on a device being set up as a KDS it takes the till's address. Set the
/// address BEFORE switching the mode — a KDS device boots straight to the
/// board (a manager can still exit KDS mode from the board's header).
class _KdsLinkSettings extends ConsumerStatefulWidget {
  const _KdsLinkSettings();

  @override
  ConsumerState<_KdsLinkSettings> createState() => _KdsLinkSettingsState();
}

class _KdsLinkSettingsState extends ConsumerState<_KdsLinkSettings> {
  final _addr = TextEditingController();
  bool _seeded = false;
  bool _saved = false;

  @override
  void dispose() {
    _addr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = ref.watch(kitchenLinkProvider);

    // Seed the field once from the stored address (it loads async).
    if (!_seeded && link.tillAddress.isNotEmpty && _addr.text.isEmpty) {
      _addr.text = link.tillAddress;
      _seeded = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (link.serverAddress.isNotEmpty) ...[
          Text(
            'Kitchen displays on this network connect to:  ${link.serverAddress}'
            '${link.clients > 0 ? '   ·   ${link.clients} connected' : ''}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface),
          ),
          const SizedBox(height: 10),
        ],
        const _FieldLabel('TILL ADDRESS (FOR A KITCHEN DISPLAY DEVICE)'),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _addr,
                decoration: const InputDecoration(
                  hintText: 'e.g. 192.168.1.10',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (_) => setState(() => _saved = false),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                await ref
                    .read(kitchenLinkProvider.notifier)
                    .setTillAddress(_addr.text);
                if (mounted) setState(() => _saved = true);
              },
              child: Text(_saved ? 'Saved ✓' : 'Save'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'On the kitchen device: enter the till\'s address shown above, save, '
          'then switch this device to "Kitchen Display only".',
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
