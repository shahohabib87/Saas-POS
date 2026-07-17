import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/features/delivery/providers/delivery_provider.dart';

/// Captured at the till when the order is a delivery: who to call, who is
/// taking it, where it is going and what that costs.
///
/// Drivers and areas come from the cloud and are read-only here — they are
/// managed in the web console. The card collapses to a summary once complete
/// so it stops competing with the cart for space.
class DeliveryDetailsCard extends ConsumerStatefulWidget {
  const DeliveryDetailsCard({super.key});

  @override
  ConsumerState<DeliveryDetailsCard> createState() =>
      _DeliveryDetailsCardState();
}

class _DeliveryDetailsCardState extends ConsumerState<DeliveryDetailsCard> {
  late final TextEditingController _phone;
  late final TextEditingController _name;
  late final TextEditingController _notes;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    final d = ref.read(deliveryDetailsProvider);
    _phone = TextEditingController(text: d.phone);
    _name = TextEditingController(text: d.customerName);
    _notes = TextEditingController(text: d.notes);
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(deliveryDetailsProvider);
    final notifier = ref.read(deliveryDetailsProvider.notifier);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  const Icon(Icons.moped_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Delivery details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_expanded && details.isComplete)
                    Expanded(
                      child: Text(
                        details.phone,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  else if (!details.isComplete)
                    const _IncompleteChip(),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  _Field(
                    controller: _phone,
                    hint: 'Phone number *',
                    keyboardType: TextInputType.phone,
                    // The phone is how the driver rescues a delivery when the
                    // address turns out to be wrong, so it is flagged visually
                    // until filled.
                    invalid: details.phone.trim().isEmpty,
                    onChanged: notifier.setPhone,
                  ),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _name,
                    hint: 'Customer name',
                    onChanged: notifier.setCustomerName,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _DriverPicker(details: details)),
                      const SizedBox(width: 8),
                      Expanded(child: _AreaPicker(details: details)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _notes,
                    hint: 'Notes (landmark, street, floor…)',
                    onChanged: notifier.setNotes,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _IncompleteChip extends StatelessWidget {
  const _IncompleteChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Incomplete',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.danger,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool invalid;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.invalid = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: invalid
            ? AppColors.danger.withValues(alpha: 0.5)
            : AppColors.outlineVariant,
      ),
    );

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: invalid
              ? AppColors.danger.withValues(alpha: 0.7)
              : AppColors.onSurface.withValues(alpha: 0.35),
        ),
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _DriverPicker extends ConsumerWidget {
  final DeliveryDetails details;
  const _DriverPicker({required this.details});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(driversProvider);

    return driversAsync.when(
      loading: () => const _PickerShell(child: Text('Loading…')),
      error: (_, _) => const _PickerShell(child: Text('Drivers unavailable')),
      data: (drivers) {
        if (drivers.isEmpty) {
          // Not an error: a terminal that has never synced simply has none.
          return const _PickerShell(
            child: Text(
              'No drivers — add them on the web',
              style: TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        return _Dropdown<String>(
          value: details.driverId,
          hint: 'Driver *',
          invalid: details.driverId == null,
          items: [
            for (final d in drivers)
              DropdownMenuItem(value: d.id, child: Text(d.name)),
          ],
          onChanged: ref.read(deliveryDetailsProvider.notifier).setDriver,
        );
      },
    );
  }
}

class _AreaPicker extends ConsumerWidget {
  final DeliveryDetails details;
  const _AreaPicker({required this.details});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(deliveryAreasProvider);

    return areasAsync.when(
      loading: () => const _PickerShell(child: Text('Loading…')),
      error: (_, _) => const _PickerShell(child: Text('Areas unavailable')),
      data: (areas) {
        if (areas.isEmpty) {
          return const _PickerShell(
            child: Text(
              'No areas — add them on the web',
              style: TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        return _Dropdown<String>(
          value: details.areaId,
          hint: 'Area / fee *',
          invalid: details.areaId == null,
          items: [
            for (final a in areas)
              DropdownMenuItem(
                value: a.id,
                child: Text(
                  a.isFree ? '${a.name} · Free' : '${a.name} · IQD ${a.fee.toStringAsFixed(0)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) {
            final area = areas.where((a) => a.id == id).firstOrNull;
            ref.read(deliveryDetailsProvider.notifier).setArea(area);
          },
        );
      },
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final bool invalid;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.invalid = false,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerShell(
      invalid: invalid,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              color: invalid
                  ? AppColors.danger.withValues(alpha: 0.7)
                  : AppColors.onSurface.withValues(alpha: 0.35),
            ),
          ),
          style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PickerShell extends StatelessWidget {
  final Widget child;
  final bool invalid;
  const _PickerShell({required this.child, this.invalid = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: invalid
              ? AppColors.danger.withValues(alpha: 0.5)
              : AppColors.outlineVariant,
        ),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 13,
          color: AppColors.onSurface.withValues(alpha: 0.5),
        ),
        child: child,
      ),
    );
  }
}
