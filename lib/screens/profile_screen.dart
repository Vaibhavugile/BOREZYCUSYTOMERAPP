import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/tenant_config.dart';
import '../services/user_helper.dart';
import 'booking_list_screen.dart';
import 'credit_history_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _ink = Color(0xFF29221F);
  static const Color _muted = Color(0xFF8E857D);
  static const Color _canvas = Color(0xFFFAF8F5);
  static const Color _primary = Color(0xFFB68A52);
  static const Color _border = Color(0xFFECE5DC);

  int points = 0;
  int rentals = 0;
  int wishlistCount = 0;

  bool isEditingName = false;
  bool loading = true;
  bool savingProfile = false;

  String customerName = 'Customer';
  String profileImageUrl = '';
  String? loadError;

  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> loadProfileData() async {
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }

    try {
      final cleanPhone = await UserHelper.getPhone();
      if (cleanPhone == null || cleanPhone.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          loading = false;
          loadError = 'We could not find your signed-in phone number.';
        });
        return;
      }

      final branch = TenantConfig.branchCode;
      final customerRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(branch)
          .collection('users')
          .doc(cleanPhone);

      final customerDoc = await customerRef.get();
      var loadedName = 'Customer';
      var loadedImage = '';
      var loadedRentals = 0;
      var loadedPoints = 0;
      var loadedWishlistCount = 0;

      if (customerDoc.exists) {
        final data = customerDoc.data() ?? <String, dynamic>{};
        loadedName = (data['name'] as String?)?.trim().isNotEmpty == true
            ? (data['name'] as String).trim()
            : 'Customer';
        loadedImage = (data['profileImage'] as String?) ?? '';

        final branchStats = data['branchStats'];
        if (branchStats is Map) {
          final currentBranchStats = branchStats[branch];
          if (currentBranchStats is Map) {
            final receiptValue = currentBranchStats['receipts'];
            if (receiptValue is num) loadedRentals = receiptValue.toInt();
          }
        }

        final creditQuery = await FirebaseFirestore.instance
            .collection('products')
            .doc(branch)
            .collection('creditNotes')
            .where('mobileNumber', isEqualTo: cleanPhone)
            .limit(1)
            .get();

        if (creditQuery.docs.isNotEmpty) {
          final balance = creditQuery.docs.first.data()['Balance'];
          if (balance is num) loadedPoints = balance.toInt();
        }

        final wishlistSnapshot = await customerRef.collection('wishlist').get();
        loadedWishlistCount = wishlistSnapshot.docs.length;
      }

      if (!mounted) return;
      setState(() {
        customerName = loadedName;
        profileImageUrl = loadedImage;
        rentals = loadedRentals;
        points = loadedPoints;
        wishlistCount = loadedWishlistCount;
        nameController.text = loadedName;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = 'We couldn’t load your profile. Please try again.';
      });
    }
  }

  Future<void> pickProfileImage() async {
    if (savingProfile) return;

    try {
      final phone = await UserHelper.getPhone();
      if (phone == null || phone.trim().isEmpty) {
        _showMessage('Please sign in again to update your photo.');
        return;
      }

      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 78,
        maxWidth: 1200,
      );
      if (picked == null || !mounted) return;

      setState(() => savingProfile = true);

      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${TenantConfig.branchCode}_$phone.jpg');

      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(TenantConfig.branchCode)
          .collection('users')
          .doc(phone)
          .set({'profileImage': downloadUrl}, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => profileImageUrl = downloadUrl);
      _showMessage('Profile photo updated.');
    } catch (e) {
      if (mounted) _showMessage('Could not upload your photo. Please try again.');
    } finally {
      if (mounted) setState(() => savingProfile = false);
    }
  }

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    try {
      final phone = await UserHelper.getPhone();
      if (phone == null || phone.trim().isEmpty) {
        _showMessage('Please sign in again to update your profile.');
        return;
      }

      setState(() => savingProfile = true);

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(TenantConfig.branchCode)
          .collection('users')
          .doc(phone)
          .set({
        'name': name,
        'profileImage': profileImageUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        customerName = name;
        isEditingName = false;
      });
      _showMessage('Your profile has been updated.');
    } catch (e) {
      if (mounted) _showMessage('Could not save your profile. Please try again.');
    } finally {
      if (mounted) setState(() => savingProfile = false);
    }
  }

  void showDeleteAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: Color(0xFFFBECE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: Color(0xFFB44A3D), size: 27),
        ),
        title: const Text(
          'Delete your account?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
        content: const Text(
          'Your account will be scheduled for deletion and permanently removed after 7 days. You can cancel the request by logging in again before the deletion date.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep account'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB44A3D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await requestAccountDeletion();
            },
            child: const Text('Request deletion'),
          ),
        ],
      ),
    );
  }

  Future<void> requestAccountDeletion() async {
    try {
      final phone = await UserHelper.getPhone();
      if (phone == null || phone.trim().isEmpty) {
        _showMessage('Please sign in again before requesting deletion.');
        return;
      }

      final deletionDate = DateTime.now().add(const Duration(days: 7));
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(TenantConfig.branchCode)
          .collection('users')
          .doc(phone)
          .set({
        'deletionRequested': true,
        'deletionRequestedAt': FieldValue.serverTimestamp(),
        'deletionDate': Timestamp.fromDate(deletionDate),
      }, SetOptions(merge: true));

      if (mounted) {
        _showMessage('Account deletion requested. Your account is scheduled for deletion in 7 days.');
      }
    } catch (e) {
      if (mounted) _showMessage('We couldn’t submit the deletion request. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  void _openBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookingListScreen()),
    );
  }

  void _openWishlist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WishlistScreen()),
    );
  }

  Future<void> _openCreditHistory() async {
    final phone = await UserHelper.getPhone();
    if (!mounted) return;
    if (phone == null || phone.trim().isEmpty) {
      _showMessage('Please sign in again to view your wallet.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditHistoryScreen(mobileNumber: phone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : SafeArea(
              child: RefreshIndicator(
                color: _primary,
                onRefresh: loadProfileData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            if (loadError != null) ...[
                              _buildErrorCard(),
                              const SizedBox(height: 16),
                            ],
                            _buildProfileCard(),
                            const SizedBox(height: 18),
                            _buildStats(),
                            const SizedBox(height: 30),
                            _sectionHeading(
                              'Your account',
                              'Manage your rentals and saved items',
                            ),
                            const SizedBox(height: 14),
                            _buildMenuGroup([
                              _MenuItemData(
                                icon: Icons.calendar_month_rounded,
                                title: 'My bookings',
                                subtitle: 'View current and previous rentals',
                                tint: const Color(0xFFF0E4D4),
                                iconColor: const Color(0xFF9A6D35),
                                onTap: _openBookings,
                              ),
                              _MenuItemData(
                                icon: Icons.favorite_rounded,
                                title: 'Wishlist',
                                subtitle: 'Your saved favourites in one place',
                                tint: const Color(0xFFF8E9DA),
                                iconColor: const Color(0xFFAD7650),
                                onTap: _openWishlist,
                              ),
                              _MenuItemData(
                                icon: Icons.account_balance_wallet_rounded,
                                title: 'Wallet & credits',
                                subtitle: 'Review your available balance',
                                tint: const Color(0xFFF7F0E7),
                                iconColor: const Color(0xFFB68A52),
                                onTap: _openCreditHistory,
                              ),
                            ]),
                            const SizedBox(height: 28),
                            _sectionHeading(
                              'Help & security',
                              'Keep your account safe and supported',
                            ),
                            const SizedBox(height: 14),
                            _buildMenuGroup([
                              _MenuItemData(
                                icon: Icons.support_agent_rounded,
                                title: 'Customer support',
                                subtitle: 'Get help with your rental experience',
                                tint: const Color(0xFFF0EDE6),
                                iconColor: const Color(0xFF75664F),
                                onTap: null,
                              ),
                              _MenuItemData(
                                icon: Icons.delete_outline_rounded,
                                title: 'Delete account',
                                subtitle: 'Request account deletion',
                                tint: const Color(0xFFFBECE7),
                                iconColor: const Color(0xFFB44A3D),
                                onTap: showDeleteAccountDialog,
                                destructive: true,
                              ),
                            ]),
                            const SizedBox(height: 24),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB68A52).withOpacity(.07),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.person_outline_rounded,
                color: _primary, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TenantConfig.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.45,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'YOUR PERSONAL SPACE',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: loadProfileData,
            icon: const Icon(Icons.refresh_rounded, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8D4B8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB76B13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loadError!,
              style: const TextStyle(color: _ink, height: 1.4),
            ),
          ),
          TextButton(onPressed: loadProfileData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFECE5DC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB68A52).withOpacity(.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDCC09A), _primary, Color(0xFF8C6537)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(.20),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFF7F0E7),
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? const Icon(Icons.person_rounded,
                          size: 48, color: _primary)
                      : null,
                ),
              ),
              Material(
                color: _primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: savingProfile ? null : pickProfileImage,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: savingProfile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt_rounded,
                            size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isEditingName)
            TextField(
              controller: nameController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              style: const TextStyle(
                color: _ink,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -.6,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFFAF8F5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => savingProfile ? null : saveProfile(),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.7,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit name',
                  onPressed: () {
                    nameController.text = customerName;
                    setState(() => isEditingName = true);
                  },
                  icon: const Icon(Icons.edit_rounded,
                      size: 18, color: _primary),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F0E7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 14, color: _primary),
                SizedBox(width: 6),
                Text(
                  'CUSTOMER ACCOUNT',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          if (isEditingName) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: savingProfile
                        ? null
                        : () {
                            nameController.text = customerName;
                            setState(() => isEditingName = false);
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _muted,
                      side: const BorderSide(color: _border),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: savingProfile ? null : saveProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: savingProfile
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              'Your rentals, rewards and saved items — all in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_month_rounded,
            label: 'RENTALS',
            value: '$rentals',
            iconColor: const Color(0xFF9A6D35),
            iconBackground: const Color(0xFFF0E4D4),
            onTap: _openBookings,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_rounded,
            label: 'WISHLIST',
            value: '$wishlistCount',
            iconColor: const Color(0xFFAD7650),
            iconBackground: const Color(0xFFF8E9DA),
            onTap: _openWishlist,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'CREDITS',
            value: '$points',
            iconColor: const Color(0xFFB68A52),
            iconBackground: const Color(0xFFF7F0E7),
            onTap: _openCreditHistory,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildMenuGroup(List<_MenuItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB68A52).withOpacity(.045),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _buildMenuItem(items[i]),
            if (i != items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 74),
                child: Divider(height: 1, color: Color(0xFFF0F2F7)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItemData item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.tint,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: item.destructive
                            ? const Color(0xFFB44A3D)
                            : _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                item.onTap == null
                    ? Icons.more_horiz_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: item.onTap == null ? 18 : 14,
                color: const Color(0xFFB8ADA1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFECE5DC),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${TenantConfig.appName}  •  V2.4.0',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF929BAD),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: .3,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Made for a smoother rental experience',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFADB4C2), fontSize: 10.5),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 15, 10, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFFE8ECF4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB68A52).withOpacity(.045),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 11),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF29221F),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.6,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8992A4),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .9,
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

class _MenuItemData {
  const _MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.iconColor,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool destructive;
}
