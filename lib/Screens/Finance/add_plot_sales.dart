import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../Utils/app_color.dart';
import '../Finance/add_sales_entry.dart';

class AddPlotSales extends StatefulWidget {
  final String plotName, year, crop, icon;
  const AddPlotSales({
    super.key,
    required this.plotName,
    required this.year,
    required this.crop,
    required this.icon,
  });

  @override
  State<AddPlotSales> createState() => _AddPlotSalesState();
}

class _AddPlotSalesState extends State<AddPlotSales> {
  late DatabaseReference ref;
  double globalTurnoverVar = -1;

  @override
  void initState() {
    ref = FirebaseDatabase.instance.ref(
      'Sales_Ledger/${widget.crop}/${widget.year}/${widget.plotName}',
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.green50,
      floatingActionButton: _addPlotSalesFAB(),
      body: SingleChildScrollView(
        child:
        Column(
          children: [
            _customAppBar(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder(
                stream: ref.onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error loading data",
                        style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                    return Center(
                      child: Text(
                        "No data available",
                        style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
                      ),
                    );
                  }

                  // ✅ Safe parsing
                  final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                  final salesEntries = Map<String, dynamic>.from(data['sales_entries'] ?? {});
                  final salesList = salesEntries.entries.map((entry) {
                    final sale = Map<String, dynamic>.from(entry.value);
                    sale['id'] = entry.key;
                    return sale;
                  }).toList();

                  // ✅ Fetch main merchant and all entry merchants
                  final mainMerchant = data['merchantName']?.toString().trim() ?? '';
                  final List<String> saleMerchants = [];

                  salesEntries.forEach((key, value) {
                    final entry = Map<String, dynamic>.from(value);
                    final merchant = entry['merchantName']?.toString().trim() ?? '';
                    if (merchant.isNotEmpty) saleMerchants.add(merchant);
                  });

                  // ✅ Combine and filter duplicates/empty
                  final allMerchants = {
                    if (mainMerchant.isNotEmpty) mainMerchant,
                    ...saleMerchants
                  }.toList();

                  debugPrint("All Merchant Names: $allMerchants");

                  // ✅ Calculate total weight, avg rate, turnover
                  double totalWeight = 0;
                  double totalRate = 0;
                  int rateCount = 0;

                  for (var entry in salesList) {
                    double weight =
                        double.tryParse(entry['totalWeight']?.toString() ?? '0') ?? 0;
                    double rate = double.tryParse(entry['rate']?.toString() ?? '0') ??
                        double.tryParse(data['rate']?.toString() ?? '0') ??
                        0;

                    totalWeight += weight;
                    if (rate > 0) {
                      totalRate += rate;
                      rateCount++;
                    }
                  }

                  double avgRate = rateCount > 0 ? totalRate / rateCount : 0;
                  double totalTurnover = totalWeight * avgRate;
                  globalTurnoverVar = totalTurnover;

                  return Column(
                    children: [
                      yearCard(widget.year),
                      const SizedBox(height: 8),
                      _plotName(),
                      const SizedBox(height: 8),

                      // ✅ Merchant Names (cleanly stacked)
                      if (salesList.isNotEmpty) ...[
                        InfoCard(
                          title: "Merchant Names",
                          // Combine with commas and line breaks
                          value: allMerchants.join(", "),
                          format: NumberFormat.decimalPattern('en_IN'),
                          isIconPath: false,
                          isNumeric: false,
                        ),
                        InfoCard(
                          title: "Avg Rate / KG",
                          value: avgRate,
                          format: NumberFormat.decimalPattern('en_IN'),
                          isIconPath: false,
                          isNumeric: true,
                        ),
                      ],

                      // ✅ Sales Table
                      SalesTable(
                          crop: widget.crop,
                          year: widget.year,
                          plotName: widget.plotName,
                        ),

                      // ✅ Total info cards
                      if (salesList.isNotEmpty) ...[
                        InfoCard(
                          title: 'Total Weight',
                          value: totalWeight,
                          iconPath: HugeIcons.strokeRoundedWeightScale01,
                          isWeight: true,
                          format: NumberFormat.decimalPattern('en_IN'),
                          isIconPath: true,
                          isNumeric: true,
                        ),
                        InfoCard(
                          title: "Total Turnover",
                          value: totalTurnover,
                          format: NumberFormat.decimalPattern('en_IN'),
                          isIconPath: true,
                          isNumeric: true,
                          iconPath: HugeIcons.strokeRoundedMoney04,
                        ),
                        const SizedBox(height: 100),
                      ]
                    ],
                  );
                },
              )

            ),
          ],
        ),
      ),
    );
  }

  Widget _addPlotSalesFAB(){
    return FloatingActionButton.extended(
      backgroundColor: AppColor.green500,
      elevation: 4,
      onPressed: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => AddSalePage(
              cropKey: widget.crop,
              year: widget.year,
              plotName: widget.plotName,
              icon: widget.icon,
            )
        ));
      },
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        "Add Sales Entry",
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget yearCard(String year) {
    return Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8),
        child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar02,
                color: Colors.black,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                  year,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Colors.black,
                  )
              ),
            ]
        )
    );
  }

  Widget _plotName(){
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: AppColor.green100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SvgPicture.asset(widget.icon, height: 36, width: 36),
          const SizedBox(width: 16),
          Text(
            widget.plotName,
            style: GoogleFonts.poppins(fontSize: 20, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _customAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedDiscountTag02,
            color: Colors.black,
            size: 30,
          ),
          const SizedBox(width: 12),
          Text(
            "Add Sales Entry",
            style: GoogleFonts.poppins(
              fontSize: 24,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SalesTable extends StatefulWidget {
  final String crop;
  final String year;
  final String plotName;

  const SalesTable({
    super.key,
    required this.crop,
    required this.year,
    required this.plotName,
  });

  @override
  State<SalesTable> createState() => _SalesTableState();
}

class _SalesTableState extends State<SalesTable> {
  late DatabaseReference ref;

  @override
  void initState() {
    super.initState();
    ref = FirebaseDatabase.instance.ref(
      'Sales_Ledger/${widget.crop}/${widget.year}/${widget.plotName}/sales_entries',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Center(
            child: Text(
                "No sales data found",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                )
            ),
          );
        }

        final Map<dynamic, dynamic> entries =
        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final salesList = entries.values.map((e) => Map<String, dynamic>.from(e)).toList();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  _buildHeader(),
                  ...salesList.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> data = entry.value;
                    return _buildRow(data, isEven: index.isEven);
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColor.green500,
      child: Row(
        children: [
          _buildCell("Date Of\nSale", isHeader: true),
          _buildCell("Weight/\nBox", isHeader: true),
          _buildCell("Qty Of\nBoxes", isHeader: true),
          _buildCell("Rate/\nKg", isHeader: true),
          _buildCell("Total\nWeight", isHeader: true),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> data, {bool isEven = false}) {
    return Container(
      color: isEven ? Colors.grey.shade100 : Colors.white,
      child: Row(
        children: [
          _buildCell(data['date'] ?? ''),
          _buildCell(data['boxWeight'] ?? ''),
          _buildCell(data['quantity'] ?? ''),
          _buildCell(data["rate"]??''),
          _buildCell('${data['totalWeight'] ?? ''} kg'),
        ],
      ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false}) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
              color: isHeader ? Colors.white.withOpacity(0.4) : Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: isHeader?13:10,
          color: isHeader ? Colors.white : Colors.black87,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}


class InfoCard extends StatelessWidget {
  final String title;
  final dynamic value;
  final bool isNumeric;
  final bool isWeight;
  final bool isIconPath;
  final List<List<dynamic>> iconPath;
  final NumberFormat format;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.isNumeric,
    required this.format,
    this.isWeight = false,
    this.isIconPath = false,
    this.iconPath = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isIconPath) ...[
            HugeIcon(icon: iconPath),
            const SizedBox(width: 12),
          ],

          // ✅ Expanded ensures proper width limit for scrolling text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                // ✅ Wrap text in a horizontally scrollable container with max height
                SizedBox(
                  height: 24, // fixed height so scroll works properly
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isNumeric
                            ? (isWeight
                            ? '${format.format(value)} kg'
                            : '₹${format.format(value)}')
                            : value.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
