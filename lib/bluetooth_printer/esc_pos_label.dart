import "package:esc_pos_utils_updated/esc_pos_utils_updated.dart";

/// 生成 ESC/POS 标签字节（用于蓝牙打印）
class EscPosLabelBuilder {
  EscPosLabelBuilder._();

  static const PaperSize _paperSize = PaperSize.mm80;

  static Future<List<int>> buildLabel({
    required String title,
    List<String> lines = const [],
    String? barcode,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(_paperSize, profile);
    List<int> bytes = [];

    bytes += generator.text(
      title,
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
      linesAfter: 1,
    );

    for (final line in lines) {
      if (line.isEmpty) continue;
      bytes += generator.text(line, styles: PosStyles(align: PosAlign.left));
      bytes += generator.text("");
    }

    if (barcode != null && barcode.isNotEmpty) {
      bytes += generator.feed(1);
      bytes += generator.text(
        "Barcode: $barcode",
        styles: PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);
    }

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  static Future<List<int>> buildStockItemLabel({
    required String partName,
    required String quantityOrSerial,
    String location = "",
    String? barcode,
  }) async {
    final lines = <String>[
      "Qty/SN: $quantityOrSerial",
      if (location.isNotEmpty) "Location: $location",
    ];
    return buildLabel(title: partName, lines: lines, barcode: barcode);
  }

  static Future<List<int>> buildReceiveLabel({
    required String partName,
    required String quantity,
    String? barcode,
  }) async {
    return buildLabel(
      title: partName,
      lines: ["Quantity: $quantity"],
      barcode: barcode,
    );
  }

  static Future<List<int>> buildLocationLabel({
    required String locationName,
    String? barcode,
  }) async {
    return buildLabel(title: locationName, lines: [], barcode: barcode);
  }
}
