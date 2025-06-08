import 'package:flutter/material.dart';
import '../../api/transaksi_api.dart';
import '../../api/detail_transaksi_api.dart';
import '../../models/transaksi_model.dart';
import '../../models/detail_transaksi_model.dart';
import '../../components/layouts/base_layout.dart';
import '../../utils/local_storage.dart';
import '../../components/custom_app_bar.dart';

class RiwayatTransaksiPage extends StatefulWidget {
  const RiwayatTransaksiPage({super.key});

  @override
  State<RiwayatTransaksiPage> createState() => _RiwayatTransaksiPageState();
}

class _RiwayatTransaksiPageState extends State<RiwayatTransaksiPage> {
  final TransaksiApi _transaksiApi = TransaksiApi();
  final DetailTransaksiApi _detailTransaksiApi = DetailTransaksiApi();

  List<TransaksiModel> _transaksiList = [];
  Map<int, List<DetailTransaksiModel>> _detailTransaksiMap = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
  }

  Future<void> _loadTransaksi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mendapatkan data user dari local storage
      final userData = await LocalStorage.getUserMap();
      print('=== DEBUG: User Data ===');
      print('User data from local storage: $userData');

      if (userData == null) {
        setState(() {
          _errorMessage = 'Anda perlu login terlebih dahulu';
          _isLoading = false;
        });
        return;
      }

      // Mendapatkan id_pembeli dari user dan pastikan itu integer
      final idPembeli = userData['id_pembeli'];
      print('ID Pembeli from user data: $idPembeli (${idPembeli.runtimeType})');

      if (idPembeli == null) {
        setState(() {
          _errorMessage = 'Data pembeli tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      // Pastikan idPembeli adalah integer
      final int idPembeliInt = int.tryParse(idPembeli.toString()) ?? 0;
      print('Converted ID Pembeli: $idPembeliInt');

      if (idPembeliInt == 0) {
        setState(() {
          _errorMessage = 'ID Pembeli tidak valid';
          _isLoading = false;
        });
        return;
      }

      // Mendapatkan daftar transaksi dari API
      final response = await _transaksiApi.getTransaksiByPembeli(idPembeliInt);
      print('=== DEBUG: API Response ===');
      print('Raw response type: ${response.runtimeType}');
      print('Raw response: $response');

      if (response != null && response is! String) {
        // Parse daftar transaksi
        List<TransaksiModel> transaksiList = [];
        if (response is List) {
          print('Processing list response with ${response.length} items');
          transaksiList =
              response
                  .map((item) {
                    print('Processing item: $item');
                    try {
                      return TransaksiModel.fromJson(item);
                    } catch (e) {
                      print('Error parsing item: $e');
                      return null;
                    }
                  })
                  .whereType<TransaksiModel>()
                  .toList();
        } else if (response is Map && response.containsKey('data')) {
          if (response['data'] is List) {
            print(
              'Processing data wrapper with ${response['data'].length} items',
            );
            transaksiList =
                (response['data'] as List)
                    .map((item) {
                      print('Processing item from data: $item');
                      try {
                        return TransaksiModel.fromJson(item);
                      } catch (e) {
                        print('Error parsing item from data: $e');
                        return null;
                      }
                    })
                    .whereType<TransaksiModel>()
                    .toList();
          }
        }

        print('=== DEBUG: Parsed Results ===');
        print('Number of transactions parsed: ${transaksiList.length}');
        for (var transaksi in transaksiList) {
          print('Transaksi ID: ${transaksi.idTransaksi}');
          print('Status: ${transaksi.statusTransaksi}');
          print('Tanggal: ${transaksi.tanggalTransaksi}');
        }

        setState(() {
          _transaksiList = transaksiList;
        });

        // Ambil detail untuk setiap transaksi
        for (var transaksi in _transaksiList) {
          print('Fetching details for transaction ${transaksi.idTransaksi}');
          await _loadDetailTransaksi(transaksi.idTransaksi);
        }
      } else {
        print('Response is null or invalid: $response');
        setState(() {
          _errorMessage = 'Tidak ada data transaksi';
        });
      }
    } catch (e) {
      print('=== DEBUG: Error ===');
      print('Stack trace: ${e.toString()}');
      setState(() {
        _errorMessage = 'Gagal memuat riwayat transaksi: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDetailTransaksi(int idTransaksi) async {
    try {
      print('=== DEBUG: Loading Detail Transaksi ===');
      print('Loading details for transaction ID: $idTransaksi');
      final response = await _detailTransaksiApi.getDetailTransaksiByTransaksi(
        idTransaksi,
      );
      print('Detail transaksi response: $response');

      if (response != null) {
        List<DetailTransaksiModel> detailList = [];
        if (response is List) {
          print('Processing ${response.length} detail items');
          detailList =
              response
                  .map((item) {
                    print('Processing detail item: $item');
                    try {
                      return DetailTransaksiModel.fromJson(item);
                    } catch (e) {
                      print('Error parsing detail item: $e');
                      return null;
                    }
                  })
                  .whereType<DetailTransaksiModel>()
                  .toList();
        } else if (response is Map && response.containsKey('data')) {
          print('Processing details from data wrapper');
          detailList =
              (response['data'] as List)
                  .map((item) {
                    print('Processing detail from data: $item');
                    try {
                      return DetailTransaksiModel.fromJson(item);
                    } catch (e) {
                      print('Error parsing detail from data: $e');
                      return null;
                    }
                  })
                  .whereType<DetailTransaksiModel>()
                  .toList();
        }

        print('=== DEBUG: Detail Results ===');
        print('Number of details parsed: ${detailList.length}');
        for (var detail in detailList) {
          print('Detail ID: ${detail.idDetailTransaksi}');
          print('Barang ID: ${detail.idBarang}');
          print('Harga: ${detail.hargaItem}');
        }

        setState(() {
          _detailTransaksiMap[idTransaksi] = detailList;
        });
      }
    } catch (e) {
      print('=== DEBUG: Detail Error ===');
      print('Error memuat detail transaksi: ${e.toString()}');
      print('Stack trace: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Riwayat Transaksi',
        backgroundColor: Colors.green.shade600,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green.shade600,
                  ),
                ),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTransaksi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
              : _transaksiList.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _transaksiList.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final transaksi = _transaksiList[index];
                  return _buildTransaksiCard(transaksi);
                },
              ),
    );
  }

  Widget _buildTransaksiCard(TransaksiModel transaksi) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ID Transaksi: ${transaksi.idTransaksi}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildStatusBadge(transaksi.statusTransaksi),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tanggal: ${transaksi.tanggalFormatted}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Metode Pengiriman: ${transaksi.metodePengiriman ?? 'Ambil Sendiri'}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembayaran:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rp ${transaksi.totalHargaFormatted}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Detail items
          _detailTransaksiMap.containsKey(transaksi.idTransaksi)
              ? Column(
                children: [
                  const Divider(height: 1),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Produk',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Harga',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        _detailTransaksiMap[transaksi.idTransaksi]!.length,
                    itemBuilder: (context, index) {
                      final detail =
                          _detailTransaksiMap[transaksi.idTransaksi]![index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                detail.barang?.namaBarang ??
                                    'Produk #${detail.idBarang}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Rp ${detail.hargaItemFormatted}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              )
              : const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('Memuat detail transaksi...')),
              ),
          // Aksi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Implementasi untuk melihat detail lengkap
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Detail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Implementasi untuk menghubungi penjual
                  },
                  icon: const Icon(Icons.headset_mic),
                  label: const Text('Bantuan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (status.toLowerCase()) {
      case 'selesai':
        backgroundColor = Colors.green.shade600;
        break;
      case 'diproses':
        backgroundColor = Colors.blue.shade600;
        break;
      case 'dikirim':
        backgroundColor = Colors.orange.shade600;
        break;
      case 'dibatalkan':
        backgroundColor = Colors.red.shade600;
        break;
      case 'menunggu pembayaran':
        backgroundColor = Colors.amber.shade600;
        break;
      default:
        backgroundColor = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
