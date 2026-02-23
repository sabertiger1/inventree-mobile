import "package:esc_pos_utils_updated/esc_pos_utils_updated.dart";

/// 使用 ESC/POS 协议生成标签字节（用于蓝牙打印机）
class EscPosLabelBuilder {
  EscPosLabelBuilder._();

  static const PaperSize _paperSize = PaperSize.mm80;

  /// 生成入库/出库标签字节：标题、多行文本、可选条形码
  /// [title] 如 "入库" / "出库" / 零件名
  /// [lines] 额外行，如 数量、库位、序列号
  /// [barcode] 可选，用于扫码的字符串（如 InvenTree 条码或序列号）
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
      bytes += generator.text("Barcode: $barcode",
          styles: PosStyles(align: PosAlign.center));
      bytes += generator.feed(1);
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  /// 库存项标签：零件名、数量/序列号、库位、条码
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
    return buildLabel(
      title: partName,
      lines: lines,
      barcode: barcode,
    );
  }

  /// 采购收货行标签：零件名、数量、可选条码
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

  /// 库位标签
  static Future<List<int>> buildLocationLabel({
    required String locationName,
    String? barcode,
  }) async {
    return buildLabel(
      title: locationName,
      lines: [],
      barcode: barcode,
    );
  }
}
