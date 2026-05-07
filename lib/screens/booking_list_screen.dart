import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'BookingDetailsScreen.dart';
import '../services/tenant_config.dart';
import '../services/user_helper.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {

  int selectedTab = 0;

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}";
  }

  bool matchStage(String stage) {

    if (selectedTab == 0) {
      return stage == "Booking" || stage == "pickupPending";
    }

    if (selectedTab == 1) {
      return stage == "pickup" ||
          stage == "returnPending" ||
          stage == "return";
    }

    if (selectedTab == 2) {
      return stage == "successful" ||
          stage == "cancelled" ||
          stage == "postponed";
    }

    return false;
  }

  Color stageColor(String stage) {

    switch(stage){

      case "Booking":
      case "pickupPending":
        return Colors.orange;

      case "pickup":
      case "returnPending":
      case "return":
        return Colors.blue;

      case "successful":
        return Colors.green;

      case "cancelled":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  @override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: AppColors.background,

    appBar: AppBar(
      elevation: 0,
      backgroundColor: AppColors.background,
      title: const Text(
        "My Bookings",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    ),

    body: Column(
      children: [

        const SizedBox(height: 20),

        /// TAB BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                buildTab("Upcoming", 0),
                buildTab("Current", 1),
                buildTab("Past", 2),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        /// 🔥 FIXED STREAM WITH USER HELPER
        Expanded(
          child: FutureBuilder<String?>(
            future: UserHelper.getPhone(),
            builder: (context, phoneSnap) {

              if (!phoneSnap.hasData || phoneSnap.data == null) {
                return const Center(child: Text("No bookings found"));
              }

              final cleanPhone = phoneSnap.data!;

              final future = FirebaseFirestore.instance
    .collection("products")
    .doc(TenantConfig.branchCode)
    .collection("payments")
    .where("contact", isEqualTo: cleanPhone)
    .orderBy("createdAt", descending: true)
    .limit(20)
    .get();

              return FutureBuilder<QuerySnapshot>(
                future: future,
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final stage = data["bookingStage"] ?? "";
                    return matchStage(stage);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text("No bookings found"));
                  }

                 return RefreshIndicator(
  onRefresh: () async {

    setState(() {});

    await Future.delayed(
      const Duration(milliseconds: 500),
    );
  },

  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {

                      final data = filteredDocs[index].data()
                          as Map<String, dynamic>;

                      final receipt = data["receiptNumber"];
                      final stage = data["bookingStage"];
                      final amount = data["totalAmount"];

                      final pickup =
                          (data["pickupDate"] as Timestamp).toDate();

                      final returnDate =
                          (data["returnDate"] as Timestamp).toDate();

                      final products = data["products"] ?? [];

                      String image = "";
                      if (products.isNotEmpty) {
                        image = products[0]["imageUrl"] ?? "";
                      }

                      List codes =
                          products.map((p) => p["productCode"]).toList();

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookingDetailsScreen(booking: data),
                            ),
                          );
                        },

                        child: Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.dark.withOpacity(.04),
                                blurRadius: 16,
                              )
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: image.isNotEmpty
                                        ? Image.network(
                                            image,
                                            width: 80,
                                            height: 110,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 80,
                                            height: 110,
                                            color: AppColors.primaryLight,
                                            child: const Icon(Icons.image),
                                          ),
                                  ),

                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [

                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4),
                                          decoration: BoxDecoration(
                                            color: stageColor(stage)
                                                .withOpacity(.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            stage,
                                            style: TextStyle(
                                              color: stageColor(stage),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Text(
                                          receipt,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          "${products.length} items booked",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),

                              const SizedBox(height: 14),

                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ...codes.take(4).map((code) {
                                    return Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        code.toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }),

                                  if (codes.length > 4)
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "+${codes.length - 4}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                ],
                              ),

                              const SizedBox(height: 12),

buildTimeline(stage),

                              const Divider(),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [

                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16,
                                          color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        "${formatDate(pickup)} - ${formatDate(returnDate)}",
                                        style: const TextStyle(
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),

                                  Text(
                                    "₹$amount",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primary,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  );
                },
              );
            },
          ),
        )
      ],
    ),
  );
}

  Widget buildTab(String title,int index){

    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(

        onTap:(){
          setState(() {
            selectedTab = index;
          });
        },

        child: Container(
          padding: const EdgeInsets.symmetric(vertical:14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
    ? AppColors.primary
    : AppColors.textSecondary
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget buildTimeline(String stage) {

  final stages = [
    "Booking",
    "Pickup Pending",
    "Picked Up",
    "Return Pending",
    "Returned",
    "Completed",
  ];

  int currentIndex = 0;

  switch(stage){

    case "Booking":
      currentIndex = 0;
      break;

    case "pickupPending":
      currentIndex = 1;
      break;

    case "pickup":
      currentIndex = 2;
      break;

    case "returnPending":
      currentIndex = 3;
      break;

    case "return":
      currentIndex = 4;
      break;

    case "successful":
      currentIndex = 5;
      break;
  }

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,

    child: Row(
      children: List.generate(stages.length, (index) {

        final isCompleted = index <= currentIndex;

        return Row(
          children: [

            Column(
              children: [

                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),

                  width: 26,
                  height: 26,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: isCompleted
                        ? Colors.green
                        : Colors.grey.shade300,

                    boxShadow: isCompleted
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),

                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 15,
                          color: Colors.white,
                        )
                      : null,
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: 80,

                  child: Text(
                    stages[index],
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCompleted
                          ? FontWeight.w600
                          : FontWeight.w400,

                      color: isCompleted
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            if(index != stages.length - 1)
              Container(
                width: 40,
                height: 3,
                margin: const EdgeInsets.only(bottom: 28),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  color: index < currentIndex
                      ? Colors.green
                      : Colors.grey.shade300,
                ),
              ),
          ],
        );
      }),
    ),
  );
}
}