import 'package:desaifarms/custom_widget/snack_bar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../Utils/app_color.dart';
import 'add_plot_screen.dart';

class AddCropScreen extends StatefulWidget {
  final String selectedYear;
  const AddCropScreen({super.key, required this.selectedYear});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final dbRef = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.green50,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _customAppBar(),
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColor.green700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Tap to add crop",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: dbRef
                  .onValue, // Listen to entire DB (lightweight since small nodes)
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return Center(
                    child: Text(
                      "No crops found.",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  );
                }

                final data = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );

                // Extract data safely
                final totalCropsMap = data["TotalCrops"] != null
                    ? Map<String, dynamic>.from(data["TotalCrops"])
                    : {};
                final cropsMap =
                    (data["Crops"] != null &&
                        data["Crops"][widget.selectedYear] != null)
                    ? Map<String, dynamic>.from(
                        data["Crops"][widget.selectedYear],
                      )
                    : {};

                final lastYearKey = (int.parse(widget.selectedYear) - 1)
                    .toString();

                final cropsMapLastYear =
                    (data["Crops"] != null &&
                        data["Crops"][lastYearKey] != null)
                    ? Map<String, dynamic>.from(data["Crops"][lastYearKey])
                    : {};

                // Compute missing crops
                List<Map<String, dynamic>> missingCrops = [];
                totalCropsMap.forEach((key, value) {
                  if (!cropsMap.containsKey(key)) {
                    missingCrops.add({
                      'key': key,
                      'name': value['name'],
                      'subtitle': value['subtitle'],
                      'icon': value['icon'],
                    });
                  }
                });

                if (missingCrops.isEmpty) {
                  return Center(
                    child: Text(
                      "All crops are added for ${widget.selectedYear}!",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: missingCrops.length,
                  itemBuilder: (context, index) {
                    final crop = missingCrops[index];
                    return _CropCard(
                      name: crop["name"],
                      icon: crop["icon"],
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (cropsMapLastYear.containsKey(crop["key"])) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Continue the crop from last year?',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: Colors.red[100]!,
                                                  width: 1.5,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                              ),
                                              child: Text(
                                                "No",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    final salesLedger = data['Sales_Ledger'];

                                                    final lastYearCropData =
                                                    salesLedger != null &&
                                                        salesLedger[crop['key']] != null &&
                                                        salesLedger[crop['key']][lastYearKey] != null
                                                        ? Map<String, dynamic>.from(
                                                      salesLedger[crop['key']][lastYearKey],
                                                    )
                                                        : {};
                                                    final plotsList = lastYearCropData.keys.toList();
                                                    List<String> mutablePlots = List.from(plotsList);

                                                    return StatefulBuilder(
                                                      builder: (context, setDialogState) {
                                                        return Dialog(
                                                          backgroundColor: Colors.transparent,
                                                          insetPadding: EdgeInsets.zero,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: SingleChildScrollView(
                                                            physics: const AlwaysScrollableScrollPhysics(
                                                              parent: BouncingScrollPhysics(),
                                                            ),
                                                            padding: const EdgeInsets.all(16),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const SizedBox(height: 8),
                                                                detailsCard(
                                                                  mutablePlots,
                                                                  onRemovePlot: (index) {
                                                                    setDialogState(() {
                                                                      mutablePlots.removeAt(index);
                                                                    });
                                                                  },
                                                                ),
                                                                const SizedBox(height: 36),
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child: ElevatedButton(
                                                                        onPressed: () {
                                                                          Navigator.pop(context);
                                                                        },
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: Colors.red,
                                                                          elevation: 0,
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(12),
                                                                          ),
                                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                                        ),
                                                                        child: Text(
                                                                          "Cancel",
                                                                          style: GoogleFonts.poppins(
                                                                            color: Colors.white,
                                                                            fontWeight: FontWeight.w500,
                                                                            fontSize: 14,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 12),
                                                                    Expanded(
                                                                      child: ElevatedButton(
                                                                        onPressed: () async {
                                                                          try {
                                                                            final cropKey = crop['key'];
                                                                            final currentYear = widget.selectedYear;
                                                                            final lastYear = lastYearKey;

                                                                            final root = FirebaseDatabase.instance.ref();

                                                                            /// ✅ Last year crop -> year -> plot nodes
                                                                            final lastYearPlotsMap =
                                                                            Map<String, dynamic>.from(
                                                                              data['Sales_Ledger']?[cropKey]?[lastYear] ?? {},
                                                                            );

                                                                            /// ✅ Build current year plots data (ONLY BASIC FIELDS)
                                                                            Map<String, dynamic> selectedPlotsData = {};
                                                                            for (String plotName in mutablePlots) {
                                                                              if (!lastYearPlotsMap.containsKey(plotName)) continue;

                                                                              final plotData = Map<String, dynamic>.from(lastYearPlotsMap[plotName]);

                                                                              // ✅ Only copy these 3 fields
                                                                              selectedPlotsData[plotName] = {
                                                                                "acre": plotData["acre"] ?? 0,
                                                                                "guntha": plotData["guntha"] ?? 0,
                                                                                "saplings": plotData["saplings"] ?? 0,
                                                                              };
                                                                            }

                                                                            /// ✅ If nothing left after removals
                                                                            if (selectedPlotsData.isEmpty) {
                                                                              CustomSnackBar.show(
                                                                                  context,
                                                                                  message: 'No plots selected',
                                                                                  type: SnackBarType.warning,
                                                                                fromTop: false
                                                                              );
                                                                              return;
                                                                            }

                                                                            /// 🔥 Prepare atomic multi-location update
                                                                            final Map<String, Object?> updates = {};

                                                                            /// ✅ Add crop into Crops node
                                                                            updates["Crops/$currentYear/$cropKey"] = {
                                                                              "name": crop["name"],
                                                                              "subtitle": crop["subtitle"],
                                                                              "icon": crop["icon"],
                                                                            };

                                                                            /// ✅ Add selected plots into Sales_Ledger current year
                                                                            updates["Sales_Ledger/$cropKey/$currentYear"] = selectedPlotsData;

                                                                            /// ✅ Perform update
                                                                            await root.update(updates);

                                                                            Navigator.pop(context); // Close dialog
                                                                            CustomSnackBar.show(context, message: 'Crop continued successfully', type: SnackBarType.success, fromTop: false);
                                                                          } catch (e) {
                                                                            CustomSnackBar.show(context, message: 'Failed to continue crop: $e', type: SnackBarType.error,fromTop: false);
                                                                          }
                                                                        },
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: AppColor.green600,
                                                                          elevation: 0,
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(12),
                                                                          ),
                                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                                        ),
                                                                        child: Text(
                                                                          "Save",
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
                                                                const SizedBox(height: 36),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColor.green600,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                              ),
                                              child: Text(
                                                "Yes",
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
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddPlotDetailsScreen(
                                selectedYear: widget.selectedYear,
                                cropName: crop["name"],
                                cropIcon: crop["icon"],
                                cropKey: crop['key'],
                                cropSubtitle: crop['subtitle'],
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget detailsCard(List<String> plots, {required Function(int) onRemovePlot}) {
    if (plots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16),
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
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
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
                  Positioned(
                    top: -5,
                    right: -5,
                    child: InkWell(
                      onTap: () => onRemovePlot(index),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 28,
                        width: 28,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
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
            icon: HugeIcons.strokeRoundedEcoEnergy,
            color: Colors.black,
            size: 30,
          ),
          const SizedBox(width: 12),
          Text(
            "Add Crops",
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

class _CropCard extends StatelessWidget {
  final String name;
  final String? icon;
  final VoidCallback onTap;

  const _CropCard({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                if (icon != null)
                  SvgPicture.asset(
                    icon!,
                    height: 44,
                    width: 44,
                    cacheColorFilter: true,
                  )
                else
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColor.green50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.eco, color: AppColor.green500),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                HugeIcon(icon: HugeIcons.strokeRoundedAddCircleHalfDot),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
