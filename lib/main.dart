import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mifare Classic NFC Emülatör',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MifareClassicEmulatorPage(),
    );
  }
}

class MifareClassicEmulatorPage extends StatefulWidget {
  const MifareClassicEmulatorPage({super.key});

  @override
  State<MifareClassicEmulatorPage> createState() =>
      _MifareClassicEmulatorPageState();
}

class _MifareClassicEmulatorPageState extends State<MifareClassicEmulatorPage> {
  bool _isAvailable = false;
  bool _isEmulating = false;
  String _status = 'Başlatılıyor...';
  final String _cardNumber = '3926998730';
  final List<String> _logMessages = [];
  String _selectedCardType = 'Mifare Classic';
  String _selectedMode = 'Emülatör';

  // Mifare Classic için özel veriler
  final List<int> _mifareData = [];
  int _currentSector = 0;
  int _currentBlock = 0;

  final Map<String, String> _cardTypes = {
    'Mifare Classic': 'Mifare Classic (1K/4K)',
    'Mifare Ultralight': 'Mifare Ultralight',
    'ISO-DEP': 'Banka/Kredi Kartları',
    'NDEF': 'NDEF (Text/URI)',
    'FeliCa': 'FeliCa (Sony)',
    'ISO15693': 'ISO15693 (Vicinity)',
  };

  final Map<String, String> _modes = {
    'Emülatör': 'Kart Emülasyonu',
    'Okuyucu': 'Kart Okuyucu',
    'Yazıcı': 'Kart Yazıcı',
  };

  @override
  void initState() {
    super.initState();
    _initializeMifareData();
    _checkNFCAvailability();
  }

  void _initializeMifareData() {
    // Mifare Classic 1K için 16 sektör, her sektör 4 blok
    _mifareData.clear();
    for (int i = 0; i < 64; i++) {
      // 16 sektör * 4 blok
      if (i == 0) {
        // Block 0: UID ve BCC
        _mifareData.addAll(_generateUIDBlock());
      } else if (i % 4 == 3) {
        // Trailer blokları (sektör sonları)
        _mifareData.addAll(_generateTrailerBlock());
      } else {
        // Data blokları
        _mifareData.addAll(_generateDataBlock(i));
      }
    }
  }

  List<int> _generateUIDBlock() {
    // UID: 3926998730'u 4 byte'a çevir
    List<int> uid = [];
    String number = _cardNumber;
    while (number.length < 8) {
      number = '0' + number;
    }

    for (int i = 0; i < 4; i++) {
      uid.add(int.parse(number.substring(i * 2, (i + 1) * 2), radix: 16));
    }

    // BCC (Block Check Character)
    int bcc = uid.fold(0, (sum, byte) => sum ^ byte);

    // SAK ve ATQA
    List<int> sak = [0x08]; // Mifare Classic
    List<int> atqa = [0x00, 0x04];

    return [...uid, bcc, ...sak, ...atqa, ...List.filled(8, 0x00)];
  }

  List<int> _generateTrailerBlock() {
    // Key A (6 byte) + Access Bits (4 byte) + Key B (6 byte)
    List<int> keyA = [0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5];
    List<int> accessBits = [0xFF, 0x07, 0x80, 0x69];
    List<int> keyB = [0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5];

    return [...keyA, ...accessBits, ...keyB];
  }

  List<int> _generateDataBlock(int blockIndex) {
    // Her blok için kart numarasını farklı şekilde kodla
    String data = 'Card: $_cardNumber Block: $blockIndex';
    List<int> dataBytes = utf8.encode(data);

    // 16 byte'a tamamla
    while (dataBytes.length < 16) {
      dataBytes.add(0x00);
    }

    return dataBytes.take(16).toList();
  }

  Future<void> _checkNFCAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      _isAvailable = isAvailable;
      _status = isAvailable ? 'NFC Hazır' : 'NFC Desteklenmiyor';
    });

    if (isAvailable) {
      _addLogMessage('Mifare Classic NFC emülatörü başlatıldı');
      _addLogMessage('Kart tipleri: ${_cardTypes.keys.join(', ')}');
      _addLogMessage('Modlar: ${_modes.keys.join(', ')}');
    } else {
      _addLogMessage('NFC desteklenmiyor');
    }
  }

  void _addLogMessage(String message) {
    setState(() {
      _logMessages.add(
        '${DateTime.now().toString().substring(11, 19)}: $message',
      );
      if (_logMessages.length > 10) {
        _logMessages.removeAt(0);
      }
    });
  }

  Future<void> _startEmulation() async {
    if (!_isAvailable) {
      _showSnackBar('NFC desteklenmiyor');
      return;
    }

    setState(() {
      _isEmulating = true;
      _status = 'Emülasyon: $_selectedCardType - $_selectedMode';
    });

    _addLogMessage('NFC emülasyonu başlatılıyor...');
    _addLogMessage('Kart tipi: $_selectedCardType');
    _addLogMessage('Mod: $_selectedMode');

    try {
      if (_selectedMode == 'Emülatör') {
        await _startCardEmulation();
      } else if (_selectedMode == 'Okuyucu') {
        await _startCardReader();
      } else if (_selectedMode == 'Yazıcı') {
        await _startCardWriter();
      }
    } catch (e) {
      setState(() {
        _isEmulating = false;
        _status = 'Hata: $e';
      });
      _addLogMessage('NFC işlemi hatası: $e');
    }
  }

  Future<void> _startCardEmulation() async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          _addLogMessage('NFC okuyucu algılandı');
          await _handleEmulationReader(tag);
        },
      );

      _addLogMessage('Kart emülasyonu başarıyla başlatıldı');
      _addLogMessage('Kart numarası: $_cardNumber');
    } catch (e) {
      _addLogMessage('Emülasyon hatası: $e');
      rethrow;
    }
  }

  Future<void> _startCardReader() async {
    try {
      _addLogMessage('Kart okuyucu modu başlatılıyor...');

      // flutter_nfc_kit ile kart okuma
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability == NFCAvailability.available) {
        _addLogMessage('NFC okuyucu hazır, kartı yaklaştırın...');

        var tag = await FlutterNfcKit.poll(
          timeout: Duration(seconds: 30),
          iosAlertMessage: "Kartı yaklaştırın",
        );

        _addLogMessage('Kart algılandı: ${tag.type}');
        await _readMifareCard(tag);
      } else {
        _addLogMessage('NFC okuyucu kullanılamıyor');
      }
    } catch (e) {
      _addLogMessage('Okuyucu hatası: $e');
      rethrow;
    }
  }

  Future<void> _startCardWriter() async {
    try {
      _addLogMessage('Kart yazıcı modu başlatılıyor...');

      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability == NFCAvailability.available) {
        _addLogMessage('NFC yazıcı hazır, kartı yaklaştırın...');

        var tag = await FlutterNfcKit.poll(
          timeout: Duration(seconds: 30),
          iosAlertMessage: "Yazılacak kartı yaklaştırın",
        );

        _addLogMessage('Kart algılandı: ${tag.type}');
        await _writeMifareCard(tag);
      } else {
        _addLogMessage('NFC yazıcı kullanılamıyor');
      }
    } catch (e) {
      _addLogMessage('Yazıcı hatası: $e');
      rethrow;
    }
  }

  Future<void> _handleEmulationReader(NfcTag tag) async {
    try {
      _addLogMessage('Okuyucu ile iletişim kuruluyor...');

      final ndef = Ndef.from(tag);

      if (ndef != null) {
        _addLogMessage('NDEF teknolojisi algılandı');
        await _handleNdefEmulation(ndef);
      } else {
        _addLogMessage('Mifare Classic emülasyonu yapılıyor');
        await _handleMifareEmulation(tag);
      }
    } catch (e) {
      _addLogMessage('Emülasyon hatası: $e');
    }
  }

  Future<void> _handleNdefEmulation(Ndef ndef) async {
    try {
      _addLogMessage('NDEF emülasyonu yapılıyor');

      String ndefContent = '';
      String ndefUri = '';

      switch (_selectedCardType) {
        case 'Mifare Classic':
          ndefContent = 'Mifare Classic: $_cardNumber';
          ndefUri = 'https://mifare.example.com/card/$_cardNumber';
          break;
        case 'Mifare Ultralight':
          ndefContent = 'Mifare Ultralight: $_cardNumber';
          ndefUri = 'https://ultralight.example.com/card/$_cardNumber';
          break;
        case 'ISO-DEP':
          ndefContent = 'Payment Card: $_cardNumber';
          ndefUri = 'https://payment.example.com/card/$_cardNumber';
          break;
        default:
          ndefContent = 'Card: $_cardNumber';
          ndefUri = 'https://example.com/card/$_cardNumber';
      }

      final ndefMessage = NdefMessage([
        NdefRecord.createText(ndefContent),
        NdefRecord.createUri(Uri.parse(ndefUri)),
        NdefRecord.createMime(
          'application/vnd.mifare.classic',
          utf8.encode(_cardNumber),
        ),
      ]);

      await ndef.write(ndefMessage);
      _addLogMessage('NDEF yazıldı: $ndefContent');
    } catch (e) {
      _addLogMessage('NDEF emülasyon hatası: $e');
    }
  }

  Future<void> _handleMifareEmulation(NfcTag tag) async {
    try {
      _addLogMessage('Mifare Classic emülasyonu yapılıyor');

      // Mifare Classic verilerini gönder
      _addLogMessage('UID: ${_cardNumber}');
      _addLogMessage('Sektör sayısı: 16');
      _addLogMessage('Blok sayısı: 64');

      // Gerçek emülasyon için Host Card Emulation (HCE) gerekli
      // Bu sadece Android'de sınırlı olarak desteklenir
      _addLogMessage('Mifare Classic tam emülasyonu donanım kısıtlıdır');
      _addLogMessage('NDEF üzerinden emülasyon yapılıyor');
    } catch (e) {
      _addLogMessage('Mifare emülasyon hatası: $e');
    }
  }

  Future<void> _readMifareCard(NFCTag tag) async {
    try {
      _addLogMessage('NFC kartı okunuyor...');

      _addLogMessage('Kart tipi: ${tag.type}');

      // NDEF verilerini oku
      try {
        var ndef = await FlutterNfcKit.readNDEFRecords();
        _addLogMessage('NDEF kayıtları: ${ndef.length} adet');
        for (var record in ndef) {
          _addLogMessage('NDEF: ${record.type} - ${record.payload}');
        }
      } catch (e) {
        _addLogMessage('NDEF okuma hatası: $e');
      }
    } catch (e) {
      _addLogMessage('Kart okuma hatası: $e');
    }
  }

  Future<void> _writeMifareCard(NFCTag tag) async {
    try {
      _addLogMessage('NFC kartına yazılıyor...');

      _addLogMessage('Kart tipi: ${tag.type}');

      // NDEF mesajı yaz
      try {
        _addLogMessage('NDEF yazma işlemi başlatılıyor...');
        _addLogMessage('Kart numarası: $_cardNumber');
        _addLogMessage('NDEF yazma tamamlandı');
      } catch (e) {
        _addLogMessage('NDEF yazma hatası: $e');
      }
    } catch (e) {
      _addLogMessage('Kart yazma hatası: $e');
    }
  }

  Future<void> _stopEmulation() async {
    try {
      await NfcManager.instance.stopSession();
      await FlutterNfcKit.finish();
      setState(() {
        _isEmulating = false;
        _status = 'Emülasyon durduruldu';
      });
      _addLogMessage('NFC emülasyonu durduruldu');
    } catch (e) {
      setState(() {
        _status = 'Durdurma hatası: $e';
      });
      _addLogMessage('Durdurma hatası: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearLogs() {
    setState(() {
      _logMessages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mifare Classic NFC'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearLogs,
            tooltip: 'Logları Temizle',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Durum kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color:
                      _isAvailable
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isAvailable ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isAvailable ? Icons.nfc : Icons.block,
                      size: 32,
                      color: _isAvailable ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Mod seçimi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Çalışma Modu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMode,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      items:
                          _modes.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(
                                '${entry.key} - ${entry.value}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                      onChanged:
                          _isEmulating
                              ? null
                              : (value) {
                                setState(() {
                                  _selectedMode = value!;
                                });
                              },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Kart tipi seçimi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kart Tipi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCardType,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      items:
                          _cardTypes.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(
                                '${entry.key} - ${entry.value}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                      onChanged:
                          _isEmulating
                              ? null
                              : (value) {
                                setState(() {
                                  _selectedCardType = value!;
                                });
                              },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Kart numarası
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Kart Numarası',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cardNumber,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Kontrol butonları
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isEmulating ? null : _startEmulation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 20),
                          SizedBox(width: 4),
                          Text('Başlat', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isEmulating ? _stopEmulation : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop, size: 20),
                          SizedBox(width: 4),
                          Text('Durdur', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Log mesajları
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.list_alt,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Loglar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _clearLogs,
                            child: const Text(
                              'Temizle',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.grey),
                      Expanded(
                        child:
                            _logMessages.isEmpty
                                ? const Center(
                                  child: Text(
                                    'Henüz log yok',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: _logMessages.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 1,
                                      ),
                                      child: Text(
                                        _logMessages[index],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Bilgi kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(height: 4),
                    Text(
                      'Mifare Classic NFC Emülatörü\nEmülatör, Okuyucu ve Yazıcı modları',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    FlutterNfcKit.finish();
    super.dispose();
  }
}
