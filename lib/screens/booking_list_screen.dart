import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'BookingDetailsScreen.dart';
import '../services/tenant_config.dart';
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
  Widget build(BuildContext context) {

    final phone = FirebaseAuth.instance.currentUser!.phoneNumber!;
    final cleanPhone = phone.replaceAll("+91", "");

    final stream = FirebaseFirestore.instance
    .collection("products")
    .doc(TenantConfig.branchCode)
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
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black),
        ),
      ),

      body: Column(
        children: [

          const SizedBox(height:20),

          /// TAB BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  buildTab("Upcoming",0),
                  buildTab("Current",1),
                  buildTab("Past",2),
                ],
              ),
            ),
          ),

          const SizedBox(height:20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(

              stream: stream,

              builder:(context,snapshot){

                if(!snapshot.hasData){
                  return const Center(child:CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final filteredDocs = docs.where((doc){

                  final data = doc.data() as Map<String,dynamic>;
                  final stage = data["bookingStage"] ?? "";

                  return matchStage(stage);

                }).toList();

                if(filteredDocs.isEmpty){
                  return const Center(child:Text("No bookings found"));
                }

                return ListView.builder(

                  padding: const EdgeInsets.all(20),

                  itemCount: filteredDocs.length,

                  itemBuilder:(context,index){

                    final data =
                        filteredDocs[index].data() as Map<String,dynamic>;

                    final receipt = data["receiptNumber"];
                    final stage = data["bookingStage"];
                    final amount = data["totalAmount"];

                    final pickup =
                        (data["pickupDate"] as Timestamp).toDate();

                    final returnDate =
                        (data["returnDate"] as Timestamp).toDate();

                    final products = data["products"] ?? [];

                    String image = "";
                    if(products.isNotEmpty){
                      image = products[0]["imageUrl"] ?? "";
                    }

                    List codes =
                        products.map((p)=>p["productCode"]).toList();

                    return GestureDetector(

                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingDetailsScreen(booking: data),
                          ),
                        );
                      },

                      child: Container(

                        margin: const EdgeInsets.only(bottom:18),
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow:[
                            BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius:16,
                            )
                          ],
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[

                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: image.isNotEmpty
                                      ? Image.network(
                                    image,
                                    width:80,
                                    height:110,
                                    fit:BoxFit.cover,
                                  )
                                      : Container(
                                    width:80,
                                    height:110,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image),
                                  ),
                                ),

                                const SizedBox(width:14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children:[

                                      /// STAGE BADGE
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:10,vertical:4),
                                        decoration: BoxDecoration(
                                          color: stageColor(stage).withOpacity(.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          stage,
                                          style: TextStyle(
                                            color: stageColor(stage),
                                            fontWeight: FontWeight.w600,
                                            fontSize:12,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height:6),

                                      Text(
                                        receipt,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize:16),
                                      ),

                                      const SizedBox(height:4),

                                      Text(
                                        "${products.length} items booked",
                                        style: const TextStyle(
                                            color: Colors.grey,fontSize:13),
                                      ),

                                    ],
                                  ),
                                )
                              ],
                            ),

                            const SizedBox(height:14),

                            /// PRODUCT CODES
                            Wrap(
                              spacing:6,
                              runSpacing:6,
                              children:[

                                ...codes.take(4).map((code){

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal:10,vertical:4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      code.toString(),
                                      style: const TextStyle(
                                          fontSize:12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  );

                                }),

                                if(codes.length > 4)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal:10,vertical:4),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "+${codes.length - 4}",
                                      style: const TextStyle(
                                        fontSize:12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  )

                              ],
                            ),

                            const SizedBox(height:12),

                            const Divider(),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children:[

                                Row(
                                  children:[
                                    const Icon(Icons.calendar_today,
                                        size:16,color: Colors.grey),
                                    const SizedBox(width:6),
                                    Text(
                                      "${formatDate(pickup)} - ${formatDate(returnDate)}",
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),

                                Text(
                                  "₹$amount",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:16,
                                    color: Colors.purple,
                                  ),
                                )

                              ],
                            )

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
                color: isSelected ? Colors.purple : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}