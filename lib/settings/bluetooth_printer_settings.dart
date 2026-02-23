import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";
import "package:bluetooth_print_plus/bluetooth_print_plus.dart";

import "package:inventree/app_colors.dart";
import "package:inventree/l10.dart";
import "package:inventree/bluetooth_printer/bluetooth_printer_service.dart";
import "package:inventree/bluetooth_printer/esc_pos_label.dart";
import "package:inventree/widget/progress.dart";
import "package:inventree/widget/snacks.dart";

class BluetoothPrinterSettingsWidget extends StatefulWidget {
  @override
  _BluetoothPrinterSettingsState createState() =>
      _BluetoothPrinterSettingsState();
}

class _BluetoothPrinterSettingsState extends State<BluetoothPrinterSettingsWidget> {
  final BluetoothPrinterService _printerService = BluetoothPrinterService.instance;
  List<BluetoothDevice> _devices = [];
  bool _scanning = false;
  String _savedName = "";
  StreamSubscription<List<BluetoothDevice>>? _scanSub;
  StreamSubscription<bool>? _scanningSub;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    _scanSub = _printerService.scanResults.listen((list) {
      if (mounted) setState(() => _devices = list);
    });
    _scanningSub = _printerService.isScanning.listen((v) {
      if (mounted) setState(() => _scanning = v);
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _scanningSub?.cancel();
    _printerService.stopScan();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    await _printerService.loadSavedPrinter();
    _savedName = await _printerService.getSavedPrinterName();
    if (mounted) setState(() {});
  }

  Future<void> _startScan() async {
    await _printerService.startScan(timeout: Duration(seconds: 10));
  }

  Future<void> _stopScan() async {
    await _printerService.stopScan();
  }

  Future<void> _selectPrinter(BluetoothDevice device) async {
    await _printerService.connect(device);
    await _printerService.savePrinter(device);
    setState(() => _savedName = device.name.isNotEmpty ? device.name : device.address);
    showSnackIcon(L10().bluetoothPrinterConnected, success: true);
  }

  Future<void> _clearPrinter() async {
    await _printerService.disconnect();
    await _printerService.savePrinter(null);
    setState(() => _savedName = "");
    showSnackIcon(L10().bluetoothPrinterDisconnected, success: true);
  }

  Future<void> _testPrint() async {
    if (!_printerService.isConnected) {
      showSnackIcon(L10().bluetoothPrinterSelectFirst, success: false);
      return;
    }
    showLoadingOverlay();
    try {
      final bytes = await EscPosLabelBuilder.buildLabel(
        title: "InvenTree",
        lines: [L10().bluetoothPrinterTestLabel],
        barcode: "TEST-001",
      );
      await _printerService.writeBytes(bytes);
      if (!mounted) return;
      hideLoadingOverlay();
      showSnackIcon(L10().printLabelSuccess, success: true);
    } catch (e) {
      if (mounted) {
        hideLoadingOverlay();
        showSnackIcon(L10().printLabelFailure, success: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10().bluetoothPrinterSettings),
        backgroundColor: COLOR_APP_BAR,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(L10().bluetoothPrinterCurrent),
            subtitle: Text(
              _savedName.isEmpty ? L10().bluetoothPrinterNone : _savedName,
            ),
            leading: Icon(TablerIcons.printer),
          ),
          if (_savedName.isNotEmpty) ...[
            ListTile(
              title: Text(L10().bluetoothPrinterTestPrint),
              leading: Icon(TablerIcons.printer_search),
              onTap: _testPrint,
            ),
            ListTile(
              title: Text(L10().bluetoothPrinterDisconnect),
              leading: Icon(TablerIcons.link_off),
              onTap: _clearPrinter,
            ),
          ],
          Divider(),
          ListTile(
            title: Text(
              _scanning ? L10().bluetoothPrinterScanning : L10().bluetoothPrinterScan,
            ),
            subtitle: Text(L10().bluetoothPrinterScanDetail),
            leading: Icon(_scanning ? Icons.bluetooth_searching : TablerIcons.bluetooth),
            trailing: _scanning
                ? TextButton(
                    onPressed: _stopScan,
                    child: Text(L10().cancel),
                  )
                : null,
            onTap: _scanning ? null : _startScan,
          ),
          if (_devices.isNotEmpty) ...[
            Divider(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                L10().bluetoothPrinterFoundCount(_devices.length),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ..._devices.map((p) => ListTile(
                  title: Text(p.name.isNotEmpty ? p.name : p.address),
                  subtitle: Text(p.address),
                  leading: Icon(TablerIcons.printer),
                  onTap: () => _selectPrinter(p),
                )),
          ],
        ],
      ),
    );
  }
}
