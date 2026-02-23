import "dart:typed_data";

import "package:bluetooth_print_plus/bluetooth_print_plus.dart";
import "package:inventree/preferences.dart";

/// 蓝牙打印服务（基于 bluetooth_print_plus，避免有问题的 flutter_bluetooth_basic_updated）
/// 注意：该包使用 BLE 扫描，部分仅支持经典蓝牙的打印机可能无法被扫描到
class BluetoothPrinterService {
  BluetoothPrinterService._();
  static final BluetoothPrinterService _instance = BluetoothPrinterService._();
  static BluetoothPrinterService get instance => _instance;

  BluetoothDevice? _savedDevice;

  Stream<List<BluetoothDevice>> get scanResults => BluetoothPrintPlus.scanResults;
  Stream<bool> get isScanning => BluetoothPrintPlus.isScanning;
  bool get isConnected => BluetoothPrintPlus.isConnected;
  BluetoothDevice? get savedDevice => _savedDevice;

  Future<void> loadSavedPrinter() async {
    final address = await InvenTreeSettingsManager().getValue(
      INV_BLUETOOTH_PRINTER_ADDRESS,
      null,
    ) as String?;
    final name = await InvenTreeSettingsManager().getValue(
      INV_BLUETOOTH_PRINTER_NAME,
      null,
    ) as String?;
    if (address != null && address.isNotEmpty) {
      _savedDevice = BluetoothDevice(name ?? "", address);
    } else {
      _savedDevice = null;
    }
  }

  Future<void> savePrinter(BluetoothDevice? device) async {
    _savedDevice = device;
    if (device != null) {
      await InvenTreeSettingsManager().setValue(
        INV_BLUETOOTH_PRINTER_ADDRESS,
        device.address,
      );
      await InvenTreeSettingsManager().setValue(
        INV_BLUETOOTH_PRINTER_NAME,
        device.name,
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

  Future<String> getSavedPrinterName() async {
    final name = await InvenTreeSettingsManager().getValue(
      INV_BLUETOOTH_PRINTER_NAME,
      "",
    ) as String?;
    return name ?? "";
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    await BluetoothPrintPlus.startScan(timeout: timeout);
  }

  Future<void> stopScan() async {
    await BluetoothPrintPlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    await BluetoothPrintPlus.connect(device);
  }

  Future<void> disconnect() async {
    await BluetoothPrintPlus.disconnect();
  }

  /// 若已保存过设备且当前未连接，则尝试重连（用于应用重启后直接打印）
  Future<bool> ensureConnected() async {
    if (BluetoothPrintPlus.isConnected) return true;
    if (_savedDevice == null) return false;
    try {
      await BluetoothPrintPlus.connect(_savedDevice!);
      return BluetoothPrintPlus.isConnected;
    } catch (_) {
      return false;
    }
  }

  /// 发送 ESC/POS 字节到已连接的设备
  Future<void> writeBytes(List<int> bytes) async {
    await BluetoothPrintPlus.write(Uint8List.fromList(bytes));
  }
}
