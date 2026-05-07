import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../services/tenant_config.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  Future<void> openUrl(String url) async {

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,

        title: const Text(
          "Our Store",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 HERO CARD
            Container(
              width: double.infinity,

              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(30),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 20,
                  )
                ],
              ),

              child: Column(
                children: [

                  /// STORE IMAGE
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),

                    child: Image.network(
                      TenantConfig.storeImage,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),

                    child: Column(
                      children: [

                        Text(
                          TenantConfig.storeName,
                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          TenantConfig.storeTagline,
                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,

                          children: [

                            buildFeature(
                              Icons.workspace_premium,
                              "Luxury",
                            ),

                            buildFeature(
                              Icons.checkroom,
                              "Premium",
                            ),

                            buildFeature(
                              Icons.favorite,
                              "Trusted",
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🔥 STORE INFORMATION
            buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SectionTitle(
                    "Store Information",
                    Icons.store,
                  ),

                  const SizedBox(height: 20),

                  infoTile(
                    Icons.location_on,
                    "Address",
                    TenantConfig.storeAddress,
                  ),

                  infoTile(
                    Icons.phone,
                    "Contact Number",
                    TenantConfig.supportPhone,
                  ),

                  infoTile(
                    Icons.access_time,
                    "Store Timing",
                    TenantConfig.storeTiming,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🔥 SOCIAL MEDIA
            buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SectionTitle(
                    "Social Media",
                    Icons.public,
                  ),

                  const SizedBox(height: 20),

                  socialButton(
                    icon: Icons.camera_alt,
                    title: "Instagram",

                    onTap: () {
                      openUrl(
                        TenantConfig.instagramUrl,
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  socialButton(
                    icon: Icons.facebook,
                    title: "Facebook",

                    onTap: () {
                      openUrl(
                        TenantConfig.facebookUrl,
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  socialButton(
                    icon: Icons.chat,
                    title: "WhatsApp",

                    onTap: () {
                      openUrl(
                        "https://wa.me/${TenantConfig.supportPhone}",
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 🔥 ACTION BUTTONS
            Row(
              children: [

                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text("Directions"),

                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,

                      side: const BorderSide(
                        color: AppColors.primary,
                      ),

                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    onPressed: () {

                      openUrl(
                        TenantConfig.googleMapUrl,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text("Call Store"),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    onPressed: () {

                      openUrl(
                        "tel:+${TenantConfig.supportPhone}",
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// 🔥 PREMIUM CARD
  Widget buildCard({
    required Widget child,
  }) {

    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: AppColors.primaryLight,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
          )
        ],
      ),

      child: child,
    );
  }

  /// 🔥 FEATURES
  Widget buildFeature(
    IconData icon,
    String title,
  ) {

    return Column(
      children: [

        Icon(
          icon,
          color: Colors.white,
        ),

        const SizedBox(height: 8),

        Text(
          title,

          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        )
      ],
    );
  }

  /// 🔥 INFO TILE
  Widget infoTile(
    IconData icon,
    String title,
    String value,
  ) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// 🔥 SOCIAL BUTTON
  Widget socialButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(18),
        ),

        child: Row(
          children: [

            Icon(
              icon,
              color: AppColors.primary,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,

                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            )
          ],
        ),
      ),
    );
  }
}

/// 🔥 SECTION TITLE
class SectionTitle extends StatelessWidget {

  final String title;
  final IconData icon;

  const SectionTitle(
    this.title,
    this.icon,
    {super.key}
  );

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [

        Icon(
          icon,
          color: AppColors.primary,
        ),

        const SizedBox(width: 10),

        Text(
          title,

          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        )
      ],
    );
  }
}