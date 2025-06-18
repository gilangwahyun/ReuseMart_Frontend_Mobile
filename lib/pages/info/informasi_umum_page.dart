import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class InformasiUmumPage extends StatefulWidget {
  const InformasiUmumPage({super.key});

  @override
  State<InformasiUmumPage> createState() => _InformasiUmumPageState();
}

class _InformasiUmumPageState extends State<InformasiUmumPage> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {'title': 'Beranda', 'icon': Icons.home},
    {'title': 'Cara Kerja', 'icon': Icons.help_outline},
    {'title': 'Tentang Kami', 'icon': Icons.info_outline},
    {'title': 'FAQ', 'icon': Icons.question_answer},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selectedIndex]['title']),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              AppRoutes.navigateTo(context, AppRoutes.login);
            },
            child: const Text(
              'Masuk',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildHomeTab(),
          _buildHowItWorksTab(),
          _buildAboutUsTab(),
          _buildFAQTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green.shade600,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        items:
            _pages
                .map(
                  (page) => BottomNavigationBarItem(
                    icon: Icon(page['icon']),
                    label: page['title'],
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Utama
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.green.shade400, Colors.green.shade700],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.recycling,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Selamat Datang di ReuseMart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Platform Konsinyasi Barang Bekas',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Apa itu ReuseMart?
          _buildSection(
            title: 'Apa itu ReuseMart?',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ReuseMart adalah platform konsinyasi barang bekas yang mengelola penjualan barang bekas melalui sistem penitipan. Anda cukup datang ke gudang kami, dan kami akan menangani seluruh proses penjualan hingga Anda mendapatkan hasil penjualan.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.money,
                        title: 'Untung Lebih',
                        description:
                            'Dapatkan hasil optimal dari barang bekas Anda',
                        color: Colors.green.shade100,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.speed,
                        title: 'Proses Cepat',
                        description:
                            'Penitipan langsung di gudang dan proses QC transparan',
                        color: Colors.blue.shade100,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.eco,
                        title: 'Ramah Lingkungan',
                        description:
                            'Barang yang tidak terjual dapat didonasikan dengan poin reward',
                        color: Colors.amber.shade100,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.verified_user,
                        title: 'Fleksibel',
                        description:
                            'Masa penitipan 30 hari dengan opsi perpanjangan',
                        color: Colors.purple.shade100,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call to Action
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  'Siap untuk bergabung dengan ReuseMart?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Daftar sekarang dan mulai jual atau beli barang bekas dengan mudah',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    AppRoutes.navigateTo(context, AppRoutes.login);
                  },
                  child: const Text('Masuk Sekarang'),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.grey.shade100,
            child: const Center(
              child: Text(
                '© 2023 ReuseMart. Semua hak dilindungi.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bagaimana ReuseMart Bekerja?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Untuk Penitip
          const Text(
            'Alur Proses Penitipan Barang',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildStepCard(
            number: 1,
            title: 'Datang ke Gudang ReuseMart',
            description:
                'Kunjungi gudang ReuseMart untuk membawa barang bekas Anda yang ingin dititipkan.',
            icon: Icons.location_on,
          ),
          _buildStepCard(
            number: 2,
            title: 'Quality Control',
            description:
                'Barang Anda akan diperiksa kualitasnya oleh petugas gudang ReuseMart.',
            icon: Icons.verified,
          ),
          _buildStepCard(
            number: 3,
            title: 'Pembuatan Akun oleh CS',
            description:
                'Customer Service akan membuatkan akun penitip untuk Anda jika belum memilikinya.',
            icon: Icons.person_add,
          ),
          _buildStepCard(
            number: 4,
            title: 'Proses Manajerial',
            description:
                'Tim manajerial akan menginput informasi barang dan menentukan detail penitipan.',
            icon: Icons.admin_panel_settings,
          ),
          _buildStepCard(
            number: 5,
            title: 'Masa Penitipan 30 Hari',
            description:
                'Barang Anda akan dititipkan selama 30 hari untuk dijual di platform ReuseMart.',
            icon: Icons.calendar_today,
          ),
          _buildStepCard(
            number: 6,
            title: 'Opsi Perpanjangan',
            description:
                'Setelah 30 hari, Anda memiliki waktu 7 hari untuk memutuskan memperpanjang masa penitipan atau mengambil barang kembali. Perpanjangan hanya bisa dilakukan sekali.',
            icon: Icons.update,
          ),
          _buildStepCard(
            number: 7,
            title: 'Pengalihan Hak Barang',
            description:
                'Jika tidak ada konfirmasi dalam 7 hari, barang masuk list kategori dan owner berhak mengalokasikan untuk donasi. Anda tetap mendapatkan poin reward donasi.',
            icon: Icons.card_giftcard,
          ),

          const SizedBox(height: 32),

          // Untuk Pembeli
          const Text(
            'Untuk Pembeli',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildStepCard(
            number: 1,
            title: 'Browse Produk',
            description:
                'Jelajahi berbagai produk bekas berkualitas di aplikasi ReuseMart.',
            icon: Icons.search,
          ),
          _buildStepCard(
            number: 2,
            title: 'Pilih & Beli',
            description:
                'Pilih produk yang Anda inginkan dan lakukan pembelian dengan mudah.',
            icon: Icons.shopping_cart,
          ),
          _buildStepCard(
            number: 3,
            title: 'Proses Pembayaran',
            description:
                'Lakukan pembayaran melalui transfer bank untuk kemudahan.',
            icon: Icons.credit_card,
          ),
          _buildStepCard(
            number: 4,
            title: 'Terima Barang',
            description:
                'Barang akan dikirimkan ke alamat Anda oleh kurir ReuseMart.',
            icon: Icons.local_shipping,
          ),

          const SizedBox(height: 32),

          // Diagram Masa Penitipan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masa Penitipan Barang',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 8, color: Colors.green.shade400),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: Container(height: 8, color: Colors.amber.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '30 Hari\nMasa Penitipan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '7 Hari\nMasa Keputusan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '• Perpanjangan masa penitipan hanya dapat dilakukan 1 kali untuk 30 hari berikutnya',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Barang tanpa keputusan setelah 7 hari akan dialokasikan untuk donasi',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                AppRoutes.navigateTo(context, AppRoutes.login);
              },
              child: const Text('Mulai Sekarang'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutUsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentang ReuseMart',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.grey.shade300,
              height: 200,
              width: double.infinity,
              child: const Center(
                child: Icon(Icons.image, size: 60, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Visi Kami',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Menjadi platform konsinyasi terkemuka yang mendorong ekonomi sirkular dan mengurangi dampak lingkungan melalui jual-beli barang bekas yang berkualitas.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          const Text(
            'Misi Kami',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildMissionItem(
            'Menyediakan platform yang aman dan terpercaya untuk jual-beli barang bekas.',
          ),
          _buildMissionItem(
            'Membantu penitip mendapatkan nilai maksimal dari barang bekas mereka.',
          ),
          _buildMissionItem(
            'Menawarkan produk berkualitas dengan harga terjangkau untuk pembeli.',
          ),
          _buildMissionItem(
            'Berkontribusi pada upaya pengurangan sampah dan pemanfaatan kembali produk.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Nilai-Nilai Kami',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildValueCard(
                  icon: Icons.verified,
                  title: 'Kepercayaan',
                  color: Colors.blue.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildValueCard(
                  icon: Icons.eco,
                  title: 'Keberlanjutan',
                  color: Colors.green.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildValueCard(
                  icon: Icons.handshake,
                  title: 'Kerjasama',
                  color: Colors.purple.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildValueCard(
                  icon: Icons.recycling,
                  title: 'Inovasi',
                  color: Colors.amber.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hubungi Kami',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildContactItem(Icons.email, 'info@reusemart.com'),
                const SizedBox(height: 8),
                _buildContactItem(Icons.phone, '+62 812 3456 7890'),
                const SizedBox(height: 8),
                _buildContactItem(
                  Icons.location_on,
                  'Jl. Green Eco Park No. 456 Yogyakarta',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pertanyaan yang Sering Diajukan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFaqItem(
            question: 'Apa itu ReuseMart?',
            answer:
                'ReuseMart adalah platform konsinyasi barang bekas yang menghubungkan penitip barang dengan calon pembeli. Kami membantu penitip menjual barang bekas mereka dengan mudah dan menguntungkan.',
          ),
          _buildFaqItem(
            question: 'Bagaimana cara menitipkan barang?',
            answer:
                'Untuk menitipkan barang, Anda perlu datang langsung ke gudang ReuseMart dengan membawa barang yang ingin dititipkan. Petugas gudang akan melakukan pemeriksaan kualitas, dan Customer Service kami akan membuatkan akun penitip untuk Anda. Selanjutnya, barang akan diproses oleh tim manajerial untuk diinputkan informasinya dan dijual melalui platform kami.',
          ),
          _buildFaqItem(
            question: 'Berapa lama masa penitipan barang?',
            answer:
                'Masa penitipan awal adalah 30 hari. Setelah itu, Anda memiliki waktu 7 hari untuk memutuskan apakah ingin memperpanjang masa penitipan selama 30 hari lagi atau mengambil barang kembali. Perpanjangan hanya dapat dilakukan satu kali. Jika tidak ada konfirmasi dalam 7 hari tersebut, barang akan masuk ke list kategori dan hak alokasi untuk donasi menjadi milik owner. Penitip tetap mendapatkan poin reward donasi.',
          ),
          _buildFaqItem(
            question: 'Berapa komisi yang diambil ReuseMart?',
            answer:
                'ReuseMart mengambil komisi sebesar 15-20% dari harga jual, tergantung pada kategori dan kondisi barang. Komisi ini digunakan untuk biaya operasional, penyimpanan, pemasaran, dan proses penjualan.',
          ),
          _buildFaqItem(
            question: 'Kapan saya akan menerima pembayaran?',
            answer:
                'Setelah barang terjual, pembayaran akan segera di proses di hari kerja dan ditransfer ke rekening bank yang telah Anda daftarkan.',
          ),
          _buildFaqItem(
            question: 'Apakah ada jaminan barang akan terjual?',
            answer:
                'Kami tidak dapat menjamin bahwa semua barang akan terjual, tetapi kami akan berusaha memasarkan barang Anda dengan optimal. Jika masa penitipan berakhir dan barang belum terjual, Anda dapat memperpanjang masa penitipan atau mengambil barang kembali.',
          ),
          _buildFaqItem(
            question: 'Bagaimana dengan kondisi dan kualitas barang?',
            answer:
                'Semua barang yang diterima akan melalui proses pemeriksaan kualitas oleh petugas gudang kami. Kami hanya menerima barang bekas dengan kondisi yang masih layak jual. Kondisi barang akan dicantumkan dengan jelas pada deskripsi produk.',
          ),
          _buildFaqItem(
            question:
                'Apa yang terjadi jika saya tidak mengambil keputusan setelah masa penitipan berakhir?',
            answer:
                'Jika tidak ada konfirmasi dalam 7 hari setelah masa penitipan 30 hari berakhir, barang akan masuk ke list kategori dan hak alokasi untuk donasi menjadi milik owner ReuseMart. Sebagai penitip, Anda tetap akan mendapatkan poin reward donasi yang dapat ditukarkan dengan berbagai hadiah menarik.',
          ),
          _buildFaqItem(
            question:
                'Apakah ReuseMart melayani pengiriman ke seluruh Indonesia?',
            answer: 'Untuk saat ini ReuseMart hanya beroperasi di Yogyakarta.',
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children: [
                const Text(
                  'Pertanyaan lainnya?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan hubungi tim layanan pelanggan kami melalui:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildContactButton(
                      icon: Icons.email,
                      label: 'Email',
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _buildContactButton(
                      icon: Icons.chat,
                      label: 'Chat',
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _buildContactButton(
                      icon: Icons.phone,
                      label: 'Telepon',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade800),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(icon, size: 32, color: Colors.green.shade300),
        ],
      ),
    );
  }

  Widget _buildMissionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade800),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green.shade600),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue.shade700),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
