import 'package:desaifarms/Screens/Finance/plot_statistics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../Utils/app_color.dart';
import 'plot_info_screen.dart';

class PlotDetailsScreen extends StatefulWidget {
  final String name, icon, cropKey, year;
  const PlotDetailsScreen({
    super.key,
    required this.name,
    required this.icon,
    required this.cropKey,
    required this.year,
  });

  @override
  State<PlotDetailsScreen> createState() => _PlotDetailsScreenState();
}

class _PlotDetailsScreenState extends State<PlotDetailsScreen> {
  late DatabaseReference dbRef;
  bool isLoading = true;
  List<Map<String, dynamic>> plotDetails = [];
  double totalWeight = 0;
  double totalTurnover = 0;
  double totalAcre = 0;

  @override
  void initState() {
    super.initState();
    dbRef = FirebaseDatabase.instance.ref(
      'Sales_Ledger/${widget.cropKey}/${widget.year}',
    );
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await dbRef.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        plotDetails.clear(); // ✅ clear before reload
        double totalWeightSum = 0;
        double totalTurnoverSum = 0;
        double totalAcreSum = 0;

        data.forEach((plotName, plotData) {
          final plot = Map<String, dynamic>.from(plotData);

          final acre = int.tryParse(plot['acre']?.toString() ?? '0') ?? 0;
          final guntha = int.tryParse(plot['guntha']?.toString() ?? '0') ?? 0;
          final totalPlotAcre = acre + (guntha / 40);
          totalAcreSum += totalPlotAcre;

          plotDetails.add({
            'name': plotName,
            'acre': acre,
            'guntha': guntha,
          });

          // ✅ Calculate avg rate and total weight for this plot
          double plotWeightSum = 0;
          double plotRateSum = 0;
          int rateCount = 0;

          if (plot['sales_entries'] != null) {
            final salesEntries = Map<String, dynamic>.from(plot['sales_entries']);
            salesEntries.forEach((_, entryData) {
              final entry = Map<String, dynamic>.from(entryData);
              final weight = double.tryParse(entry['totalWeight']?.toString() ?? '0') ?? 0;
              final rate = double.tryParse(entry['rate']?.toString() ?? '0') ?? 0;

              plotWeightSum += weight;
              if (rate > 0) {
                plotRateSum += rate;
                rateCount++;
              }
            });
          }

          double avgRate = rateCount > 0 ? plotRateSum / rateCount : 0;
          double plotTurnover = plotWeightSum * avgRate;

          totalWeightSum += plotWeightSum;
          totalTurnoverSum += plotTurnover;
        });

        totalAcre = totalAcreSum;
        totalWeight = totalWeightSum;
        totalTurnover = totalTurnoverSum;
      }
    } catch (e) {
      print("Error loading data: $e");
    }

    setState(() => isLoading = false);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.black),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _customAppBar(),
          Expanded(
            child: RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.white,
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    yearCard(widget.year),
                    const SizedBox(height: 8),
                    detailsCard(),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                      ),
                      child: Row(
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedCrop),
                          const SizedBox(width: 12),
                          Text(
                            'Total Area: $totalAcre Acre',
                            style: GoogleFonts.poppins(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    statisticsCards(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _customAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 48, left: 16, right: 8, bottom: 8),
      color: AppColor.green100,
      child: Row(
        children: [
          SvgPicture.asset(widget.icon, height: 36, width: 36),
          const SizedBox(width: 16),
          Text(
            widget.name,
            style: GoogleFonts.poppins(fontSize: 24, color: Colors.black),
          ),
          const Spacer(),
          IconButton(
              onPressed: loadData,
              icon: HugeIcon(icon: HugeIcons.strokeRoundedRefresh)
          )
        ],
      ),
    );
  }

  Widget detailsCard() {
    if (plotDetails.isEmpty) {
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
            padding: const EdgeInsets.only(left: 16.0, top: 16,right: 16),
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
            itemCount: plotDetails.length,
            itemBuilder: (context, index) {
              final plot = plotDetails[index];
              final plotName = plot['name'];
              final acre = plot['acre'];
              final guntha = plot['guntha'];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlotInfoScreen(
                      plotName: plotName,
                      year: widget.year,
                      crop: widget.cropKey,
                      icon: widget.icon,
                      area : acre + (guntha / 40)
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
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          plotName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Area: ${acre + (guntha / 40)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        )
                      ],
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

  Widget statisticsCards() {
    if (totalWeight == 0 && totalTurnover == 0) {
      return Container(
        color: Colors.white,
        child: Text(''),
      );
    }

    final format = NumberFormat.decimalPattern('en_IN');
    return Column(
      children: [
        InfoCard(
          title: 'Total Weight',
          value: totalWeight,
          iconPath: HugeIcons.strokeRoundedWeightScale01,
          isWeight: true,
          format: format,
        ),
        InfoCard(
          title: 'Total Turnover',
          value: totalTurnover,
          iconPath: HugeIcons.strokeRoundedMoney04,
          isWeight: false,
          format: format,
        ),
      ],
    );
  }

  Widget _noDataCard(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                text,
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
              ),
            ),
          ),
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
              widget.year,
              style: GoogleFonts.poppins(
                fontSize: 24,
                color: Colors.black,
              )
          ),
          const Spacer(),
      PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          onSelected: (value) {
            if (value == 'statistics') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PlotStatistics(
                        cropKey:  widget.cropKey,
                        year:  widget.year,
                        icon:  widget.icon,
                        name:  widget.name,
                      )
                  )
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: "statistics",
              child: Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedAnalytics01),
                  SizedBox(width: 8),
                  Text(
                      "Statistics",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      )
                  ),
                ],
              ),
            ),
          ],
          child: IconButton(
              onPressed: null,
              icon: HugeIcon(icon: HugeIcons.strokeRoundedMoreVerticalSquare01)
          )
      )
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final double value;
  final List<List<dynamic>> iconPath;
  final bool isWeight;
  final NumberFormat format;
  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.iconPath,
    required this.isWeight,
    required this.format,
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
        children: [
          HugeIcon(icon: iconPath),
          const SizedBox(width: 12),
          Column(
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
              Text(
                isWeight
                    ? '${format.format(value)} kg'
                    : '₹${format.format(value)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
