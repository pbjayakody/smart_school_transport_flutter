import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptService {
  static Future<Uint8List> build(Map<String,Object?> payment, Map<String,String> settings) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(pageFormat: PdfPageFormat.a5, build: (_) => pw.Padding(
      padding: const pw.EdgeInsets.all(24),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(settings['company_name'] ?? 'Nethsara Transport', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text(settings['company_address'] ?? ''), pw.Text(settings['company_phone'] ?? ''),
        pw.SizedBox(height: 22), pw.Text('PAYMENT RECEIPT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)), pw.Divider(),
        _line('Receipt no.', payment['receipt_number']), _line('Date', payment['payment_date']),
        _line('Student', payment['name']), _line('Student ID', payment['student_code']),
        _line('Bus', payment['vehicle_number']), _line('Method', payment['payment_method']),
        pw.Divider(), _line('Amount paid', 'Rs. ${payment['amount']}'), pw.SizedBox(height: 24),
        pw.Text('Thank you.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ]),
    )));
    return doc.save();
  }
  static pw.Widget _line(String a,Object? b)=>pw.Padding(padding:const pw.EdgeInsets.symmetric(vertical:4),child:pw.Row(children:[pw.SizedBox(width:110,child:pw.Text(a)),pw.Expanded(child:pw.Text('${b??''}',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)))]));
  static Future<void> printReceipt(Map<String,Object?> payment, Map<String,String> settings) async => Printing.layoutPdf(onLayout: (_) => build(payment,settings));
}
