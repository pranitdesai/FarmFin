import 'package:desaifarms/Utils/app_color.dart';
import 'package:desaifarms/custom_widget/textfield.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../custom_widget/snack_bar.dart';
import 'add_plot_sales.dart';

class AddPlotDetailsScreen extends StatefulWidget {
  final String selectedYear, cropName, cropIcon, cropKey, cropSubtitle;
  const AddPlotDetailsScreen({super.key, required this.selectedYear, required this.cropName, required this.cropIcon, required this.cropKey, required this.cropSubtitle});

  @override
  State<AddPlotDetailsScreen> createState() => _AddPlotDetailsScreenState();
}

class _AddPlotDetailsScreenState extends State<AddPlotDetailsScreen> {
  late DatabaseReference dbRef;
  bool isLoading = true;
  List<String> plots = [];
  double totalWeight = 0;
  double totalTurnover = 0;
  TextEditingController plotNameController = TextEditingController();
  TextEditingController acreController = TextEditingController();
  TextEditingController gunthaController = TextEditingController();
  TextEditingController sapllingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    dbRef = FirebaseDatabase.instance.ref(
      'Sales_Ledger/${widget.cropKey}/${widget.selectedYear}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _AddCropFAB(

        plotNameController: plotNameController,
        acreController: acreController,
        gunthaController: gunthaController,
        sapllingController: sapllingController,
        cropKey: widget.cropKey,
        year: widget.selectedYear,
        cropName: widget.cropName,
        subtitle: widget.cropSubtitle,
        iconPath: widget.cropIcon,
      ),
      backgroundColor: AppColor.green50,
      body: Column(
        children: [
          _customAppBar(),
          Padding(
            padding: const EdgeInsets.only(top:16, left: 16, right: 16, bottom: 8),
            child: yearCard(widget.selectedYear),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: _cropName(),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: dbRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return _noDataCard('No plots found');
                }

                final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);
                final plots = data.keys.toList();

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      detailsCard(plots),
                      const SizedBox(height: 36),
                      const SizedBox(height: 36),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cropName(){
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SvgPicture.asset(widget.cropIcon, height: 28, width: 28),
            const SizedBox(width: 12),
            Text(
              widget.cropName,
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget yearCard(String year) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
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

  Widget _customAppBar() {
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
            icon: HugeIcons.strokeRoundedAddCircleHalfDot,
            color: Colors.black,
            size: 30,
          ),
          const SizedBox(width: 12),
          Text(
            "Add Plots",
            style: GoogleFonts.poppins(fontSize: 24, color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
  Widget detailsCard(List<String> plots) {
    if (plots.isEmpty) {
      return _noDataCard('No plots found');
    }

    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16),
            child: Text(
              'Plots',
              style: GoogleFonts.poppins(fontSize: 24, color: Colors.black),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: plots.length,
            itemBuilder: (context, index) {
              final plotName = plots[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddPlotSales(
                      plotName: plotName,
                      year: widget.selectedYear,
                      crop: widget.cropKey,
                      icon: widget.cropIcon,
                    )
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        plotName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _noDataCard(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco_outlined,
                    size: 64, color: AppColor.green500.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  text,
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _AddCropFAB extends StatelessWidget {
  final String cropKey, year, cropName, subtitle, iconPath;
  final TextEditingController plotNameController;
  final TextEditingController acreController;
  final TextEditingController gunthaController;
  final TextEditingController sapllingController;

  const _AddCropFAB({
    required this.plotNameController,
    required this.acreController,
    required this.gunthaController,
    required this.sapllingController,
    required this.cropKey,
    required this.year,
    required this.cropName,
    required this.subtitle,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: AppColor.green500,
      elevation: 4,
      onPressed: () {
        HapticFeedback.lightImpact();
        showDialog(
          context: context,
          builder: (BuildContext context) => dialogBox(context),
        );
      },
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        "Add Plot",
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget dialogBox(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter Plot Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // Plot Name
                CustomTextField(
                  hintText: 'Plot Name',
                  controller: plotNameController,
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter plot name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Acre & Guntha
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        hintText: 'Acre',
                        controller: acreController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final num? parsed = num.tryParse(value);
                          if (parsed == null || parsed < 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomTextField(
                        hintText: 'Guntha',
                        controller: gunthaController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final num? parsed = num.tryParse(value);
                          if (parsed == null || parsed < 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // No. of Saplings
                CustomTextField(
                  hintText: 'No. of Saplings',
                  controller: sapllingController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter saplings count';
                    }
                    final num? parsed = num.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await _savePlotAndCrop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.green500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "Save",
                          style:
                          GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Unified Firebase write operation
  Future<void> _savePlotAndCrop(BuildContext context) async {
    final plotName = plotNameController.text.trim();
    final acre = acreController.text.trim();
    final guntha = gunthaController.text.trim();
    final saplings = sapllingController.text.trim();

    final database = FirebaseDatabase.instance.ref();

    final cropPath = "Crops/$year/$cropKey";
    final plotPath = "Sales_Ledger/$cropKey/$year/$plotName";

    final updates = <String, dynamic>{
      // Add crop if not exists
      cropPath: {
        "icon": iconPath,
        "name": cropName,
        "subtitle": subtitle,
      },

      // Add plot data
      plotPath: {
        "acre": acre,
        "guntha": guntha,
        "saplings": saplings,
        "merchantName": "",
        "sales_entries": {},
      },
    };

    try {
      await database.update(updates); // Single atomic write
      Navigator.pop(context);
      CustomSnackBar.show(
        context,
        message: "✅ Plot added successfully!",
        fromTop: false,
        type: SnackBarType.success,
      );

      // clear text fields after success
      plotNameController.clear();
      acreController.clear();
      gunthaController.clear();
      sapllingController.clear();

    } catch (e) {
      Navigator.pop(context);
      CustomSnackBar.show(
        context,
        message: "❌ Error adding plot: $e",
        fromTop: false,
        type: SnackBarType.error,
      );
    }
  }
}

