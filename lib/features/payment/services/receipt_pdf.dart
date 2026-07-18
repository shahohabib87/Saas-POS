import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:easycasher/core/constants/app_constants.dart';
import 'package:easycasher/features/payment/models/payment.dart';
import 'package:easycasher/features/settings/models/app_settings.dart';

/// Turns a completed sale into an 80mm-roll receipt and hands it to the OS
/// print dialog. Split from the widget so [buildReceipt] can be exercised in a
/// test with no printer attached — the button used to only show a toast.
Future<void> printReceipt(CompletedPayment p, AppSettings settings) async {
  final doc = buildReceipt(p, settings);
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

/// Build (but don't print) the receipt document. Pure, so it is unit-testable.
pw.Document buildReceipt(CompletedPayment p, AppSettings s) {
  final doc = pw.Document();

  String money(double v) => v.toStringAsFixed(0);
  String two(int n) => n.toString().padLeft(2, '0');
  final dt = p.timestamp;
  final when =
      '${two(dt.day)}/${two(dt.month)}/${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';

  pw.Widget line(String left, String right, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: bold ? 11 : 9,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(left, style: style), pw.Text(right, style: style)],
    );
  }

  pw.Widget divider() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Divider(height: 1, thickness: 0.5),
      );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      margin: const pw.EdgeInsets.all(8),
      build: (context) {
        final rows = <pw.Widget>[
          pw.Center(
            child: pw.Text(s.restaurantName,
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ),
          if (s.restaurantAddress.isNotEmpty)
            pw.Center(
                child: pw.Text(s.restaurantAddress,
                    style: const pw.TextStyle(fontSize: 8))),
          if (s.restaurantPhone.isNotEmpty)
            pw.Center(
                child: pw.Text(s.restaurantPhone,
                    style: const pw.TextStyle(fontSize: 8))),
          pw.SizedBox(height: 6),
          divider(),
          line(p.orderNumber, p.orderType),
          line(when, p.staffName),
          divider(),
        ];

        for (final it in p.items) {
          rows.add(line('${it.quantity} x ${it.name}',
              money(it.unitPrice * it.quantity)));
          if (it.modifiersLabel.isNotEmpty) {
            rows.add(pw.Text('   ${it.modifiersLabel}',
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)));
          }
        }

        rows.add(divider());
        rows.add(line('Subtotal', money(p.subtotal)));
        if (p.discountAmount > 0) {
          rows.add(line('Discount', '-${money(p.discountAmount)}'));
        }
        if (p.tax > 0) rows.add(line('Tax', money(p.tax)));
        if (p.tip > 0) rows.add(line('Tip', money(p.tip)));
        if (p.deliveryFee > 0) rows.add(line('Delivery', money(p.deliveryFee)));
        rows.add(pw.SizedBox(height: 2));
        rows.add(line('TOTAL', '${money(p.total)} ${AppConstants.currencySymbol}',
            bold: true));
        rows.add(pw.SizedBox(height: 4));
        rows.add(line('Paid (${p.method.name})',
            money(p.method == PaymentMethod.cash ? p.cashPaid : p.cardPaid)));
        if (p.method == PaymentMethod.cash && p.change > 0) {
          rows.add(line('Change', money(p.change)));
        }

        if (p.customerName.isNotEmpty || p.customerPhone.isNotEmpty) {
          rows.add(divider());
          if (p.customerName.isNotEmpty) {
            rows.add(pw.Text('Customer: ${p.customerName}',
                style: const pw.TextStyle(fontSize: 8)));
          }
          if (p.customerPhone.isNotEmpty) {
            rows.add(pw.Text('Phone: ${p.customerPhone}',
                style: const pw.TextStyle(fontSize: 8)));
          }
          if (p.deliveryNotes.isNotEmpty) {
            rows.add(pw.Text('Notes: ${p.deliveryNotes}',
                style: const pw.TextStyle(fontSize: 8)));
          }
        }

        rows.add(pw.SizedBox(height: 6));
        if (s.receiptFooter.isNotEmpty) {
          rows.add(pw.Center(
            child: pw.Text(s.receiptFooter,
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center),
          ));
        }

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    ),
  );

  return doc;
}
