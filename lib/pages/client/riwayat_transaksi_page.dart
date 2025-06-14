import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/transaksi_api.dart';
import '../../api/detail_transaksi_api.dart';
import '../../api/foto_barang_api.dart';
import '../../api/api_service.dart';
import '../../models/transaksi_model.dart';
import '../../models/detail_transaksi_model.dart';
import '../../models/foto_barang_model.dart';
import '../../utils/local_storage.dart';
import '../../models/barang_model.dart';

class RiwayatTransaksiPage extends StatefulWidget {
  const RiwayatTransaksiPage({super.key});

  @override
  State<RiwayatTransaksiPage> createState() => _RiwayatTransaksiPageState();
}

class _RiwayatTransaksiPageState extends State<RiwayatTransaksiPage> {
  final TransaksiApi _transaksiApi = TransaksiApi();
  final DetailTransaksiApi _detailTransaksiApi = DetailTransaksiApi();
  final FotoBarangApi _fotoBarangApi = FotoBarangApi();
  final ApiService _apiService = ApiService();

  List<TransaksiModel> _transaksiList = [];
  List<TransaksiModel> _filteredTransaksiList = [];
  Map<int, List<DetailTransaksiModel>> _detailTransaksiMap = {};
  Map<int, bool> _expandedMap = {}; // Track expanded state for each transaction
  Map<int, FotoBarangModel?> _thumbnails =
      {}; // Menyimpan thumbnail untuk setiap barang

  bool _isLoading = true;
  String? _errorMessage;

  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _filterTransactions() {
    if (_startDate == null || _endDate == null) {
      setState(() {
        _filteredTransaksiList = List.from(_transaksiList);
      });
      return;
    }

    // Set time to start of day for start date and end of day for end date
    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      23,
      59,
      59,
    );

    setState(() {
      _filteredTransaksiList =
          _transaksiList.where((transaksi) {
            final transaksiDate = DateTime.parse(transaksi.tanggalTransaksi);
            return transaksiDate.isAfter(startDateTime) &&
                transaksiDate.isBefore(endDateTime);
          }).toList();
    });
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = _formatDate(picked);
          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
            _endDateController.text = '';
          }
        } else {
          if (_startDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pilih tanggal mulai terlebih dahulu'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          if (picked.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tanggal selesai harus setelah tanggal mulai'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          _endDate = picked;
          _endDateController.text = _formatDate(picked);
        }
        _filterTransactions();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _clearDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _startDateController.text = '';
      _endDateController.text = '';
      _filterTransactions();
    });
  }

  Future<void> _loadTransaksi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Coba dapatkan id_pembeli langsung dari local storage
      final idPembeli = await LocalStorage.getPembeliId();
      print('=== DEBUG: User Data ===');
      print('ID Pembeli from local storage: $idPembeli');

      if (idPembeli == null) {
        // Jika tidak ada di local storage, coba ambil dari user data
        final userData = await LocalStorage.getUserMap();
        print('User data from local storage: $userData');

        if (userData == null || userData['id_pembeli'] == null) {
          setState(() {
            _errorMessage = 'Data pembeli tidak ditemukan';
            _isLoading = false;
          });
          return;
        }

        // Simpan id_pembeli ke local storage untuk penggunaan berikutnya
        final int idPembeliFromUser =
            int.tryParse(userData['id_pembeli'].toString()) ?? 0;
        if (idPembeliFromUser > 0) {
          await LocalStorage.savePembeliId(idPembeliFromUser);
          print('ID Pembeli berhasil disimpan: $idPembeliFromUser');
        }
      }

      final int idPembeliInt = idPembeli ?? 0;
      print('ID Pembeli yang akan digunakan: $idPembeliInt');

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

      List<dynamic> transaksiData;

      // Handle response in new format (with success, message, data)
      if (response is Map<String, dynamic>) {
        print('Response is in Map format');
        if (response['success'] == true) {
          transaksiData = response['data'] ?? [];
        } else {
          print('API indicates failure: ${response['message']}');
          setState(() {
            _errorMessage =
                response['message'] ?? 'Gagal memuat data transaksi';
          });
          return;
        }
      }
      // Handle response in direct array format
      else if (response is List) {
        print('Response is in direct List format');
        transaksiData = response;
      } else {
        print('Unexpected response format: ${response.runtimeType}');
        setState(() {
          _errorMessage = 'Format response tidak valid';
        });
        return;
      }

      print('Processing ${transaksiData.length} transactions');

      List<TransaksiModel> transaksiList =
          transaksiData
              .map((item) {
                print('Processing transaction item: $item');
                try {
                  return TransaksiModel.fromJson(item);
                } catch (e) {
                  print('Error parsing transaction: $e');
                  return null;
                }
              })
              .whereType<TransaksiModel>()
              .toList();

      print('=== DEBUG: Parsed Results ===');
      print('Number of transactions parsed: ${transaksiList.length}');
      for (var transaksi in transaksiList) {
        print('Transaksi ID: ${transaksi.idTransaksi}');
        print('Status: ${transaksi.statusTransaksi}');
        print('Tanggal: ${transaksi.tanggalTransaksi}');
      }

      setState(() {
        _transaksiList = transaksiList;
        _filterTransactions();
      });

      // Initialize expanded state for each transaction
      for (var transaksi in _transaksiList) {
        _expandedMap[transaksi.idTransaksi] = false;
      }

      // Ambil detail untuk setiap transaksi
      for (var transaksi in _transaksiList) {
        print('Fetching details for transaction ${transaksi.idTransaksi}');
        await _loadDetailTransaksi(transaksi.idTransaksi);
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

  // Fungsi untuk mengambil thumbnail foto
  Future<void> _fetchThumbnailFoto(int idBarang) async {
    try {
      final fotos = await _fotoBarangApi.getFotoBarangByIdBarang(idBarang);

      if (fotos.isNotEmpty) {
        // Pilih foto dengan is_thumbnail === true
        final thumbnail = fotos.firstWhere(
          (f) => f.isThumbnail,
          orElse: () {
            // Fallback ke foto pertama (id_foto_barang terkecil)
            final sortedFotos = List.from(fotos)
              ..sort((a, b) => a.idFotoBarang.compareTo(b.idFotoBarang));
            return sortedFotos.first;
          },
        );

        setState(() {
          _thumbnails[idBarang] = thumbnail;
        });
      }
    } catch (e) {
      print('Error fetching foto barang: $e');
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
      print('Response type: ${response?.runtimeType}');

      List<dynamic> detailData;

      // Handle response in new format (with success, message, data)
      if (response is Map<String, dynamic>) {
        print('Response is Map format');
        if (response['success'] == true) {
          detailData = response['data'] ?? [];
          print('Success: true, found ${detailData.length} details');

          // Debug data barang
          for (var item in detailData) {
            print('\n=== DEBUG: Detail Item ===');
            print('Item: $item');
            if (item['barang'] != null) {
              print('Barang data: ${item['barang']}');
              if (item['barang']['penitipan_barang'] != null) {
                print('Penitipan data: ${item['barang']['penitipan_barang']}');
                if (item['barang']['penitipan_barang']['penitip'] != null) {
                  print(
                    'Penitip data: ${item['barang']['penitipan_barang']['penitip']}',
                  );
                }
              }
            }
          }
        } else {
          print('Success: false, message: ${response['message']}');
          return;
        }
      }
      // Handle response in direct array format
      else if (response is List) {
        print('Response is direct List format');
        detailData = response;
        print('Found ${detailData.length} details');

        // Debug data barang untuk format list langsung
        for (var item in detailData) {
          print('\n=== DEBUG: Detail Item (List Format) ===');
          print('Item: $item');
          if (item['barang'] != null) {
            print('Barang data: ${item['barang']}');
            if (item['barang']['penitipan_barang'] != null) {
              print('Penitipan data: ${item['barang']['penitipan_barang']}');
              if (item['barang']['penitipan_barang']['penitip'] != null) {
                print(
                  'Penitip data: ${item['barang']['penitipan_barang']['penitip']}',
                );
              }
            }
          }
        }
      } else {
        print('Unexpected response format: ${response.runtimeType}');
        return;
      }

      List<DetailTransaksiModel> detailList =
          detailData
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

      print('Successfully parsed ${detailList.length} detail items');

      // Debug parsed models
      for (var detail in detailList) {
        print('\n=== DEBUG: Parsed Detail ===');
        print('Detail ID: ${detail.idDetailTransaksi}');
        print('Barang: ${detail.barang?.namaBarang}');
        print('Penitipan: ${detail.barang?.penitipanBarang?.idPenitipan}');
        print(
          'Penitip: ${detail.barang?.penitipanBarang?.penitip?.namaPenitip}',
        );
      }

      setState(() {
        _detailTransaksiMap[idTransaksi] = detailList;
      });

      // Fetch thumbnails untuk setiap barang dalam detail transaksi
      for (var detail in detailList) {
        if (detail.barang != null) {
          await _fetchThumbnailFoto(detail.barang!.idBarang);
        }
      }
    } catch (e) {
      print('Error loading detail transaksi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date Filter Section with new design
          Container(
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        color: Colors.green.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filter Periode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tanggal Mulai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _startDateController.text.isEmpty
                                          ? 'Pilih Tanggal'
                                          : _startDateController.text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            _startDateController.text.isEmpty
                                                ? Colors.grey.shade500
                                                : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tanggal Selesai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _endDateController.text.isEmpty
                                          ? 'Pilih Tanggal'
                                          : _endDateController.text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            _endDateController.text.isEmpty
                                                ? Colors.grey.shade500
                                                : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_startDate != null || _endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _clearDates,
                            icon: Icon(
                              Icons.clear,
                              size: 18,
                              color: Colors.red.shade600,
                            ),
                            label: Text(
                              'Reset Filter',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Transaction List with new design
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade600,
                        ),
                      ),
                    )
                    : _filteredTransaksiList.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _startDate != null
                                ? 'Tidak ada transaksi dalam\nrentang tanggal ini'
                                : 'Belum ada transaksi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_startDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TextButton.icon(
                                onPressed: _clearDates,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tampilkan Semua'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadTransaksi,
                      color: Colors.green.shade600,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredTransaksiList.length,
                        itemBuilder: (context, index) {
                          final transaksi = _filteredTransaksiList[index];
                          return _buildTransactionCard(transaksi);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransaksiModel transaksi) {
    final isExpanded = _expandedMap[transaksi.idTransaksi] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section
          InkWell(
            onTap: () {
              setState(() {
                _expandedMap[transaksi.idTransaksi] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.receipt_outlined,
                          color: Colors.green.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaksi #${transaksi.idTransaksi}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              transaksi.tanggalFormatted,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(transaksi.statusTransaksi),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              transaksi.statusTransaksi,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getStatusTextColor(
                                  transaksi.statusTransaksi,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rp ${transaksi.totalHargaFormatted}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isExpanded ? 'Sembunyikan Detail' : 'Lihat Detail',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable detail section
          if (isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  Container(height: 1, color: Colors.grey.shade200),
                  _detailTransaksiMap.containsKey(transaksi.idTransaksi)
                      ? ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            _detailTransaksiMap[transaksi.idTransaksi]!.length,
                        separatorBuilder:
                            (context, index) => Container(
                              height: 1,
                              color: Colors.grey.shade100,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                        itemBuilder: (context, index) {
                          final detail =
                              _detailTransaksiMap[transaksi
                                  .idTransaksi]![index];
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail image
                                if (detail.barang != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        _thumbnails[detail.barang!.idBarang] !=
                                                null
                                            ? CachedNetworkImage(
                                              imageUrl: _apiService.getImageUrl(
                                                _thumbnails[detail
                                                        .barang!
                                                        .idBarang]!
                                                    .urlFoto,
                                              ),
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              placeholder:
                                                  (context, url) => Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey.shade200,
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors
                                                                    .green
                                                                    .shade600,
                                                          ),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey.shade200,
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                  ),
                                            )
                                            : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                  ),
                                const SizedBox(width: 12),
                                // Item details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detail.barang?.namaBarang ??
                                            'Produk #${detail.idBarang}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (detail.barang?.kategori != null)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.category_outlined,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              detail
                                                  .barang!
                                                  .kategori!
                                                  .namaKategori,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (detail
                                              .barang
                                              ?.penitipanBarang
                                              ?.penitip !=
                                          null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.person_outline,
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Penitip: ${detail.barang!.penitipanBarang!.penitip!.namaPenitip}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (detail.barang?.deskripsi != null &&
                                          detail.barang!.deskripsi.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.description_outlined,
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  detail.barang!.deskripsi,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rp ${detail.hargaItemFormatted}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (detail.barang?.rating != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              detail.barang!.rating > 0
                                                  ? Colors.amber.shade50
                                                  : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              detail.barang!.rating > 0
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              size: 14,
                                              color:
                                                  detail.barang!.rating > 0
                                                      ? Colors.amber.shade600
                                                      : Colors.grey.shade400,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              detail.barang!.rating > 0
                                                  ? '${detail.barang!.rating}'
                                                  : 'Belum Dirating',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    detail.barang!.rating > 0
                                                        ? Colors.amber.shade800
                                                        : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      )
                      : const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green.shade100;
      case 'menunggu pembayaran':
        return Colors.orange.shade100;
      case 'dibatalkan':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green.shade800;
      case 'menunggu pembayaran':
        return Colors.orange.shade800;
      case 'dibatalkan':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
}
