import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Model/Marketing/school_visit_model.dart';
import 'package:intl/intl.dart';

class ExcelService {
  Future<void> exportVisits(List<SchoolVisit> visits) async {
    try {
      var excel = Excel.createExcel();
      // Use the default sheet
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      Sheet sheetObject = excel[defaultSheet];

      print(
          "🟢 Starting Excel Generation for ${visits.length} items. Writing to sheet: $defaultSheet");

      // Add Headers
      List<String> headers = [
        "School Name",
        "City",
        "State",
        "Status",
        "Visit Date",
        "Revisit Date",
        "Assigned To",
        "Created By",
        "Contact Person",
        "Phone",
        "Proposal Sent",
        "Proposal Approved",
        "PO Received",
        "Payment Confirmed"
      ];

      try {
        sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());
        print("✅ Added headers");
      } catch (e) {
        print("❌ Error adding headers: $e");
      }

      // Add Data
      for (var visit in visits) {
        String contactName = visit.contactPersons.isNotEmpty
            ? visit.contactPersons.first.name
            : "N/A";
        String contactPhone = visit.contactPersons.isNotEmpty
            ? visit.contactPersons.first.phone
            : "N/A";

        List<CellValue> row = [
          TextCellValue(visit.schoolProfile.name),
          TextCellValue(visit.schoolProfile.city),
          TextCellValue(visit.schoolProfile.state),
          TextCellValue(visit.visitDetails.status),
          TextCellValue(visit.visitDetails.visitDate ?? ""),
          TextCellValue(visit.visitDetails.revisitDate ?? ""),
          TextCellValue(visit.assignedUserName ?? "Unassigned"),
          TextCellValue(visit.createdByUserName),
          TextCellValue(contactName),
          TextCellValue(contactPhone),
          TextCellValue(visit.proposalChecklist.sent ? "Yes" : "No"),
          TextCellValue(visit.proposalChecklist.approved ? "Yes" : "No"),
          TextCellValue(visit.purchaseOrder.poReceived ? "Yes" : "No"),
          TextCellValue(visit.payment.paymentConfirmed ? "Yes" : "No"),
        ];

        sheetObject.appendRow(row);
      }
      print("✅ Finished adding ${visits.length} rows");

      // Save to temporary file
      var fileBytes = excel.save();
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = "School_Visits_$timestamp.xlsx";

      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        // Desktop: Save to Downloads
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final file = File("${downloadsDir.path}/$fileName");
          await file.writeAsBytes(fileBytes!);

          // Open file
          final uri = Uri.file(file.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            // Fallback if can't launch directly (maybe show in finder?)
            // For now just throw so UI shows error or success message
            print("Could not launch file: ${file.path}");
          }
          return;
        }
      }

      // Mobile / Fallback: Share
      var directory = await getTemporaryDirectory();
      File tempFile = File("${directory.path}/$fileName");
      await tempFile.create(recursive: true);
      await tempFile.writeAsBytes(fileBytes!);

      // Share/Export using share_plus
      final files = <XFile>[
        XFile(
          tempFile.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        )
      ];
      // ignore: deprecated_member_use
      await Share.shareXFiles(files, text: 'Here is the School Visits Report');
    } catch (e) {
      // ignore: avoid_print
      print("Error generating Excel: $e");
      rethrow;
    }
  }
}
