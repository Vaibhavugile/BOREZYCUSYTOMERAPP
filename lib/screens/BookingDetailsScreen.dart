import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/tenant_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import 'package:cached_network_image/cached_network_image.dart';
class BookingDetailsScreen extends StatelessWidget {
final Map<String, dynamic> booking;

const BookingDetailsScreen({
super.key,
required this.booking,
});

String formatDate(DateTime date) {
return "${date.day}/${date.month}/${date.year}";
}
String formatDateTime(DateTime date) {

  final hour = date.hour > 12
      ? date.hour - 12
      : date.hour;

  final amPm = date.hour >= 12 ? "PM" : "AM";

  return "${date.day}/${date.month}/${date.year} "
      "${hour.toString().padLeft(2, '0')}:"
      "${date.minute.toString().padLeft(2, '0')} "
      "$amPm";
}

@override
Widget build(BuildContext context) {
final products = booking["products"] ?? [];
final payment = booking;


final pickup = (booking["pickupDate"] as Timestamp).toDate();
final returnDate = (booking["returnDate"] as Timestamp).toDate();

return Scaffold(
  backgroundColor: AppColors.background,

  appBar: AppBar(
    title: const Text("Booking Details"),
    backgroundColor: Colors.white,
    elevation: 0,
  ),

  bottomNavigationBar: _bottomActions(),
body: RefreshIndicator(
  onRefresh: () async {

    await Future.delayed(
      const Duration(milliseconds: 500),
    );
  },

  child: ListView(
    padding: const EdgeInsets.all(20),
    children: [

      _receiptHeader(pickup, returnDate),

      const SizedBox(height:20),

      _customerCard(),

      const SizedBox(height:20),

      _productSection(products),

      const SizedBox(height:20),

      _paymentDetails(payment),

      const SizedBox(height:20),

      _paymentHistory(),

      const SizedBox(height:20),

      _accountSummary(payment),

      const SizedBox(height:20),

      if((booking["specialNote"] ?? "").toString().isNotEmpty)
        _noteSection(),

      const SizedBox(height:20),

_attachmentsSection(context),
      const SizedBox(height:20),


      _helpSection(),

      const SizedBox(height:40)

    ],
  ),
  ),
);


}

/// RECEIPT HEADER
Widget _receiptHeader(DateTime pickup, DateTime returnDate) {


Color stageColor;

switch(booking["bookingStage"]){
  case "successful":
    stageColor = Colors.green;
    break;
  case "pickupPending":
    stageColor = Colors.orange;
    break;
  case "returnPending":
    stageColor = Colors.blue;
    break;
  default:
    stageColor = AppColors.primary;
}

return Container(
  padding: const EdgeInsets.all(22),
  decoration: BoxDecoration(
    gradient: AppGradients.primaryGradient,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: AppColors.textPrimary.withOpacity(.15),
        blurRadius: 20,
      )
    ],
  ),

  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Receipt Number",
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height:4),

          Text(
            booking["receiptNumber"],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    ),

    const SizedBox(width:10),

    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        booking["bookingStage"].toString().toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    )

  ],
),

      const SizedBox(height:16),

      Row(
        children: [

          const Icon(Icons.calendar_today,
              color: Colors.white70, size:16),

          const SizedBox(width:8),

          Text(
            "${formatDate(pickup)} → ${formatDate(returnDate)}",
            style: const TextStyle(color: Colors.white),
          )

        ],
      )

    ],
  ),
);


}

/// CUSTOMER CARD
Widget _customerCard(){


return _cardWrapper(

  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const _sectionTitle("Customer Details", Icons.person),

      const SizedBox(height:14),
_infoRow("Name", booking["clientName"]),
_infoRow("Contact", booking["contact"]),
_infoRow("Customer By", booking["customerBy"]),
_infoRow("Receipt By", booking["receiptBy"]),

if((booking["alterations"] ?? "").toString().isNotEmpty)
  _infoRow(
    "Alterations",
    booking["alterations"],
  ),

if(booking["createdAt"] != null)
  _infoRow(
    "Created At",
    formatDateTime(
      (booking["createdAt"] as Timestamp).toDate(),
    ),
  ),
    ],
  ),
);


}

/// PRODUCTS
Widget _productSection(List products){


return _cardWrapper(

  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const _sectionTitle("Products", Icons.checkroom),

      const SizedBox(height:14),

      ...products.map((p){

        return Container(

          margin: const EdgeInsets.only(bottom:14),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: AppColors.textPrimary.withOpacity(.08),
              )
            ],
          ),

          child: ListTile(

            leading: ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: p["imageUrl"] != null && p["imageUrl"].toString().isNotEmpty
      ? CachedNetworkImage(
  imageUrl: p["imageUrl"],
  width: 60,
  height: 80,
  fit: BoxFit.cover,
  errorWidget: (context, url, error) {
    return Container(
      width: 60,
      height: 80,
      color: AppColors.primaryLight,
      child: const Icon(Icons.image),
    );
  },
)
      : Container(
          width: 60,
          height: 80,
          color: AppColors.textSecondary,
          child: const Icon(Icons.image, color: AppColors.textSecondary),
        ),
),

            title: Text(
              p["productName"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Code: ${p["productCode"]}"),
                Text("Qty: ${p["quantity"]}")
              ],
            ),

            trailing: Text(
              "₹${p["price"]}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize:16,
              ),
            ),

          ),

        );

      })

    ],
  ),
);


}

/// PAYMENT DETAILS
Widget _paymentDetails(Map payment){


return _cardWrapper(

  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const _sectionTitle("Payment Details", Icons.payments),

      const SizedBox(height:14),

      _infoRow("Grand Total Rent","₹${payment["grandTotalRent"]}"),
      _infoRow("Discount on Rent","₹${payment["discountOnRent"]}"),
      _infoRow("Final Rent","₹${payment["finalRent"]}"),

      const Divider(),

      _infoRow("Grand Total Deposit","₹${payment["grandTotalDeposit"]}"),
      _infoRow("Final Deposit","₹${payment["finalDeposit"]}"),

      const Divider(),

      _infoRow("Amount Paid","₹${payment["amountPaid"]}",color: Colors.green),
      _infoRow("Balance","₹${payment["balance"]}",color: Colors.red),

    ],
  ),
);


}

/// PAYMENT HISTORY
Widget _paymentHistory(){


return FutureBuilder(

future: FirebaseFirestore.instance
    .collection("products")
    .doc(TenantConfig.branchCode)
    .collection("payments")
    .doc(booking["receiptNumber"])
    .collection("transactions")
    .orderBy("createdAt", descending: true)
    .get(),

  builder:(context,snapshot){

    if(!snapshot.hasData){
      return const Center(child:CircularProgressIndicator());
    }

    final docs = snapshot.data!.docs;

    if(docs.isEmpty){
      return const Text("No payments recorded");
    }

    return _cardWrapper(

      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[

          const _sectionTitle("Payment History", Icons.history),

          const SizedBox(height:14),

          ...docs.map((doc){

            final data = doc.data() as Map<String,dynamic>;
            bool isRefund = data["type"] == "depositReturn";

            return Container(

              margin: const EdgeInsets.only(bottom:12),

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(14),
              ),

              child: Row(

                children: [

                  CircleAvatar(
                    backgroundColor:
                    isRefund
                        ? Colors.red.withOpacity(.2)
                        : Colors.green.withOpacity(.2),
                    child: Icon(
                      isRefund ? Icons.undo : Icons.payments,
                      color: isRefund ? Colors.red : Colors.green,
                    ),
                  ),

                  const SizedBox(width:12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          isRefund
                              ? "Deposit Refunded"
                              : "Payment ${data["paymentNumber"]}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),

                        Text(data["mode"] ?? "")

                      ],
                    ),
                  ),

                  Text(
                    "₹${data["amount"]}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isRefund ? Colors.red : Colors.green,
                    ),
                  )

                ],
              ),

            );

          })

        ],
      ),
    );
  },
);


}

/// ACCOUNT SUMMARY
Widget _accountSummary(Map payment){


return _cardWrapper(

  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const _sectionTitle("Account Summary", Icons.account_balance),

      const SizedBox(height:14),

      _infoRow("Total Rent","₹${payment["finalRent"]}"),
      _infoRow("Rent Paid","₹${payment["rentCollected"]}"),
      _infoRow("Rent Pending","₹${payment["rentPending"]}"),

      const Divider(),

      _infoRow("Total Deposit","₹${payment["finalDeposit"]}"),
      _infoRow("Deposit Returned","₹${payment["depositReturned"]}"),
      _infoRow("Deposit With Us","₹${payment["depositWithYou"]}"),

    ],
  ),
);


}

Widget _noteSection(){


return _cardWrapper(

  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const _sectionTitle("Special Note", Icons.note),

      const SizedBox(height:8),

      Text(booking["specialNote"])

    ],
  ),
);


}
Widget _attachmentsSection( BuildContext context,){

  final attachments =
      booking["attachments"] ?? [];

  return _cardWrapper(

    Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        const _sectionTitle(
          "Attachments",
          Icons.attach_file,
        ),

        const SizedBox(height:14),

        if(attachments.isEmpty)

          const Text(
            "No attachments available",
          )

        else

          ...attachments.map<Widget>((item){

            final data =
                Map<String,dynamic>.from(item);

            final images =
                data["images"] ?? [];

            return Container(

              margin:
                  const EdgeInsets.only(
                      bottom:16),

              padding:
                  const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color:
                    AppColors.primaryLight,

                borderRadius:
                    BorderRadius.circular(
                        16),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    data["title"] ?? "",

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  if((data["note"] ?? "")
                      .toString()
                      .isNotEmpty)

                    Padding(
                      padding:
                          const EdgeInsets.only(
                              top:8),

                      child: Text(
                        data["note"],

                        style:
                            const TextStyle(
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ),

                  if(images.isNotEmpty)

                    Padding(
                      padding:
                          const EdgeInsets.only(
                              top:14),

                      child:
                          SingleChildScrollView(

                        scrollDirection:
                            Axis.horizontal,

                        child: Row(

                          children:
                              images.map<Widget>(
                            (img){

                              return Padding(

                                padding:
                                    const EdgeInsets
                                        .only(
                                            right:10),

                                child: GestureDetector(

                                  onTap: () {

                                    showDialog(

                                      context:
                                          context,

                                      builder: (_){

                                        return Dialog(

                                          backgroundColor:
                                              Colors
                                                  .black,

                                          child:
                                              InteractiveViewer(

                                            child:
                                                Image.network(
                                              img,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },

                                  child:
                                      ClipRRect(

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                14),

                                    child:
                                        CachedNetworkImage(

                                      imageUrl:
                                          img,

                                      width: 110,
                                      height: 140,

                                      fit:
                                          BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    )
                ],
              ),
            );

          }).toList()
      ],
    ),
  );
}

Widget _helpSection(){


return _cardWrapper(

  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const _sectionTitle("Need Help?", Icons.support_agent),

      const SizedBox(height:12),

      Row(
        children: [

          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.message),
              label: const Text("WhatsApp"),
              onPressed: (){
                launchUrl(
  Uri.parse("https://wa.me/${TenantConfig.supportPhone}")
);
              },
            ),
          ),

          const SizedBox(width:12),

          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text("Call"),
              onPressed: (){
                launchUrl(
  Uri.parse("tel:+${TenantConfig.supportPhone}")
);
              },
            ),
          ),

        ],
      )
  
    ],
  ),
);


}

Widget _bottomActions(){


return Container(
  padding: const EdgeInsets.all(16),
  color: Colors.white,

  child: Row(
    children: [

      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.support_agent),
          label: const Text("Contact"),
          onPressed: (){},
        ),
      ),

      const SizedBox(width:12),

      Expanded(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.shopping_bag),
          label: const Text("Book Again"),
          onPressed: (){},
        ),
      )

    ],
  ),
);


}

Widget _cardWrapper(Widget child){


return Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
  color: Colors.white,

  borderRadius: BorderRadius.circular(18),

  border: Border.all(
    color: AppColors.primaryLight,
  ),

  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(.04),
      blurRadius: 12,
    )
  ],
),
  child: child,
);


}

Widget _infoRow(String label,dynamic value,{Color? color}){


return Padding(
  padding: const EdgeInsets.only(bottom:10),

  child: Row(
    children: [

      Expanded(
        flex:4,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),

      Expanded(
        flex:6,
        child: Text(
          value?.toString() ?? "-",
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      )

    ],
  ),
);


}
}

class _sectionTitle extends StatelessWidget {

final String title;
final IconData icon;

const _sectionTitle(this.title,this.icon);

@override
Widget build(BuildContext context){


return Row(
  children: [

    Icon(icon,color: AppColors.primary),

    const SizedBox(width:8),

    Text(
      title,
      style: const TextStyle(
        fontSize:18,
        fontWeight: FontWeight.bold,
      ),
    )

  ],
);


}
}
