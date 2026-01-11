import 'package:desaifarms/Screens/Finance/per_plot_stat.dart';
import 'package:desaifarms/Utils/app_color.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class PlotStatistics extends StatefulWidget {
  final String cropKey,year,icon,name;
  const PlotStatistics({super.key, required this.cropKey, required this.year, required this.icon, required this.name});

  @override
  State<PlotStatistics> createState() => _PlotStatisticsState();
}

class _PlotStatisticsState extends State<PlotStatistics> {
  late DatabaseReference ref;
  @override
  void initState() {
    ref = FirebaseDatabase.instance.ref(
      'Sales_Ledger/${widget.cropKey}/${widget.year}',
    );
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.green100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _customAppBar(),
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _cropName(),
                    const SizedBox(height: 32),
                    StreamBuilder(
                        stream: ref.onValue,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator(color: Colors.green)),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                            return Center(
                              child: Text(
                                  "No data found",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  )
                              ),
                            );
                          }
                          final Map<dynamic, dynamic> plots =
                          snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                          return ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: BouncingScrollPhysics(),
                            itemCount: plots.length,
                            itemBuilder: (context, index) {
                              final String plotName = plots.keys.elementAt(index);
                              final Map<dynamic, dynamic> plotInfo =
                              Map<dynamic, dynamic>.from(plots[plotName]);
                              return PlotList(
                                plotData: plotInfo,
                                plotName: plotName,
                              );
                            }
                          );
                        }
                    )
                  ],
                ),
              ),
        
          ],
        ),
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
            SvgPicture.asset(widget.icon, height: 28, width: 28),
            const SizedBox(width: 12),
            Text(
              widget.name,
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
            ),
            const Spacer(),
          ],
        ),
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
          icon: HugeIcons.strokeRoundedAnalytics01,
            color: Colors.black,
            size: 30,
          ),
          const SizedBox(width: 12),
          Text(
            "Plot Statistics",
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
class PlotList extends StatelessWidget {
  final Map<dynamic, dynamic> plotData;
  final String plotName;
  const PlotList({super.key, required this.plotData, required this.plotName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 4,
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: (){
            Navigator.push(context,
            MaterialPageRoute(
              builder: (context) => StatisticsPlotInfo(
                plotData: plotData,
                plotName: plotName,
              )
            ));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    plotName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.black.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
