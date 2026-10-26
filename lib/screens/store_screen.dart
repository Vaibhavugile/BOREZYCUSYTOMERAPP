import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/tenant_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _fadeAnimation;

  static const Color _ink = Color(0xFF211A18);
  static const Color _gold = Color(0xFFC9A875);
  static const Color _cream = Color(0xFFFAF7F2);
  static const Color _muted = Color(0xFF81766D);
  static const Color _border = Color(0xFFECE4D9);

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _motionController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: .94, end: 1).animate(
      CurvedAnimation(parent: _motionController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String rawUrl) async {
    final value = rawUrl.trim();
    if (value.isEmpty) return;

    final uri = Uri.tryParse(value);
    if (uri == null) return;

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this link right now.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 22,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'THE EXPERIENCE',
              style: TextStyle(
                color: _muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Our Store',
              style: TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _border),
              ),
              child: IconButton(
                tooltip: 'Contact store',
                onPressed: () => _openUrl(
                  'https://wa.me/${TenantConfig.supportPhone.replaceAll(RegExp(r'[^0-9]'), '')}',
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              const SizedBox(height: 22),
              _buildTrustStrip(),
              const SizedBox(height: 30),
              _sectionHeading('A little about us', 'THE DETAILS'),
              const SizedBox(height: 14),
              _buildInformationCard(),
              const SizedBox(height: 30),
              _sectionHeading('Stay connected', 'FOLLOW OUR WORLD'),
              const SizedBox(height: 14),
              _buildSocialCard(),
              const SizedBox(height: 26),
              _buildActions(),
              const SizedBox(height: 25),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 34,
                      height: 1,
                      color: _gold,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'THOUGHTFULLY CURATED. PERSONALLY SERVED.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 8,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _motionController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value * .35),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _ink.withOpacity(.17),
              blurRadius: 28,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: TenantConfig.storeImage.trim().isNotEmpty
                  ? Image.network(
                      TenantConfig.storeImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _heroFallback(),
                    )
                  : _heroFallback(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(.10),
                      const Color(0xFF1B1411).withOpacity(.35),
                      const Color(0xFF1B1411).withOpacity(.94),
                    ],
                    stops: const [0, .36, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(.28)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFFF3D9A7), size: 14),
                    SizedBox(width: 7),
                    Text(
                      'YOUR LOCAL DESTINATION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.13),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.25)),
                ),
                child: const Icon(Icons.north_east_rounded, color: Colors.white, size: 19),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(23, 190, 23, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TenantConfig.storeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    TenantConfig.storeTagline,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.82),
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _heroPill(Icons.workspace_premium_rounded, 'Curated quality'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _heroPill(Icons.favorite_rounded, 'Made for you'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8A6B50), Color(0xFF30231D), Color(0xFF171311)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 100,
          color: Colors.white.withOpacity(.12),
        ),
      ),
    );
  }

  Widget _heroPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFF0D7A8)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustStrip() {
    return Row(
      children: [
        Expanded(child: _trustItem(Icons.diamond_outlined, 'Quality', 'Carefully chosen')),
        const SizedBox(width: 9),
        Expanded(child: _trustItem(Icons.handshake_outlined, 'Personal', 'Here to help')),
        const SizedBox(width: 9),
        Expanded(child: _trustItem(Icons.verified_outlined, 'Trusted', 'Service first')),
      ],
    );
  }

  Widget _trustItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _gold.withOpacity(.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF967344), size: 19),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            style: const TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 8, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String eyebrow) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: Color(0xFF9C7B4D),
                  fontSize: 8,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _border),
          ),
          child: const Icon(Icons.arrow_outward_rounded, color: _gold, size: 17),
        ),
      ],
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 6, 17, 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: _ink.withOpacity(.035), blurRadius: 20, offset: const Offset(0, 7)),
        ],
      ),
      child: Column(
        children: [
          _infoTile(Icons.location_on_outlined, 'Visit us', TenantConfig.storeAddress),
          _divider(),
          _infoTile(Icons.phone_in_talk_outlined, 'Give us a call', TenantConfig.supportPhone),
          _divider(),
          _infoTile(Icons.schedule_rounded, 'Store hours', TenantConfig.storeTiming),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: Color(0xFFF1EBE3), indent: 54);

  Widget _infoTile(IconData icon, String title, String value) {
    final displayValue = value.trim().isEmpty ? 'Please contact us for details' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_gold.withOpacity(.22), _gold.withOpacity(.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF8D6D42), size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text(
                  displayValue,
                  style: const TextStyle(color: _ink, fontSize: 13, height: 1.45, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB7A99A), size: 20),
        ],
      ),
    );
  }

  Widget _buildSocialCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF30251F), Color(0xFF4D3A2D)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _ink.withOpacity(.11), blurRadius: 22, offset: const Offset(0, 9)),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A closer look',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Follow along for updates and inspiration.',
                      style: TextStyle(color: Color(0xFFD7CCC2), fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              Icon(Icons.waves_rounded, color: Color(0xFFE2C18D), size: 30),
            ],
          ),
          const SizedBox(height: 17),
          _socialRow(
            icon: Icons.camera_alt_outlined,
            title: 'Instagram',
            subtitle: 'Discover our latest looks',
            onTap: () => _openUrl(TenantConfig.instagramUrl),
          ),
          const SizedBox(height: 9),
          _socialRow(
            icon: Icons.facebook_rounded,
            title: 'Facebook',
            subtitle: 'News, updates and more',
            onTap: () => _openUrl(TenantConfig.facebookUrl),
          ),
          const SizedBox(height: 9),
          _socialRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'WhatsApp',
            subtitle: 'Talk to our team directly',
            onTap: () => _openUrl(
              'https://wa.me/${TenantConfig.supportPhone.replaceAll(RegExp(r'[^0-9]'), '')}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.11),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withOpacity(.13)),
                ),
                child: Icon(icon, color: const Color(0xFFE8CCA0), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: Color(0xFFD7CCC2), fontSize: 10)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFFE8CCA0), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () => _openUrl(TenantConfig.googleMapUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.near_me_outlined, size: 19),
                SizedBox(width: 10),
                Text('Get directions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                SizedBox(width: 8),
                Icon(Icons.arrow_outward_rounded, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 11),
        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: () => _openUrl('tel:${TenantConfig.supportPhone.replaceAll(RegExp(r'[^0-9+]'), '')}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              side: const BorderSide(color: _border, width: 1.2),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call_outlined, size: 18),
                SizedBox(width: 9),
                Text('Call our store', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
