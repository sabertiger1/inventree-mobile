import "dart:async";

import "package:esc_pos_bluetooth_updated/esc_pos_bluetooth_updated.dart";
import "package:inventree/preferences.dart";

/// 蓝牙 ESC/POS 打印机服务：扫描、连接、打印
class BluetoothPrinterService {
  BluetoothPrinterService._();
  static final BluetoothPrinterService _instance = BluetoothPrinterService._();
  static BluetoothPrinterService get instance => _instance;

  final PrinterBluetoothManager _manager = PrinterBluetoothManager();
  PrinterBluetooth? _selectedPrinter;
  String? _savedAddress;

  Stream<List<PrinterBluetooth>> get scanResults => _manager.scanResults;
  Stream<bool> get isScanning => _manager.isScanningStream;
  PrinterBluetooth? get selectedPrinter => _selectedPrinter;
  bool get isConnected => _selectedPrinter != null;

  /// 从设置加载已保存的打印机地址（不自动连接，需用户再次选择或扫描后连接）
  Future<void> loadSavedPrinter() async {
    _savedAddress = await InvenTreeSettingsManager().getValue(
      INV_BLUETOOTH_PRINTER_ADDRESS,
      null,
    ) as String?;
  }

  /// 保存选中的打印机到设置
  Future<void> savePrinter(PrinterBluetooth? printer) async {
    _selectedPrinter = printer;
    if (printer != null) {
      await InvenTreeSettingsManager().setValue(
        INV_BLUETOOTH_PRINTER_ADDRESS,
        printer.address ?? "",
      );
      await InvenTreeSettingsManager().setValue(
        INV_BLUETOOTH_PRINTER_NAME,
        printer.name ?? "",
      );
    } else {
      await InvenTreeSettingsManager().setValue(
        INV_BLUETOOTH_PRINTER_ADDRESS,
        "",
      );
      await InvenTreeSettingsManager().setValue(
        INV_BLUETOOTH_PRINTER_NAME,
        "",
      );
    }
  }

  /// 获取已保存的打印机名称（用于 UI 显示）
  Future<String> getSavedPrinterName() async {
    final name = await InvenTreeSettingsManager().getValue(
      INV_BLUETOOTH_PRINTER_NAME,
      "",
    ) as String?;
    return name ?? "";
  }

  void startScan({Duration timeout = const Duration(seconds: 8)}) {
    _manager.startScan(timeout);
  }

  void stopScan() {
    _manager.stopScan();
  }

  /// 选择并连接打印机（后续打印将发往该设备）
  void selectPrinter(PrinterBluetooth printer) {
    _manager.selectPrinter(printer);
    _selectedPrinter = printer;
  }

  /// 断开当前打印机（不删除已保存的设置）
  void disconnect() {
    _selectedPrinter = null;
  }

  /// 发送 ESC/POS 字节到当前选中的打印机
  /// [bytes] 由 EscPosLabelBuilder 生成
  Future<PosPrintResult> printBytes(List<int> bytes) async {
    if (_selectedPrinter == null) {
      return PosPrintResult.printerNotSelected;
    }
    return _manager.printTicket(
      bytes,
      chunkSizeBytes: 512,
      queueSleepTimeMs: 50,
    );
  }
}
