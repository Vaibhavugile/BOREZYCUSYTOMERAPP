import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/tenant_config.dart';
import '../services/user_helper.dart';

class SubmitDressScreen extends StatefulWidget {
  const SubmitDressScreen({super.key});

  @override
  State<SubmitDressScreen> createState() => _SubmitDressScreenState();
}

class _SubmitDressScreenState extends State<SubmitDressScreen>
    with SingleTickerProviderStateMixin {
  static const Color _ink = Color(0xFF29221E);
  static const Color _gold = Color(0xFFC5A46D);
  static const Color _background = Color(0xFFFCF9F5);
  static const Color _muted = Color(0xFF81766D);
  static const Color _line = Color(0xFFECE2D5);
  static const Color _softGold = Color(0xFFF5EBDD);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final List<XFile> _images = [];

  String? _category;
  String? _size;
  String? _condition;
  String _partnership = 'revenue_share';
  bool _isSubmitting = false;

  final List<String> _categories = const [
    'Lehenga',
    'Saree',
    'Gown',
    'Anarkali',
    'Indo-Western',
    'Sherwani',
    'Suit',
    'Other',
  ];

  final List<String> _sizes = const [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'Free Size',
    'Custom Size',
  ];

  final List<String> _conditions = const [
    'Like New',
    'Excellent',
    'Good',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(_fadeAnimation);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_isSubmitting) return;
    final remaining = 5 - _images.length;

    if (remaining <= 0) {
      _showMessage('You can upload up to 5 photos.');
      return;
    }

    try {
      final selected = await _picker.pickMultiImage(
        imageQuality: 82,
        maxWidth: 1800,
      );

      if (!mounted || selected.isEmpty) return;

      final available = 5 - _images.length;
      final newImages = selected.take(available).toList();

      setState(() => _images.addAll(newImages));

      if (selected.length > available && mounted) {
        _showMessage('Only 5 photos can be added. Extra photos were skipped.');
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to select photos. Please try again.');
    }
  }

  Future<void> _submitDress() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      _showMessage('Please add at least one photo of your dress.');
      return;
    }

    if (_category == null || _size == null || _condition == null) {
      _showMessage('Please select category, size and condition.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final branchCode = TenantConfig.branchCode.trim();
      if (branchCode.isEmpty) {
        throw Exception('Branch configuration is missing.');
      }

      final phone = await UserHelper.getPhone();
      if (phone == null || phone.trim().isEmpty) {
        throw Exception(
          'Please sign in with your mobile number before submitting.',
        );
      }

      final user = FirebaseAuth.instance.currentUser;
      final requestRef = FirebaseFirestore.instance
          .collection('products')
          .doc(branchCode)
          .collection('dressRentalRequests')
          .doc();

      final imageUrls = <String>[];

      for (var i = 0; i < _images.length; i++) {
        final image = _images[i];
        final extension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';
        final contentType = extension == 'png'
            ? 'image/png'
            : extension == 'webp'
                ? 'image/webp'
                : 'image/jpeg';

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('products')
            .child(branchCode)
            .child('dressRentalRequests')
            .child(requestRef.id)
            .child('${DateTime.now().millisecondsSinceEpoch}_$i.$extension');

        final upload = await storageRef.putFile(
          File(image.path),
          SettableMetadata(contentType: contentType),
        );

        imageUrls.add(await upload.ref.getDownloadURL());
      }

      final requestData = <String, dynamic>{
        'requestId': requestRef.id,
        'branchCode': branchCode,
        'ownerUid': user?.uid,
        'ownerPhone': phone.trim(),
        'dressName': _nameController.text.trim(),
        'category': _category,
        'size': _size,
        'condition': _condition,
        'description': _descriptionController.text.trim(),
        'imageUrls': imageUrls,
        'preferredModel': _partnership,
        'status': 'submitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'ownerSharePercent': _partnership == 'revenue_share' ? 30 : null,
        'dorSharePercent': _partnership == 'revenue_share' ? 70 : null,
        'approvedRentalPrice': null,
        'approvedCreditAmount': null,
        'adminNotes': null,
        'reviewedAt': null,
        'offerAccepted': false,
      };

      await requestRef.set(requestData);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          backgroundColor: _background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 28, 25, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F1E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 36,
                    color: Color(0xFF356B48),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your dress is submitted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Thank you for sharing your outfit with Dor. '
                  'Our team will review your submission and confirm '
                  'the applicable rental price and terms.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    height: 1.6,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        'Submission failed: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? const Color(0xFF9C3838) : _ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _isSubmitting ? null : () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
        title: const Column(
          children: [
            Text(
              'D O R',
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'LIST YOUR DRESS',
              style: TextStyle(
                color: _muted,
                fontSize: 8,
                letterSpacing: 1.7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: BoxDecoration(
            color: _background,
            border: Border(top: BorderSide(color: _line.withOpacity(0.8))),
            boxShadow: [
              BoxShadow(
                color: _ink.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitDress,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB9B0A7),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSubmitting
                    ? const Row(
                        key: ValueKey('loading'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Submitting your dress...'),
                        ],
                      )
                    : const Row(
                        key: ValueKey('submit'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Submit for Review',
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
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                _buildIntro(),
                const SizedBox(height: 27),
                _sectionHeading('01', 'Dress photos', 'A picture tells the story'),
                const SizedBox(height: 13),
                _buildPhotoPicker(),
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildPhotoGallery(),
                ],
                const SizedBox(height: 30),
                _sectionHeading('02', 'Dress details', 'Help us understand your outfit'),
                const SizedBox(height: 17),
                _label('Dress name'),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    'e.g. Designer bridal lehenga',
                    icon: Icons.checkroom_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the dress name';
                    }
                    if (value.trim().length < 3) {
                      return 'Enter at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 17),
                _label('Category'),
                DropdownButtonFormField<String>(
                  value: _category,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    'Choose a category',
                    icon: Icons.category_outlined,
                  ),
                  items: _categories
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _category = value),
                  validator: (value) =>
                      value == null ? 'Select a category' : null,
                ),
                const SizedBox(height: 17),
                _label('Size'),
                DropdownButtonFormField<String>(
                  value: _size,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    'Choose the size',
                    icon: Icons.straighten_rounded,
                  ),
                  items: _sizes
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _size = value),
                  validator: (value) => value == null ? 'Select a size' : null,
                ),
                const SizedBox(height: 17),
                _label('Current condition'),
                DropdownButtonFormField<String>(
                  value: _condition,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    'Choose the condition',
                    icon: Icons.auto_awesome_outlined,
                  ),
                  items: _conditions
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _condition = value),
                  validator: (value) =>
                      value == null ? 'Select the dress condition' : null,
                ),
                const SizedBox(height: 17),
                _label('Additional details (optional)'),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSubmitting,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    'Fabric, colour, designer, embellishments or special details',
                    icon: Icons.notes_rounded,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 31),
                _sectionHeading(
                  '03',
                  'Your partnership',
                  'Choose how you would prefer to benefit',
                ),
                const SizedBox(height: 10),
                _infoBanner(),
                const SizedBox(height: 15),
                _partnershipOption(
                  value: 'revenue_share',
                  icon: Icons.percent_rounded,
                  title: 'Revenue sharing',
                  subtitle: 'Earn when your dress is rented',
                  description:
                      'Proposed split: 30% to you and 70% to Dor '
                      'from the agreed rental revenue. Final terms '
                      'must be confirmed by Dor.',
                  tag: 'PROPOSED 30% OWNER SHARE',
                ),
                const SizedBox(height: 13),
                _partnershipOption(
                  value: 'credit_note',
                  icon: Icons.card_giftcard_rounded,
                  title: 'Dor credit note',
                  subtitle: 'Receive eligible shopping credit',
                  description:
                      'Dor will review your dress and confirm any '
                      'approved credit amount and applicable conditions.',
                  tag: 'AMOUNT APPROVED BY DOR',
                ),
                const SizedBox(height: 25),
                _buildReviewNote(),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          colors: [Color(0xFF30251F), Color(0xFF70543E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.11),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -12,
            child: Icon(
              Icons.diamond_outlined,
              size: 105,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'THE DOR CIRCULAR FASHION EDIT',
                  style: TextStyle(
                    color: Color(0xFFE8CEA1),
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Give your outfit\na new story.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                'Share the details, choose your preferred partnership, '
                'and let our team review your dress.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.79),
                  fontSize: 13,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: Color(0xFFE8CEA1),
                    size: 17,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Every submission is reviewed by Dor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String number, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 43,
          height: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _softGold,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    final full = _images.length >= 5;

    return InkWell(
      onTap: full ? null : _pickImages,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: full ? _line : _gold.withOpacity(0.65),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _softGold,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Icon(
                full ? Icons.check_rounded : Icons.add_a_photo_outlined,
                color: _gold,
                size: 27,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              full ? 'Photo limit reached' : 'Add your dress photos',
              style: const TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose clear photos showing the full outfit and details.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5EF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${_images.length} of 5 photos selected  ·  JPG, PNG or WebP',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                width: 112,
                height: 116,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: _line),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_images[index].path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: _softGold,
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 7,
                bottom: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.62),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PHOTO ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (!_isSubmitting)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black.withOpacity(0.68),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _images.removeAt(index)),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: _ink,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFA69B91),
        fontSize: 12,
      ),
      prefixIcon: Icon(icon, color: _gold, size: 20),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFB64C4C)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFB64C4C), width: 1.4),
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: Color(0xFF997648),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is your preferred option, not a confirmed offer. '
              'Dor will confirm the final terms after reviewing your dress.',
              style: TextStyle(
                color: Color(0xFF6F6256),
                fontSize: 11,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _partnershipOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required String tag,
  }) {
    final selected = _partnership == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 230),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFFBF4) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? _gold : _line,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _gold.withOpacity(0.09),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: _isSubmitting
              ? null
              : () => setState(() => _partnership = value),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: selected ? _softGold : const Color(0xFFF8F5EF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: _gold, size: 23),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? _ink : Colors.transparent,
                        border: Border.all(
                          color: selected ? _ink : const Color(0xFFD5C9B9),
                          width: 1.4,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 15,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _softGold : const Color(0xFFF5F2ED),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Color(0xFF80633C),
                      fontSize: 9,
                      letterSpacing: 0.45,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: _gold,
            size: 21,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'By submitting, you request a review only. Listing approval, '
              'rental pricing, revenue share and credit-note terms are '
              'confirmed by Dor after review.',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
