import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../services/tenant_config.dart';

class CreditHistoryScreen extends StatelessWidget {

  final String mobileNumber;

  const CreditHistoryScreen({
    super.key,
    required this.mobileNumber,
  });

  Future<DocumentSnapshot?> fetchCreditDoc() async {

    final query =
        await FirebaseFirestore.instance
            .collection("products")
            .doc(TenantConfig.branchCode)
            .collection("creditNotes")
            .where(
              "mobileNumber",
              isEqualTo: mobileNumber,
            )
            .limit(1)
            .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF7F8FA),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
            Colors.transparent,

        centerTitle: true,

        iconTheme:
            const IconThemeData(
          color: Colors.black,
        ),

        title: const Text(

          "Wallet History",

          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: FutureBuilder<DocumentSnapshot?>(
        future: fetchCreditDoc(),

        builder: (context, creditSnap) {

          /* ================= LOADING ================= */

          if (creditSnap.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          /* ================= EMPTY ================= */

          if (!creditSnap.hasData ||
              creditSnap.data == null) {

            return const Center(

              child: Text(

                "No wallet history found",

                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            );
          }

          final creditDoc =
              creditSnap.data!;

          final creditData =
              creditDoc.data()
                  as Map<String, dynamic>;

          return Column(

            children: [

              /* =====================================================
                 COMPACT PREMIUM WALLET CARD
              ===================================================== */

              Container(

                margin:
                    const EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  14,
                ),

                padding:
                    const EdgeInsets.all(18),

                decoration: BoxDecoration(

                  gradient:
                      const LinearGradient(

                    begin:
                        Alignment.topLeft,

                    end:
                        Alignment.bottomRight,

                    colors: [

                      Color(0xFFFFF9EC),

                      Color(0xFFFFF2D8),

                      Color(0xFFFDE7B0),
                    ],
                  ),

                  borderRadius:
                      BorderRadius.circular(
                          28),

                  border: Border.all(
                    color:
                        const Color(
                            0xFFF4D58D),
                    width: 1,
                  ),

                  boxShadow: [

                    BoxShadow(

                      blurRadius: 14,

                      color:
                          const Color(
                                  0xFFE6C26A)
                              .withOpacity(
                                  .18),

                      offset:
                          const Offset(
                              0, 8),
                    )
                  ],
                ),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    /* ================= TOP ================= */

                    Row(

                      children: [

                        Container(

                          padding:
                              const EdgeInsets
                                  .all(10),

                          decoration:
                              BoxDecoration(

                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                                        16),
                          ),

                          child: const Icon(

                            Icons
                                .account_balance_wallet_rounded,

                            color:
                                Color(
                                    0xFFC69214),

                            size: 22,
                          ),
                        ),

                        const Spacer(),

                        Container(

                          padding:
                              const EdgeInsets
                                  .symmetric(

                            horizontal: 12,
                            vertical: 6,
                          ),

                          decoration:
                              BoxDecoration(

                            color: Colors
                                .green
                                .withOpacity(
                                    .10),

                            borderRadius:
                                BorderRadius
                                    .circular(
                                        24),
                          ),

                          child:
                              const Row(

                            children: [

                              Icon(

                                Icons
                                    .verified_rounded,

                                size: 13,

                                color: Colors
                                    .green,
                              ),

                              SizedBox(
                                  width: 5),

                              Text(

                                "ACTIVE",

                                style:
                                    TextStyle(

                                  color: Colors
                                      .green,

                                  fontSize: 10,

                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 18),

                    /* ================= LABEL ================= */

                    const Text(

                      "Wallet Balance",

                      style: TextStyle(

                        color:
                            Color(0xFF8B6A22),

                        fontSize: 13,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                        height: 6),

                    /* ================= AMOUNT ================= */

                    Text(

                      "₹${creditData["Balance"] ?? 0}",

                      style:
                          const TextStyle(

                        color:
                            Color(0xFF1F2937),

                        fontSize: 34,

                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                        height: 16),

                    /* ================= MOBILE ================= */

                    Container(

                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),

                      decoration:
                          BoxDecoration(

                        color: Colors.white
                            .withOpacity(.70),

                        borderRadius:
                            BorderRadius
                                .circular(
                                    14),
                      ),

                      child: Row(

                        children: [

                          const Icon(

                            Icons.phone_rounded,

                            size: 15,

                            color:
                                Color(
                                    0xFF8B6A22),
                          ),

                          const SizedBox(
                              width: 8),

                          Expanded(

                            child: Text(

                              mobileNumber,

                              overflow:
                                  TextOverflow
                                      .ellipsis,

                              style:
                                  const TextStyle(

                                color:
                                    Color(
                                        0xFF6B4F16),

                                fontSize: 13,

                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              /* =====================================================
                 HISTORY LIST
              ===================================================== */

              Expanded(

                child:
                    StreamBuilder<
                        QuerySnapshot>(

                  stream:
                      FirebaseFirestore
                          .instance
                          .collection(
                              "products")
                          .doc(
                            TenantConfig
                                .branchCode,
                          )
                          .collection(
                              "creditNotes")
                          .doc(
                              creditDoc.id)
                          .collection(
                              "history")
                          .orderBy(
                            "createdAt",
                            descending:
                                true,
                          )
                          .snapshots(),

                  builder:
                      (context, snapshot) {

                    if (!snapshot
                        .hasData) {

                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    final docs =
                        snapshot
                            .data!.docs;

                    if (docs.isEmpty) {

                      return const Center(

                        child: Text(

                          "No wallet transactions",

                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(

                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 16,
                      ),

                      itemCount:
                          docs.length,

                      itemBuilder:
                          (context,
                              index) {

                        final data =
                            docs[index]
                                    .data()
                                as Map<
                                    String,
                                    dynamic>;

                        final isAdd =
                            data["type"] ==
                                "ADD";

                        final Timestamp? ts =
                            data[
                                "createdAt"];

                        String formattedDate =
                            "-";

                        if (ts != null) {

                          formattedDate =
                              DateFormat(
                            "dd MMM yyyy • hh:mm a",
                          ).format(
                            ts.toDate(),
                          );
                        }

                        return Container(

                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 16,
                          ),

                          padding:
                              const EdgeInsets
                                  .all(18),

                          decoration:
                              BoxDecoration(

                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                                        24),

                            boxShadow: [

                              BoxShadow(

                                blurRadius:
                                    14,

                                color: Colors
                                    .black
                                    .withOpacity(
                                        .05),

                                offset:
                                    const Offset(
                                        0, 6),
                              )
                            ],
                          ),

                          child: Row(

                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              /* ================= ICON ================= */

                              Container(

                                height: 58,
                                width: 58,

                                decoration:
                                    BoxDecoration(

                                  gradient:
                                      LinearGradient(

                                    colors:
                                        isAdd

                                            ? [

                                                const Color(
                                                    0xFF7DDC92),

                                                const Color(
                                                    0xFF22C55E),
                                              ]

                                            : [

                                                const Color(
                                                    0xFFFF9B9B),

                                                const Color(
                                                    0xFFEF4444),
                                              ],
                                  ),

                                  shape:
                                      BoxShape
                                          .circle,
                                ),

                                child: Icon(

                                  isAdd

                                      ? Icons
                                          .south_rounded

                                      : Icons
                                          .north_rounded,

                                  color: Colors
                                      .white,
                                ),
                              ),

                              const SizedBox(
                                  width: 16),

                              /* ================= DETAILS ================= */

                              Expanded(

                                child:
                                    Column(

                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    /* ================= TOP ================= */

                                    Row(

                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [

                                        Expanded(

                                          child:
                                              Text(

                                            isAdd

                                                ? "Credit Added"

                                                : "Credit Used",

                                            maxLines:
                                                1,

                                            overflow:
                                                TextOverflow
                                                    .ellipsis,

                                            style:
                                                const TextStyle(

                                              fontWeight:
                                                  FontWeight.bold,

                                              fontSize:
                                                  16,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                10),

                                        Flexible(

                                          child:
                                              Text(

                                            "${isAdd ? "+" : "-"} ₹${data["amount"]}",

                                            maxLines:
                                                1,

                                            overflow:
                                                TextOverflow.ellipsis,

                                            textAlign:
                                                TextAlign.end,

                                            style:
                                                TextStyle(

                                              color:
                                                  isAdd

                                                      ? const Color(
                                                          0xFF16A34A)

                                                      : const Color(
                                                          0xFFDC2626),

                                              fontWeight:
                                                  FontWeight.bold,

                                              fontSize:
                                                  18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                        height:
                                            6),

                                    /* ================= DATE ================= */

                                    Text(

                                      formattedDate,

                                      style:
                                          TextStyle(

                                        color: Colors
                                            .grey
                                            .shade500,

                                        fontSize:
                                            12,
                                      ),
                                    ),

                                    const SizedBox(
                                        height:
                                            10),

                                    /* ================= NOTE ================= */

                                    SizedBox(

                                      width:
                                          double.infinity,

                                      child: Text(

                                        data["note"] ??
                                            "",

                                        maxLines:
                                            2,

                                        overflow:
                                            TextOverflow
                                                .ellipsis,

                                        style:
                                            TextStyle(

                                          color: Colors
                                              .grey
                                              .shade600,

                                          fontSize:
                                              12,

                                          fontWeight:
                                              FontWeight
                                                  .w500,

                                          height:
                                              1.3,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                        height:
                                            14),

                                    /* ================= TAGS ================= */

                                    Wrap(

                                      spacing:
                                          10,

                                      runSpacing:
                                          10,

                                      children: [

                                        /* ================= BALANCE ================= */

                                        Container(

                                          padding:
                                              const EdgeInsets.symmetric(

                                            horizontal:
                                                10,

                                            vertical:
                                                6,
                                          ),

                                          decoration:
                                              BoxDecoration(

                                            color:
                                                const Color(
                                                    0xFFF3F4F6),

                                            borderRadius:
                                                BorderRadius.circular(
                                                    14),
                                          ),

                                          child:
                                              Text(

                                            "Balance ₹${data["newBalance"] ?? 0}",

                                            overflow:
                                                TextOverflow.ellipsis,

                                            style:
                                                const TextStyle(

                                              fontSize:
                                                  12,

                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          ),
                                        ),

                                        /* ================= RECEIPT ================= */

                                        if (data["receiptNo"] !=
                                                null &&
                                            data["receiptNo"]
                                                .toString()
                                                .isNotEmpty)

                                          Container(

                                            constraints:
                                                const BoxConstraints(
                                              maxWidth:
                                                  140,
                                            ),

                                            padding:
                                                const EdgeInsets.symmetric(

                                              horizontal:
                                                  10,

                                              vertical:
                                                  6,
                                            ),

                                            decoration:
                                                BoxDecoration(

                                              color:
                                                  const Color(
                                                      0xFFEFF6FF),

                                              borderRadius:
                                                  BorderRadius.circular(
                                                      14),
                                            ),

                                            child:
                                                Text(

                                              data["receiptNo"],

                                              maxLines:
                                                  1,

                                              overflow:
                                                  TextOverflow.ellipsis,

                                              style:
                                                  const TextStyle(

                                                fontSize:
                                                    11,

                                                fontWeight:
                                                    FontWeight.w600,

                                                color:
                                                    Color(
                                                        0xFF2563EB),
                                              ),
                                            ),
                                          )
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}