import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../api/komisi_pegawai_api.dart';
import '../../api/transaksi_api.dart';
import '../../api/detail_transaksi_api.dart';
import '../../api/barang_api.dart';
import '../../models/komisi_pegawai_model.dart';
import '../../models/detail_transaksi_model.dart';
import '../../models/barang_model.dart';

class KomisiDetailPage extends StatefulWidget {
  final int komisiId;

  const KomisiDetailPage({
    Key? key,
    required this.komisiId,
  }) : super(key: key);

  @override
  State<KomisiDetailPage> createState() => _KomisiDetailPageState();
}

class _KomisiDetailPageState extends State<KomisiDetailPage> {
  final KomisiPegawaiApi _komisiApi = KomisiPegawaiApi();
  final TransaksiApi _transaksiApi = TransaksiApi();
  final DetailTransaksiApi _detailTransaksiApi = DetailTransaksiApi();
  final BarangApi _barangApi = BarangApi();

  bool _isLoading = true;
  String? _errorMessage;
  KomisiPegawaiModel? _komisi;
  List<DetailTransaksiModel> _detailTransaksiList = [];
  BarangModel? _barang;

  @override
  void initState() {
    super.initState();
    _loadKomisiDetail();
  }

  Future<void> _loadKomisiDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load komisi data
      final komisi = await _komisiApi.getKomisiById(widget.komisiId);

      if (komisi == null) {
        setState(() {
          _errorMessage = 'Komisi tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _komisi = komisi;
      });

      // Load transaction details
      final detailList = await _detailTransaksiApi.getDetailTransaksiByTransaksi(komisi.idTransaksi);
      
      setState(() {
        _detailTransaksiList = detailList;
      });

      // If details found, get the first item's data
      if (detailList.isNotEmpty && detailList[0].barang != null) {
        setState(() {
          _barang = detailList[0].barang;
          _isLoading = false;
        });
      } else if (detailList.isNotEmpty) {
        // If barang not included in the response, load it separately
        final barang = await _barangApi.getBarangById(detailList[0].idBarang);
        if (barang != null) {
          BarangModel? barangModel;
          if (barang is Map) {
            if (barang.containsKey('data')) {
              barangModel = BarangModel.fromJson(barang['data'] as Map<String, dynamic>);
            } else {
              barangModel = BarangModel.fromJson(barang as Map<String, dynamic>);
            }
          }
          
          setState(() {
            _barang = barangModel;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Barang tidak ditemukan';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Detail transaksi tidak ditemukan';
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading komisi detail: $e');
      setState(() {
        _errorMessage = 'Gagal memuat detail komisi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Komisi'),
        backgroundColor: Colors.green.shade600,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
              ),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildDetailView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadKomisiDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    if (_komisi == null) {
      return const Center(child: Text('Data tidak tersedia'));
    }

    return RefreshIndicator(
      onRefresh: _loadKomisiDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKomisiInfoCard(),
              const SizedBox(height: 16),
              if (_barang != null) _buildBarangCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKomisiInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Komisi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow(
              'ID Komisi',
              '#${_komisi!.idKomisiPegawai}',
              Icons.tag,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'ID Transaksi',
              '#${_komisi!.idTransaksi}',
              Icons.receipt_long,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Jumlah Komisi',
              'Rp ${_formatRupiah(_komisi!.jumlahKomisi)}',
              Icons.monetization_on,
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarangCard() {
    final barang = _barang!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Barang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const Divider(),
            const SizedBox(height: 12),
            // Item name
            Text(
              barang.namaBarang,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Item price
            Row(
              children: [
                Icon(Icons.sell, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Harga: Rp ${_formatRupiah(barang.harga)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isHighlighted = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlighted ? Colors.green.shade700 : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.green.shade700 : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatRupiah(double price) {
    int priceInt = price.toInt();
    String priceStr = priceInt.toString();
    String result = '';
    int count = 0;

    for (int i = priceStr.length - 1; i >= 0; i--) {
      result = priceStr[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }

    return result;
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day/$month/$year';
    } catch (e) {
      return isoDate.substring(0, 10);
    }
  }

  // Function to check if warranty is still valid
  bool isWarrantyValid(String? warrantyDate) {
    if (warrantyDate == null || warrantyDate.isEmpty) {
      return false;
    }

    developer.log('Checking warranty date: $warrantyDate');

    try {
      DateTime? warrantyDateTime;

      // Try DD/MM/YYYY format first
      if (warrantyDate.contains('/')) {
        final parts = warrantyDate.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]) ?? 1;
          final month = int.tryParse(parts[1]) ?? 1;
          final year = int.tryParse(parts[2]) ?? 2000;
          warrantyDateTime = DateTime(year, month, day);
        }
      } 
      // Try YYYY-MM-DD format
      else if (warrantyDate.contains('-')) {
        try {
          warrantyDateTime = DateTime.parse(warrantyDate);
        } catch (e) {
          final parts = warrantyDate.split('-');
          if (parts.length == 3) {
            final year = int.tryParse(parts[0]) ?? 2000;
            final month = int.tryParse(parts[1]) ?? 1;
            final day = int.tryParse(parts[2]) ?? 1;
            warrantyDateTime = DateTime(year, month, day);
          }
        }
      }
      // Try to directly parse the date
      else {
        try {
          warrantyDateTime = DateTime.parse(warrantyDate);
        } catch (e) {
          // If all parsing attempts fail, try to extract numbers and assume it's a future date
          final RegExp regExp = RegExp(r'\d+');
          final matches = regExp.allMatches(warrantyDate);
          if (matches.isNotEmpty) {
            // If we find any numbers, assume it's a valid warranty
            return true;
          }
        }
      }
      
      if (warrantyDateTime != null) {
        final currentDate = DateTime.now();
        // Compare with current date
        final isValid = warrantyDateTime.isAfter(currentDate);
        developer.log('Warranty date: $warrantyDateTime, Current: $currentDate, Valid: $isValid');
        return isValid;
      }
      
      // If we couldn't parse the date but it's not empty, assume it's valid
      developer.log('Could not parse warranty date format: $warrantyDate - assuming valid');
      return true;
    } catch (e) {
      developer.log('Error parsing warranty date: $e');
      // If there's an error in parsing but the warranty string exists, assume it's valid
      return true;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Colors.green.shade100;
      case 'non-aktif':
        return Colors.grey.shade200;
      case 'terjual':
        return Colors.blue.shade100;
      case 'barang untuk donasi':
        return Colors.amber.shade100;
      case 'habis':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Colors.green.shade800;
      case 'non-aktif':
        return Colors.grey.shade800;
      case 'terjual':
        return Colors.blue.shade800;
      case 'barang untuk donasi':
        return Colors.amber.shade800;
      case 'habis':
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
} 