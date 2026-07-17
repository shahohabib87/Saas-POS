import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easycasher/core/constants/app_colors.dart';
import 'package:easycasher/core/database/app_database.dart';
import 'package:easycasher/features/auth/providers/auth_provider.dart';
import 'package:easycasher/features/shift/providers/shift_provider.dart';

/// Matches how the rest of the app renders money: IQD has no subunit, so
/// amounts are whole numbers.
String _money(double v) => 'IQD ${v.toStringAsFixed(0)}';

/// The cash drawer session. Open with a counted float, move cash in and out
/// with a reason, close against a physical count.
class ShiftScreen extends ConsumerWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(shift: shift),
        Expanded(
          child: shift == null ? const _ClosedDrawer() : _OpenDrawer(shift: shift),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final ShiftRow? shift;
  const _Header({required this.shift});

  @override
  Widget build(BuildContext context) {
    final open = shift != null;
    final color = open ? Colors.green : AppColors.onSurface.withValues(alpha: 0.4);

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
            'Shift',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: color),
                const SizedBox(width: 6),
                Text(
                  open ? 'Open' : 'Closed',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (open) ...[
            const SizedBox(width: 12),
            Text(
              'Opened by ${shift!.staffName} at ${_time(shift!.openedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _time(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ── Closed: offer to open ────────────────────────────────────────────────────

class _ClosedDrawer extends ConsumerStatefulWidget {
  const _ClosedDrawer();

  @override
  ConsumerState<_ClosedDrawer> createState() => _ClosedDrawerState();
}

class _ClosedDrawerState extends ConsumerState<_ClosedDrawer> {
  final _float = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final staff = ref.read(currentStaffProvider);
    if (staff == null) {
      setState(() => _error = 'Sign in before opening a shift.');
      return;
    }
    final amount = double.tryParse(_float.text.trim());
    if (amount == null || amount < 0) {
      setState(() => _error = 'Enter the counted starting cash.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(shiftProvider.notifier).open(staff: staff, openingFloat: amount);
    } on StateError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.point_of_sale_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No shift is open',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Count the cash already in the drawer and enter it as the\n'
              'starting float.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _float,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onSubmitted: (_) => _open(),
              decoration: InputDecoration(
                labelText: 'Starting float',
                prefixText: 'IQD ',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _open,
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: Text(_busy ? 'Opening…' : 'Open shift'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Open: X report, cash movements, close ────────────────────────────────────

class _OpenDrawer extends ConsumerWidget {
  final ShiftRow shift;
  const _OpenDrawer({required this.shift});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(shiftSummaryProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load shift: $e')),
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TakingsGrid(summary: summary),
              const SizedBox(height: 20),
              _Actions(shift: shift, summary: summary),
              const SizedBox(height: 20),
              _MovementsList(summary: summary),
            ],
          ),
        );
      },
    );
  }
}

class _TakingsGrid extends StatelessWidget {
  final ShiftSummary summary;
  const _TakingsGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Stat(label: 'Orders', value: '${summary.takings.orderCount}'),
        _Stat(label: 'Gross sales', value: _money(summary.takings.gross)),
        _Stat(label: 'Cash sales', value: _money(summary.takings.cashSales)),
        _Stat(label: 'Card sales', value: _money(summary.takings.cardSales)),
        _Stat(label: 'Opening float', value: _money(summary.openingFloat)),
        _Stat(label: 'Cash in', value: _money(summary.cashIn)),
        _Stat(label: 'Cash out', value: _money(summary.cashOut)),
        _Stat(
          label: 'Expected in drawer',
          value: _money(summary.expectedCash),
          emphasis: true,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasis;
  const _Stat({required this.label, required this.value, this.emphasis = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasis ? AppColors.primaryFixed : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasis ? AppColors.primary : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: emphasis ? AppColors.primary : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  final ShiftRow shift;
  final ShiftSummary summary;
  const _Actions({required this.shift, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => _showCashDialog(context, ref, isIn: true),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Cash in'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () => _showCashDialog(context, ref, isIn: false),
          icon: const Icon(Icons.remove_rounded, size: 16),
          label: const Text('Cash out'),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: () => _showCloseDialog(context, ref, summary),
          icon: const Icon(Icons.lock_rounded, size: 16),
          label: const Text('Close shift'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
        ),
      ],
    );
  }
}

Future<void> _showCashDialog(BuildContext context, WidgetRef ref,
    {required bool isIn}) async {
  final amount = TextEditingController();
  final reason = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isIn ? 'Cash in' : 'Cash out'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reason,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'e.g. bank drop, supplier paid in cash',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final value = double.tryParse(amount.text.trim());
            // A movement without an amount or a reason is unauditable, so
            // both are required rather than defaulted.
            if (value == null || value <= 0 || reason.text.trim().isEmpty) {
              return;
            }
            final staff = ref.read(currentStaffProvider);
            await ref.read(shiftProvider.notifier).addCash(
                  isIn: isIn,
                  amount: value,
                  reason: reason.text.trim(),
                  staffName: staff?.name ?? 'Unknown',
                );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Record'),
        ),
      ],
    ),
  );

  amount.dispose();
  reason.dispose();
}

Future<void> _showCloseDialog(
    BuildContext context, WidgetRef ref, ShiftSummary summary) async {
  final counted = TextEditingController();
  final note = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (ctx) => _CloseDialog(
      summary: summary,
      counted: counted,
      note: note,
    ),
  );

  counted.dispose();
  note.dispose();
}

/// Asks for the physical count *before* revealing the variance, so the number
/// the cashier types is a real count and not a copy of the expected figure.
class _CloseDialog extends ConsumerStatefulWidget {
  final ShiftSummary summary;
  final TextEditingController counted;
  final TextEditingController note;

  const _CloseDialog({
    required this.summary,
    required this.counted,
    required this.note,
  });

  @override
  ConsumerState<_CloseDialog> createState() => _CloseDialogState();
}

class _CloseDialogState extends ConsumerState<_CloseDialog> {
  double? _variance;

  @override
  Widget build(BuildContext context) {
    if (_variance != null) {
      final over = _variance! > 0;
      final exact = _variance!.abs() < 0.5; // IQD has no subunit
      return AlertDialog(
        title: const Text('Shift closed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ZLine(
                label: 'Expected',
                value: _money(widget.summary.expectedCash)),
            _ZLine(
                label: 'Counted',
                value: _money(double.parse(widget.counted.text.trim()))),
            const Divider(),
            _ZLine(
              label: exact ? 'Balanced' : (over ? 'Over' : 'Short'),
              value: exact ? '—' : _money(_variance!.abs()),
              color: exact
                  ? Colors.green
                  : (over ? Colors.blue : AppColors.danger),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Close shift'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Count the drawer and enter the total.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.counted,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Counted cash',
              prefixText: 'IQD ',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final value = double.tryParse(widget.counted.text.trim());
            if (value == null || value < 0) return;
            final expected = widget.summary.expectedCash;
            await ref.read(shiftProvider.notifier).close(
                  countedCash: value,
                  expectedCash: expected,
                  note: widget.note.text.trim(),
                );
            if (mounted) setState(() => _variance = value - expected);
          },
          child: const Text('Close shift'),
        ),
      ],
    );
  }
}

class _ZLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _ZLine({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: color ?? AppColors.onSurface)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementsList extends StatelessWidget {
  final ShiftSummary summary;
  const _MovementsList({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.movements.isEmpty) {
      return Text(
        'No cash movements this shift.',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.onSurface.withValues(alpha: 0.4),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CASH MOVEMENTS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ...summary.movements.map((m) {
          final isIn = m.kind == 'in';
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 16,
                  color: isIn ? Colors.green : AppColors.danger,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(m.reason,
                      style: const TextStyle(fontSize: 13)),
                ),
                Text(
                  '${isIn ? '+' : '−'}${_money(m.amount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isIn ? Colors.green : AppColors.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${m.staffName} · ${_time(m.at)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
