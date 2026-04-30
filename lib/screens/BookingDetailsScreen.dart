import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDetailsScreen extends StatelessWidget {

  final Map<String,dynamic> booking;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
  });

  String formatDate(DateTime date){
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context){

    final products = booking["products"] ?? [];

    final pickup =
        (booking["pickupDate"] as Timestamp).toDate();

    final returnDate =
        (booking["returnDate"] as Timestamp).toDate();

    return Scaffold(

      backgroundColor: const Color(0xFFF6F6F8),

      appBar: AppBar(
        title: const Text("Booking Details"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: ListView(

        padding: const EdgeInsets.all(20),

        children: [

          /// RECEIPT HEADER
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      booking["receiptNumber"],
                      style: const TextStyle(
                        fontSize:18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal:10,vertical:4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking["bookingStage"],
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  ],
                ),

                const SizedBox(height:12),

                Row(
                  children: [

                    const Icon(Icons.calendar_today,size:16,color: Colors.grey),

                    const SizedBox(width:6),

                    Text(
                      "${formatDate(pickup)}  →  ${formatDate(returnDate)}",
                      style: const TextStyle(color: Colors.grey),
                    )
                  ],
                )

              ],
            ),
          ),

          const SizedBox(height:20),

          /// PRODUCTS
          const Text(
            "Products",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize:16,
            ),
          ),

          const SizedBox(height:10),

          ...products.map((p){

            return Container(

              margin: const EdgeInsets.only(bottom:12),

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Row(

                children: [

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      p["imageUrl"],
                      width:60,
                      height:80,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(width:12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          p["productName"],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height:4),

                        Text(
                          "Code: ${p["productCode"]}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize:13,
                          ),
                        ),

                        const SizedBox(height:4),

                        Text(
                          "Qty: ${p["quantity"]}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize:13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    "₹${p["price"]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )

                ],
              ),
            );

          }),

          const SizedBox(height:20),

          /// PAYMENT SUMMARY
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Payment Summary",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:16,
                  ),
                ),

                const SizedBox(height:12),

                infoRow("Total Amount","₹${booking["totalAmount"]}"),
                infoRow("Amount Paid","₹${booking["amountPaid"]}"),
                infoRow("Balance","₹${booking["balance"]}"),

                const Divider(),

                infoRow("Rent","₹${booking["finalRent"]}"),
                infoRow("Deposit","₹${booking["finalDeposit"]}"),

              ],
            ),
          ),

          const SizedBox(height:20),

          /// NOTE
          if((booking["specialNote"] ?? "").toString().isNotEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Special Note",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height:6),

                Text(booking["specialNote"])

              ],
            ),
          ),

          const SizedBox(height:30),

        ],
      ),
    );
  }

  Widget infoRow(String label,String value){

    return Padding(
      padding: const EdgeInsets.symmetric(vertical:4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,style: const TextStyle(color: Colors.grey)),
          Text(value,style: const TextStyle(fontWeight: FontWeight.bold))
        ],
      ),
    );
  }
}