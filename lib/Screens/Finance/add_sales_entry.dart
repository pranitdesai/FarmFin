import 'package:desaifarms/Utils/app_color.dart';
import 'package:desaifarms/custom_widget/snack_bar.dart';
import 'package:desaifarms/custom_widget/textfield.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

class AddSalePage extends StatefulWidget {
  final String cropKey;
  final String year;
  final String plotName;
  final String icon;

  const AddSalePage({
    super.key,
    required this.cropKey,
    required this.year,
    required this.plotName,
    required this.icon,
  });

  @override
  State<AddSalePage> createState() => _AddSalePageState();
}

class _AddSalePageState extends State<AddSalePage> {
  final merchantController = TextEditingController();
  final rateController = TextEditingController();
  final dateController = TextEditingController();
  final weightController = TextEditingController();
  final qtyController = TextEditingController();
  final totalWeightController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  late final DatabaseReference dbRef;

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    dbRef = FirebaseDatabase.instance
        .ref("Sales_Ledger/${widget.cropKey}/${widget.year}/${widget.plotName}/sales_entries");

    weightController.addListener(calculateTotalWeight);
    qtyController.addListener(calculateTotalWeight);
  }

  void calculateTotalWeight() {
    final double weight = double.tryParse(weightController.text.trim()) ?? 0.0;
    final int qty = int.tryParse(qtyController.text.trim()) ?? 0;
    final double total = weight * qty;
    totalWeightController.text = total == 0 ? "" : total.toStringAsFixed(2);
  }

  Future<void> saveSale() async {
    if (formKey.currentState!.validate()) {
      final saleData = {
        'merchantName': merchantController.text.trim(),
        'rate': rateController.text.trim(),
        'date': dateController.text.trim(),
        'boxWeight': weightController.text.trim(),
        'quantity': qtyController.text.trim(),
        'totalWeight': totalWeightController.text.trim(),
      };

      try {
        await dbRef.push().set(saleData);
        if (mounted) {
          Navigator.pop(context);
          CustomSnackBar.show(
            context,
            message: "Sale entry added successfully",
            fromTop: false,
            type: SnackBarType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Error: $e',
            fromTop: false,
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: _customAppBar(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Year + Crop Icon Row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _contextCard(widget.year, Icons.calendar_month, "Year"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 65,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0F2FE), width: 1),
                      ),
                      child: Center(
                        child: SvgPicture.asset(widget.icon, height: 32, width: 32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              /// Plot name
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0F2FE), width: 1),
                ),
                child: Text(
                  widget.plotName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              /// Merchant Info Section
              _sectionTitle("Merchant Information"),
              const SizedBox(height: 14),

              CustomTextField(
                hintText: "Merchant Name",
                controller: merchantController,
                keyboardType: TextInputType.text,
                prefixIcon: Icons.store_rounded,
                validator: (value) =>
                value == null || value.isEmpty ? "Enter merchant name" : null,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                hintText: "Rate (₹/kg)",
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.currency_rupee_rounded,
                validator: (value) =>
                value == null || value.isEmpty ? "Enter rate" : null,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 14),

              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    selectedDate = picked;
                    dateController.text =
                        DateFormat('dd MMM yyyy').format(picked);
                    setState(() {});
                  }
                },
                child: AbsorbPointer(
                  child: CustomTextField(
                    hintText: "Date of Sale",
                    controller: dateController,
                    keyboardType: TextInputType.datetime,
                    prefixIcon: Icons.calendar_today_rounded,
                    validator: (value) =>
                    value == null || value.isEmpty ? "Select date" : null,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              /// Quantity & Weight Section
              _sectionTitle("Quantity & Weight"),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      hintText: "Weight/Box (kg)",
                      controller: weightController,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.scale_rounded,
                      validator: (value) =>
                      value == null || value.isEmpty ? "Enter weight" : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      hintText: "No. of Boxes",
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.inventory_2_rounded,
                      validator: (value) =>
                      value == null || value.isEmpty ? "Enter quantity" : null,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              ValueListenableBuilder<TextEditingValue>(
                valueListenable: totalWeightController,
                builder: (context, value, _) {
                  final displayText =
                  value.text.isEmpty ? "0 kg" : "${value.text} kg";
                  return Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColor.green200, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedTv02,
                          color: AppColor.green600,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Weight",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              displayText,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColor.green700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              /// Save & Cancel buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.green600,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: saveSale,
                      child: Text(
                        "Save Sale",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 56,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedDiscountTag02,
              color: AppColor.green600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Add Sales Entry",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Record a new sale transaction",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextCard(String text, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F2FE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 32,
          decoration: BoxDecoration(
            color: AppColor.green500,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
