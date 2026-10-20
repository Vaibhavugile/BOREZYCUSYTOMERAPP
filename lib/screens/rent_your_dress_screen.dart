
import 'package:flutter/material.dart';
import 'submit_dress_screen.dart';

class RentYourDressScreen extends StatefulWidget {
  const RentYourDressScreen({super.key});

  @override
  State<RentYourDressScreen> createState() =>
      _RentYourDressScreenState();
}

class _RentYourDressScreenState extends State<RentYourDressScreen>
    with SingleTickerProviderStateMixin {
  static const Color _background = Color(0xFFFCF9F5);
  static const Color _ink = Color(0xFF29221E);
  static const Color _gold = Color(0xFFC5A46D);
  static const Color _muted = Color(0xFF81766D);
  static const Color _cream = Color(0xFFF2E8DA);

  late final AnimationController _controller;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;

  bool _showBenefits = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _heroFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _reveal({
    required int index,
    required Widget child,
  }) {
    final double start = (index * 0.09).clamp(0.0, 0.70);
    final double end = (start + 0.30).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.07),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  void _openSubmission() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SubmitDressScreen(),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar()),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _reveal(
                    index: 0,
                    child: _buildHero(),
                  ),

                  const SizedBox(height: 32),

                  _reveal(
                    index: 1,
                    child: _buildSectionHeading(
                      eyebrow: 'THE DOR EXPERIENCE',
                      title: 'Your style deserves\na second story.',
                      subtitle:
                          'Turn the outfits you love into an opportunity '
                          'while someone else creates beautiful memories.',
                    ),
                  ),

                  const SizedBox(height: 24),

                  _reveal(
                    index: 2,
                    child: _buildStats(),
                  ),

                  const SizedBox(height: 34),

                  _reveal(
                    index: 3,
                    child: _buildHowItWorks(),
                  ),

                  const SizedBox(height: 34),

                  _reveal(
                    index: 4,
                    child: _buildPartnerships(),
                  ),

                  const SizedBox(height: 28),

                  _reveal(
                    index: 5,
                    child: _buildBenefits(),
                  ),

                  const SizedBox(height: 30),

                  _reveal(
                    index: 6,
                    child: _buildBottomAction(),
                  ),

                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 20, 12),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 19,
                  color: _ink,
                ),
              ),
            ),
          ),

          const Expanded(
            child: Column(
              children: [
                Text(
                  'D O R',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: _ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'PRE-LOVED. RE-IMAGINED.',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 1.5,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF997648),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      height: 465,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF49372D),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1539008835657-9e8e9680c956'
            '?auto=format&fit=crop&w=1200&q=85',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF30231D),
                      Color(0xFF80634C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.checkroom_rounded,
                    size: 100,
                    color: Color(0xFFE5C995),
                  ),
                ),
              );
            },
          ),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.12),
                  Colors.transparent,
                  const Color(0xFF211712).withOpacity(0.94),
                ],
                stops: const [0, 0.32, 1],
              ),
            ),
          ),

          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: Color(0xFFFFDDA8),
                  ),
                  SizedBox(width: 7),
                  Text(
                    'THE CIRCULAR FASHION EDIT',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 26,
            child: FadeTransition(
              opacity: _heroFade,
              child: SlideTransition(
                position: _heroSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR WARDROBE.\nYOUR NEXT CHAPTER.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1.17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 13),

                    Text(
                      'Give your beautiful outfits another life '
                      'and discover a new way to benefit with Dor.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.86),
                        fontSize: 14,
                        height: 1.65,
                      ),
                    ),

                    const SizedBox(height: 22),

                    InkWell(
                      onTap: _openSubmission,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 19,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8CEA1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Share your outfit',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: _ink,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required String eyebrow,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF9A7849),
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 29,
            height: 1.18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(
            color: _muted,
            fontSize: 14,
            height: 1.75,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 21,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE3D6)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.recycling_rounded,
              title: 'Re-loved',
              subtitle: 'Fashion',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.handshake_outlined,
              title: 'Two',
              subtitle: 'Ways to benefit',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.verified_outlined,
              title: 'Dor',
              subtitle: 'Reviewed',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('A beautiful journey', 'How it works'),

        const SizedBox(height: 23),

        _WorkflowStep(
          number: '01',
          icon: Icons.photo_camera_back_outlined,
          title: 'Show us your dress',
          description:
              'Upload clear photos and add the outfit details.',
        ),

        _WorkflowStep(
          number: '02',
          icon: Icons.favorite_border_rounded,
          title: 'Choose your preference',
          description:
              'Select revenue sharing or a Dor credit note.',
        ),

        _WorkflowStep(
          number: '03',
          icon: Icons.fact_check_outlined,
          title: 'Our team reviews it',
          description:
              'Dor reviews your submission and proposes the '
              'rental price and applicable terms.',
        ),

        _WorkflowStep(
          number: '04',
          icon: Icons.account_balance_wallet_outlined,
          title: 'Follow your benefits',
          description:
              'Track approved listings, bookings, earnings, '
              'payouts or eligible credits as these features '
              'become available in your account.',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildPartnerships() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'CHOOSE YOUR PATH',
          'Two ways to benefit',
        ),

        const SizedBox(height: 9),

        const Text(
          'Tell us which partnership you prefer. Dor will '
          'review the dress and confirm the applicable terms.',
          style: TextStyle(
            color: _muted,
            fontSize: 13,
            height: 1.7,
          ),
        ),

        const SizedBox(height: 21),

        _PartnershipCard(
          icon: Icons.percent_rounded,
          title: 'Revenue sharing',
          subtitle: 'Earn when your dress is rented.',
          description:
              'Proposed split: 30% to the dress owner '
              'and 70% to Dor, subject to final approval '
              'and agreed terms.',
          tag: 'PROPOSED 30% OWNER SHARE',
          highlighted: true,
          onTap: _openSubmission,
        ),

        const SizedBox(height: 14),

        _PartnershipCard(
          icon: Icons.card_giftcard_rounded,
          title: 'Dor credit note',
          subtitle: 'Choose eligible Dor shopping credits.',
          description:
              'The credit-note amount and conditions are '
              'reviewed and approved by the Dor team.',
          tag: 'AMOUNT CONFIRMED BY DOR',
          highlighted: false,
          onTap: _openSubmission,
        ),
      ],
    );
  }

  Widget _buildBenefits() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cream.withOpacity(0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _gold.withOpacity(0.28),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showBenefits = !_showBenefits;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF9A7849),
                  ),
                ),

                const SizedBox(width: 13),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why list with Dor?',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'A thoughtful way to re-love fashion.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                AnimatedRotation(
                  turns: _showBenefits ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _ink,
                    size: 25,
                  ),
                ),
              ],
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox(
              width: double.infinity,
              height: 0,
            ),
            secondChild: const Padding(
              padding: EdgeInsets.only(top: 19),
              child: Column(
                children: [
                  _BenefitRow(
                    icon: Icons.check_circle_outline_rounded,
                    text: 'Simple online dress submission',
                  ),
                  SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.check_circle_outline_rounded,
                    text: 'Two partnership preferences',
                  ),
                  SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.check_circle_outline_rounded,
                    text: 'Review and terms confirmed by Dor',
                  ),
                  SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.check_circle_outline_rounded,
                    text: 'Listing remains subject to approval',
                  ),
                ],
              ),
            ),
            crossFadeState: _showBenefits
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.diamond_outlined,
            size: 32,
            color: Color(0xFFE8CEA1),
          ),

          const SizedBox(height: 13),

          const Text(
            'Ready for your dress\nto tell a new story?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Start with your photos. Our team will take '
            'it from there.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 13,
              height: 1.7,
            ),
          ),

          const SizedBox(height: 23),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _openSubmission,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8CEA1),
                foregroundColor: _ink,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'List Your Dress',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          Text(
            'Every submission is reviewed by Dor.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.60),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String eyebrow, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF9A7849),
            fontSize: 9,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StatItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: const Color(0xFFAA8958)),
        const SizedBox(height: 9),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF29221E),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF81766D),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: const Color(0xFFEDE3D6),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

  const _WorkflowStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 54,
            child: Column(
              children: [
                Container(
                  width: 49,
                  height: 49,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE8D8C1),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 23,
                    color: const Color(0xFFAA8958),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: const Color(0xFFE5D7C5),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3, bottom: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number  ·  $title',
                    style: const TextStyle(
                      color: Color(0xFF29221E),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF81766D),
                      fontSize: 12,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnershipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final String tag;
  final bool highlighted;
  final VoidCallback onTap;

  const _PartnershipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tag,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? Colors.white : const Color(0xFFFFFDF9),
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFD9C19C)
                  : const Color(0xFFEDE3D6),
              width: highlighted ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 47,
                    height: 47,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EBDD),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF997648),
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF29221E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF81766D),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 19,
                    color: Color(0xFF997648),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF81766D),
                  fontSize: 12,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: highlighted
                      ? const Color(0xFFF5EBDD)
                      : const Color(0xFFF2F0EB),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Color(0xFF80633C),
                    fontSize: 9,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF997648),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF574B42),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
