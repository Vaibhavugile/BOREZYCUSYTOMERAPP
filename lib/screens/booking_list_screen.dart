import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {

  final String branchCode = "7007";

  int selectedTab = 0;

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}";
  }

  bool isUpcoming(DateTime pickup) {
    return pickup.isAfter(DateTime.now());
  }

  bool isPast(DateTime returnDate) {
    return returnDate.isBefore(DateTime.now());
  }

  bool isCurrent(DateTime pickup, DateTime returnDate) {
    final now = DateTime.now();
    return pickup.isBefore(now) && returnDate.isAfter(now);
  }

  @override
  Widget build(BuildContext context) {

    final phone = FirebaseAuth.instance.currentUser!.phoneNumber!;
    final cleanPhone = phone.replaceAll("+91", "");

    final stream = FirebaseFirestore.instance
        .collection("products")
        .doc(branchCode)
        .collection("payments")
        .where("contact", isEqualTo: cleanPhone)
        .orderBy("createdAt", descending: true)
        .snapshots();

    return Scaffold(

      backgroundColor: const Color(0xFFF6F6F8),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "My Bookings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
                color: Colors.grey.shade200,
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

          /// BOOKINGS
          Expanded(

            child: StreamBuilder<QuerySnapshot>(

              stream: stream,

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                List filteredDocs = [];

                for (var doc in docs) {

                  final data = doc.data() as Map<String, dynamic>;

                  final pickup =
                      (data["pickupDate"] as Timestamp).toDate();

                  final returnDate =
                      (data["returnDate"] as Timestamp).toDate();

                  if (selectedTab == 0 && isUpcoming(pickup)) {
                    filteredDocs.add(data);
                  }

                  if (selectedTab == 1 &&
                      isCurrent(pickup, returnDate)) {
                    filteredDocs.add(data);
                  }

                  if (selectedTab == 2 && isPast(returnDate)) {
                    filteredDocs.add(data);
                  }
                }

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text("No bookings found"),
                  );
                }

                return ListView.builder(

                  padding: const EdgeInsets.all(20),

                  itemCount: filteredDocs.length,

                  itemBuilder: (context, index) {

                    final data = filteredDocs[index];

                    final receipt = data["receiptNumber"];
                    final stage = data["bookingStage"];
                    final amount = data["totalAmount"];

                    final pickup =
                        (data["pickupDate"] as Timestamp).toDate();

                    final returnDate =
                        (data["returnDate"] as Timestamp).toDate();

                    return Container(

                      margin: const EdgeInsets.only(bottom: 20),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 18,
                          )
                        ],
                      ),

                      child: Padding(

                        padding: const EdgeInsets.all(18),

                        child: Row(

                          children: [

                            /// IMAGE
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(12),
                              child: Image.network(
                                "https://picsum.photos/200",
                                width: 90,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),

                            const SizedBox(width: 14),

                            /// DETAILS
                            Expanded(

                              child: Column(

                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  /// STATUS
                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                            horizontal: 10,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.purple
                                          .withOpacity(.1),
                                      borderRadius:
                                          BorderRadius.circular(
                                              20),
                                    ),
                                    child: Text(
                                      stage,
                                      style: const TextStyle(
                                        color: Colors.purple,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    receipt,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    children: [

                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey,
                                      ),

                                      const SizedBox(width: 6),

                                      Text(
                                        "${formatDate(pickup)} - ${formatDate(returnDate)}",
                                        style: const TextStyle(
                                            color: Colors.grey),
                                      ),

                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    "₹$amount",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),

                                ],
                              ),
                            ),

                            const Icon(Icons.more_vert)

                          ],
                        ),
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

  Widget buildTab(String title, int index) {

    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(

        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },

        child: Container(

          padding: const EdgeInsets.symmetric(vertical: 14),

          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),

          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.purple : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}