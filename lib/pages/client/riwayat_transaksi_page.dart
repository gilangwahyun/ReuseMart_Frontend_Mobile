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
      if (userData == null) {
        setState(() {
          _errorMessage = 'Anda perlu login terlebih dahulu';
          _isLoading = false;
        });
        return;
      }

      // Mendapatkan id_pembeli dari user
      final idPembeli = userData['id_pembeli'];
      if (idPembeli == null) {
        setState(() {
          _errorMessage = 'Data pembeli tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      // Mendapatkan daftar transaksi dari API
      final response = await _transaksiApi.getTransaksiByPembeli(idPembeli);

      if (response != null) {
        // Parse daftar transaksi
        List<TransaksiModel> transaksiList = [];
        if (response is List) {
          transaksiList =
              response.map((item) => TransaksiModel.fromJson(item)).toList();
        } else if (response is Map && response.containsKey('data')) {
          transaksiList =
              (response['data'] as List)
                  .map((item) => TransaksiModel.fromJson(item))
                  .toList();
        }

        setState(() {
          _transaksiList = transaksiList;
        });

        // Ambil detail untuk setiap transaksi
        for (var transaksi in _transaksiList) {
          await _loadDetailTransaksi(transaksi.idTransaksi);
        }
      }
    } catch (e) {
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
      final response = await _detailTransaksiApi.getDetailTransaksiByTransaksi(
        idTransaksi,
      );

      if (response != null) {
        List<DetailTransaksiModel> detailList = [];
        if (response is List) {
          detailList =
              response
                  .map((item) => DetailTransaksiModel.fromJson(item))
                  .toList();
        } else if (response is Map && response.containsKey('data')) {
          detailList =
              (response['data'] as List)
                  .map((item) => DetailTransaksiModel.fromJson(item))
                  .toList();
        }

        setState(() {
          _detailTransaksiMap[idTransaksi] = detailList;
        });
      }
    } catch (e) {
      print('Error memuat detail transaksi: ${e.toString()}');
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
