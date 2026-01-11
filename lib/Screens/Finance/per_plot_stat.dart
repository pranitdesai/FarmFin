import 'package:desaifarms/Utils/app_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

// <CHANGE> Extract text styles as constants for better performance
final _titleStyle = GoogleFonts.poppins(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: Colors.black,
);

final _labelStyle = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: Colors.black54,
);

final _valueStyle = GoogleFonts.poppins(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: Colors.black,
);

final _merchantStyle = GoogleFonts.poppins(
  fontSize: 18,
  color: Colors.grey.shade700,
);

class StatisticsPlotInfo extends StatelessWidget {
  final Map<dynamic, dynamic> plotData;
  final String plotName;

  const StatisticsPlotInfo({
    super.key,
    required this.plotData,
    required this.plotName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.green100,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _customAppBar(context),
              Padding(
                padding: const EdgeInsets.all(16),
                child: StatisticsPlotCard(plotData: plotData, plotName: plotName),
              ),
            
          ],
        ),
      ),
    );
  }
  Widget _customAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 48, left: 8, right: 8, bottom: 12),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
              onPressed: (){
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 24,)
          ),
          const SizedBox(width: 12),
          Text(
            "Plot Overview",
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

class StatisticsPlotCard extends StatelessWidget {
  final Map<dynamic, dynamic> plotData;
  final String plotName;

  const StatisticsPlotCard({
    super.key,
    required this.plotData,
    required this.plotName,
  });

  @override
  Widget build(BuildContext context) {
    final int acre = int.tryParse(plotData['acre']?.toString() ?? '0') ?? 0;
    final int guntha = int.tryParse(plotData['guntha']?.toString() ?? '0') ?? 0;
    final int saplings = int.tryParse(plotData['saplings']?.toString() ?? '0') ?? 0;

    final salesEntries = Map<String, dynamic>.from(plotData['sales_entries'] ?? {});
    final salesList = salesEntries.entries.map((entry) {
      final sale = Map<String, dynamic>.from(entry.value);
      sale['id'] = entry.key;
      return sale;
    }).toList();

    final mainMerchant = plotData['merchantName']?.toString().trim() ?? '';
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

    double totalWeight = 0;
    double totalRate = 0;
    int rateCount = 0;

    for (final entry in salesList) {
      final weight = double.tryParse(entry['totalWeight']?.toString() ?? '0') ?? 0;
      double rate = double.tryParse(entry['rate']?.toString() ?? plotData['rate']?.toString() ?? '0') ?? 0;

      totalWeight += weight;
      if (rate > 0) {
        totalRate += rate;
        rateCount++;
      }
    }

    final avgRate = rateCount > 0 ? totalRate / rateCount : 0;
    final totalTurnover = totalWeight * avgRate;
    final formatter = NumberFormat("#,##0.00", "en_IN");

    // <CHANGE> Calculate derived values
    final totalArea = acre + guntha / 40;
    final weightPerSapling = saplings > 0 ? totalWeight / saplings : 0;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // <CHANGE> Simplified header with plot name
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plotName,
                        style: _titleStyle,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedUser02,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Text(
                                allMerchants.join(", "),
                                style: _merchantStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedTag01,
                  color: AppColor.green500,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // <CHANGE> Grid layout for stats - 2 columns for better space utilization
            GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.zero,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              children: [
                _StatCard(
                  icon: HugeIcons.strokeRoundedMapPin,
                  title: "Total Area",
                  value: "${totalArea.toStringAsFixed(2)} Acre",
                ),
                _StatCard(
                  icon: HugeIcons.strokeRoundedPlant02,
                  title: "Saplings",
                  value: saplings.toString(),
                ),
                _StatCard(
                  icon: HugeIcons.strokeRoundedWeightScale,
                  title: "Total Weight",
                  value: "${formatter.format(totalWeight)} kg",
                ),
                _StatCard(
                  icon: HugeIcons.strokeRoundedTag02,
                  title: "Avg Rate/kg",
                  value: "₹${formatter.format(avgRate)}",
                ),
                _StatCard(
                  icon: HugeIcons.strokeRoundedPlant02,
                  title: "Weight/Sapling",
                  value: "${formatter.format(weightPerSapling)} kg Or\n${formatter.format(weightPerSapling/4)} Box",
                ),
                _StatCard(
                  icon: HugeIcons.strokeRoundedWeightScale,
                  title: "Weight per acre",
                  value: "${formatter.format(totalWeight/totalArea)}KG",
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColor.green50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColor.green200,
                  width: 1.5 ,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedMoneyBag01,
                    color: AppColor.green600,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total turnover',
                    style: _labelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${formatter.format(totalTurnover)}",
                    style: _valueStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// <CHANGE> New optimized stat card component with const constructor
class _StatCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HugeIcon(
              icon: icon,
              color: AppColor.green600,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: _labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: _valueStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}