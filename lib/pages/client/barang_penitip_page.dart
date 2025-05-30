import 'package:flutter/material.dart';
import '../../api/penitipan_barang_api.dart';
import '../../api/penitip_api.dart';
import '../../models/penitipan_barang_model.dart';
import '../../models/barang_model.dart';
import '../../models/user_profile_model.dart';
import '../../utils/local_storage.dart';

class BarangPenitipPage extends StatefulWidget {
  const BarangPenitipPage({super.key});

  @override
  State<BarangPenitipPage> createState() => _BarangPenitipPageState();
}

class _BarangPenitipPageState extends State<BarangPenitipPage> {
  final PenitipanBarangApi _penitipanApi = PenitipanBarangApi();
  final PenitipApi _penitipApi = PenitipApi();
  List<PenitipanBarangModel> _penitipanList = [];
  bool _isLoading = true;
  String? _errorMessage;
  UserProfileModel? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final profile = await LocalStorage.getProfile();
      final userData = await LocalStorage.getUser();

      print("Mencoba mendapatkan data penitip untuk tampilan barang...");

      if (userData != null) {
        try {
          // Coba dapatkan data penitip berdasarkan ID user
          print(
            "Menggunakan ID user ${userData.idUser} untuk mendapatkan data penitip",
          );
          final penitipResponse = await _penitipApi.getPenitipByUserId(
            userData.idUser,
          );

          if (penitipResponse != null && penitipResponse['success']) {
            final penitipData = penitipResponse['data'];
            final idPenitip = penitipData['id_penitip'];

            print('ID penitip ditemukan melalui user ID: $idPenitip');

            // Simpan ID penitip ke storage untuk penggunaan berikutnya
            await LocalStorage.saveData('id_penitip', idPenitip.toString());

            await _loadPenitipanData(idPenitip);
            return;
          } else {
            print(
              'API merespons tanpa data penitip yang valid: $penitipResponse',
            );
          }
        } catch (e) {
          print('Error mendapatkan data penitip dari ID user: $e');
        }
      } else {
        print('Data user tidak ditemukan di local storage');
      }

      // Fallback: Coba dari profile local jika mendapatkan dari user ID gagal
      if (profile != null && profile.penitip != null) {
        print(
          'Menggunakan data penitip dari profil lokal: ID ${profile.penitip!.idPenitip}',
        );
        setState(() {
          _userProfile = profile;
        });
        await _loadPenitipanData(profile.penitip!.idPenitip);
      } else {
        print('Data penitip tidak ditemukan di profil lokal');

        // Cek apakah ada ID penitip tersimpan di local storage
        final idPenitip = await LocalStorage.getPenitipId();
        if (idPenitip != null) {
          print('Menggunakan ID penitip dari local storage: $idPenitip');
          await _loadPenitipanData(idPenitip);
          return;
        }

        setState(() {
          _errorMessage = 'Data profil penitip tidak ditemukan';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fatal saat memuat data profil: $e');
      setState(() {
        _errorMessage = 'Gagal memuat data profil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPenitipanData(int idPenitip) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _penitipanApi.getPenitipanBarangByIdPenitip(
        idPenitip,
      );

      if (response is List) {
        final penitipanList =
            response
                .map((item) => PenitipanBarangModel.fromJson(item))
                .toList();

        // Urutkan penitipan berdasarkan tanggal terbaru
        penitipanList.sort(
          (a, b) => b.tanggalAwalPenitipan.compareTo(a.tanggalAwalPenitipan),
        );

        setState(() {
          _penitipanList = penitipanList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _penitipanList = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data penitipan barang: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Penitipan Saya'),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          if (_userProfile?.penitip != null) {
                            _loadPenitipanData(
                              _userProfile!.penitip!.idPenitip,
                            );
                          } else {
                            _loadUserProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
              : _penitipanList.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada barang yang dititipkan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Anda belum menitipkan barang di ReuseMart',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  if (_userProfile?.penitip != null) {
                    await _loadPenitipanData(_userProfile!.penitip!.idPenitip);
                  }
                },
                color: Colors.green.shade700,
                child: ListView.builder(
                  itemCount: _penitipanList.length,
                  itemBuilder: (context, index) {
                    final penitipan = _penitipanList[index];
                    return _buildPenitipanCard(penitipan);
                  },
                ),
              ),
    );
  }

  Widget _buildPenitipanCard(PenitipanBarangModel penitipan) {
    // Format tanggal untuk tampilan
    String tglAwal = _formatDate(penitipan.tanggalAwalPenitipan);
    String tglAkhir = _formatDate(penitipan.tanggalAkhirPenitipan);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Periode Penitipan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range,
                    size: 18,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Periode: $tglAwal - $tglAkhir',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail pegawai QC
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  'Petugas QC: ${penitipan.namaPetugasQc}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Nomor Penitipan
            Row(
              children: [
                Icon(Icons.numbers, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  'ID Penitipan: ${penitipan.idPenitipan}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.grey.shade300, height: 1),
            ),

            // Label barang
            const Text(
              'Daftar Barang:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Daftar barang
            if (penitipan.barang == null || penitipan.barang!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  'Tidak ada data barang',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: penitipan.barang!.length,
                itemBuilder:
                    (context, idx) => _buildBarangItem(penitipan.barang![idx]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarangItem(BarangModel barang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              barang.gambarUtama.isNotEmpty
                  ? Image.network(
                    barang.gambarUtama,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildNoImage(),
                  )
                  : _buildNoImage(),
        ),
        title: Text(
          barang.namaBarang,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Rp ${_formatRupiah(barang.harga)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(barang.statusBarang),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    barang.statusBarang,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusTextColor(barang.statusBarang),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (barang.kategori != null)
                  Text(
                    barang.kategori!.namaKategori,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
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

  String _formatRupiah(double price) {
    int priceInt = price.toInt(); // Konversi ke int
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
      default:
        return Colors.grey.shade800;
    }
  }
}
