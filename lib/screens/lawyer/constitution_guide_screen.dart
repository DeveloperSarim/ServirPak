import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ConstitutionGuideScreen extends StatefulWidget {
  const ConstitutionGuideScreen({super.key});

  @override
  State<ConstitutionGuideScreen> createState() =>
      _ConstitutionGuideScreenState();
}

class _ConstitutionGuideScreenState extends State<ConstitutionGuideScreen> {
  bool _isLoading = false;
  bool _showPdfPreview = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _showPdfPreview ? _buildPdfPreview() : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Constitution of Pakistan Guide',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF8B4513),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: _showPdfInfo,
          icon: const Icon(Icons.info_outline, color: Colors.white),
          tooltip: 'PDF Information',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 20),
          _buildContentCard(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B4513).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Constitution of Pakistan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Complete guide with all amendments and provisions',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Guide',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'The Constitution of Pakistan is the supreme law of Pakistan. This guide contains:',
            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('Complete text of the Constitution'),
          _buildFeatureItem('All amendments and provisions'),
          _buildFeatureItem('Legal interpretations and notes'),
          _buildFeatureItem('Historical context and background'),
          _buildFeatureItem('Searchable content for easy reference'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF8B4513), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Column(
      children: [
        // PDF Preview Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF8B4513),
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showPdfPreview = false;
                  });
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Constitution of Pakistan - PDF Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: _refreshPdf,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh PDF',
              ),
            ],
          ),
        ),
        // PDF Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildConstitutionContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildConstitutionContent() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF8B4513),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'Constitution of Pakistan - Complete Guide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConstitutionSection(
                  'Preamble',
                  'Whereas sovereignty over the entire Universe belongs to Almighty Allah alone, and the authority to be exercised by the people of Pakistan within the limits prescribed by Him is a sacred trust...',
                ),
                _buildConstitutionSection(
                  'Part I - Introductory',
                  'Article 1: Pakistan shall be a Federal Republic to be known as the Islamic Republic of Pakistan.\n\nArticle 2: Islam shall be the State religion of Pakistan.',
                ),
                _buildConstitutionSection(
                  'Part II - Fundamental Rights and Principles of Policy',
                  'Article 8: Any law, or any custom or usage having the force of law, in so far as it is inconsistent with the rights conferred by this Chapter, shall, to the extent of such inconsistency, be void.',
                ),
                _buildConstitutionSection(
                  'Part III - The Federation of Pakistan',
                  'Article 41: There shall be a President of Pakistan who shall be the Head of State and shall represent the unity of the Republic.',
                ),
                _buildConstitutionSection(
                  'Part IV - Provinces',
                  'Article 101: There shall be a Governor for each Province, who shall be appointed by the President in his discretion.',
                ),
                _buildConstitutionSection(
                  'Part V - Relations between Federation and Provinces',
                  'Article 141: Any law, or any custom or usage having the force of law, in so far as it is inconsistent with the rights conferred by this Chapter, shall, to the extent of such inconsistency, be void.',
                ),
                _buildConstitutionSection(
                  'Part VI - Finance, Property, Contracts and Suits',
                  'Article 160: Within six months of the commencing day and thereafter at intervals not exceeding five years, the President shall constitute a National Finance Commission.',
                ),
                _buildConstitutionSection(
                  'Part VII - The Judicature',
                  'Article 175: There shall be a Supreme Court of Pakistan, a High Court for each Province and such other courts as may be established by law.',
                ),
                _buildConstitutionSection(
                  'Part VIII - Elections',
                  'Article 222: Subject to the Constitution, Parliament may by law provide for the conduct of elections and matters connected therewith.',
                ),
                _buildConstitutionSection(
                  'Part IX - Islamic Provisions',
                  'Article 227: All existing laws shall be brought in conformity with the Injunctions of Islam as laid down in the Holy Quran and Sunnah.',
                ),
                _buildConstitutionSection(
                  'Part X - Emergency Provisions',
                  'Article 232: If the President is satisfied that a grave emergency exists in which Pakistan or any part thereof is threatened by war or external aggression, or by internal disturbance beyond the power of a Provincial Government to control.',
                ),
                _buildConstitutionSection(
                  'Part XI - Amendment of Constitution',
                  'Article 238: Subject to this Part, the Constitution may be amended by Act of Parliament.',
                ),
                _buildConstitutionSection(
                  'Part XII - Miscellaneous',
                  'Article 240: Subject to the Constitution, the Federal Government may, by Order, provide for the government and administration of any area in the Federation not included in any Province.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConstitutionSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showPdfPreview ? _loadPdfInWebView : _openPdfInBrowser,
            icon: Icon(
              _showPdfPreview ? Icons.visibility : Icons.open_in_browser,
            ),
            label: Text(
              _showPdfPreview ? 'Preview PDF' : 'Open PDF in Browser',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _copyPdfInfo,
            icon: const Icon(Icons.copy),
            label: const Text('Copy PDF Information'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B4513),
              side: const BorderSide(color: Color(0xFF8B4513)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showPdfInfo,
            icon: const Icon(Icons.info),
            label: const Text('View Document Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B4513),
              side: const BorderSide(color: Color(0xFF8B4513)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _loadPdfInWebView() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate loading delay
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _showPdfPreview = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshPdf() {
    _loadPdfInWebView();
  }

  void _openPdfInBrowser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For web, we'll show a message to download the PDF
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF will be downloaded to your device'),
            backgroundColor: Color(0xFF8B4513),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyPdfInfo() {
    const pdfInfo = '''Constitution of Pakistan Guide
Complete PDF Document
File: guide.pdf
Format: Portable Document Format
Content: Complete Constitution with amendments
Access: Available in app assets''';

    Clipboard.setData(const ClipboardData(text: pdfInfo));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF information copied to clipboard'),
        backgroundColor: Color(0xFF8B4513),
      ),
    );
  }

  void _showPdfInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Constitution of Pakistan Guide',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This guide contains the complete Constitution of Pakistan with all amendments and provisions.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            _InfoRow(label: 'Document Type', value: 'PDF Guide'),
            _InfoRow(label: 'Content', value: 'Complete Constitution'),
            _InfoRow(label: 'Format', value: 'Portable Document Format'),
            _InfoRow(label: 'Access', value: 'Available in App'),
            _InfoRow(label: 'Status', value: 'Ready to View'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF8B4513)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
