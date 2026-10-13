import 'dart:async';
import 'package:flutter/material.dart';

import '../services/bluetooth_chat_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final BluetoothChatService _bluetoothService;

  StreamSubscription<List<dynamic>>? _devicesSubscription;
  StreamSubscription<String>? _statusSubscription;

  List<dynamic> _devices = [];

  String _status = 'اضغط على رمز البلوتوث للبحث عن الأجهزة';
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();

    _bluetoothService = BluetoothChatService();

    _devicesSubscription =
        _bluetoothService.onDevicesChanged.listen((devices) {
      if (!mounted) return;

      setState(() {
        _devices = devices;
      });
    });

    _statusSubscription =
        _bluetoothService.onStatusChanged.listen((status) {
      if (!mounted) return;

      setState(() {
        _status = status;
        _isSearching = status == 'جارٍ البحث عن الأجهزة...';
      });
    });
  }

  Future<void> _scanDevices() async {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _devices = [];
      _status = 'جارٍ البحث عن الأجهزة...';
    });

    try {
      await _bluetoothService.scanDevices();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _status = 'تعذر البحث عن الأجهزة. تحقق من البلوتوث والأذونات.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في البلوتوث: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _statusSubscription?.cancel();
    _bluetoothService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: const Text('واتساب بلوتوث'),
        actions: [
          IconButton(
            tooltip: 'البحث عن الأجهزة',
            icon: const Icon(Icons.bluetooth_searching),
            onPressed: _isSearching ? null : _scanDevices,
          ),
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'سنفعّل صفحة الإعدادات في الخطوة التالية.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFD7E8E4),
            child: Text(
              _status,
              textAlign: TextAlign.center,
            ),
          ),
          if (_isSearching)
            const LinearProgressIndicator(),
          Expanded(
            child: !_hasSearched
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bluetooth,
                          size: 64,
                          color: Color(0xFF075E54),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'ابحث عن أجهزة البلوتوث القريبة',
                          style: TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                  )
                : _devices.isEmpty && !_isSearching
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'لم يتم العثور على أجهزة. '
                            'تأكد من تشغيل البلوتوث، '
                            'واجعل الجهاز الآخر قابلًا للاكتشاف، '
                            'ثم أعد البحث.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final dynamic device = _devices[index];

                          String name = 'جهاز بلوتوث';
                          String address = '';

                          try {
                            final value = device.displayName;
                            if (value != null &&
                                value.toString().trim().isNotEmpty) {
                              name = value.toString();
                            }
                          } catch (_) {}

                          try {
                            address = device.address.toString();
                          } catch (_) {}

                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF075E54),
                              child: Icon(
                                Icons.bluetooth,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(name),
                            subtitle: Text(address),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم العثور على $name. '
                                    'سنضيف الاتصال في الخطوة التالية.',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        tooltip: 'البحث عن الأجهزة',
        onPressed: _isSearching ? null : _scanDevices,
        child: const Icon(Icons.bluetooth_searching),
      ),
    );
  }
}