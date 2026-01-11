import 'dart:async';
import 'package:desaifarms/Utils/app_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../Comman/login_screen.dart';
import 'plot_details_screen.dart';

class HomeScreenFinance extends StatefulWidget {
  const HomeScreenFinance({super.key});

  @override
  State<HomeScreenFinance> createState() => _HomeScreenFinanceState();
}

class _HomeScreenFinanceState extends State<HomeScreenFinance>
    with AutomaticKeepAliveClientMixin {
  late Future<String> _fetchNameFuture;
  late final DatabaseReference cropsRef;

  final ValueNotifier<double> _revenueNotifier = ValueNotifier(0);
  final NumberFormat _format = NumberFormat.decimalPattern('en_IN');

  String selectedYear = DateTime.now().year.toString();
  bool isLoadingRevenue = true;
  Map<dynamic, dynamic>? cachedCrops;
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchNameFuture = getName();
    cropsRef = FirebaseDatabase.instance.ref("Crops/$selectedYear");
    _calculateRevenue();
  }

  void _updateYear(String year) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        selectedYear = year;
        isLoadingRevenue = true;
      });
      _calculateRevenue();
    });
  }

  Future<void> _calculateRevenue() async {
    final total = await calculateYearRevenueAvgRate(selectedYear);
    _revenueNotifier.value = total;
    setState(() => isLoadingRevenue = false);
  }

  Stream<DatabaseEvent> _fetchCrops() =>
      FirebaseDatabase.instance.ref("Crops/$selectedYear").onValue;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _customAppBar(context),
          YearDropdown(selectedYear: selectedYear, onYearChanged: _updateYear),
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
            child: Text(
              'Your Crops',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              )
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.white,
              onRefresh: () async {
                await _calculateRevenue();
              },
              child: StreamBuilder<DatabaseEvent>(
                stream: _fetchCrops(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.eco_outlined,
                              size: 64, color: AppColor.green500.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            "No Crops Found",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final newData =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  if (cachedCrops != newData) cachedCrops = newData;

                  final data = cachedCrops ?? {};

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),                     itemCount: data.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final key = data.keys.elementAt(index);
                      final crop = data[key];
                      return cropCard(
                        name: crop["name"],
                        subtitle: crop["subtitle"],
                        icon: crop["icon"],
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlotDetailsScreen(
                                name: crop["name"],
                                icon: crop["icon"],
                                cropKey: key,
                                year: selectedYear,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 48,
                top: 4,
              ),
              child: isLoadingRevenue
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.transparent),
                    )
                  : ValueListenableBuilder<double>(
                      valueListenable: _revenueNotifier,
                      builder: (context, value, _) {
                        return InfoCard(
                          title: "Total Revenue",
                          value: value,
                          iconPath: HugeIcons.strokeRoundedMoney01,
                          format: _format,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      drawer: SafeArea(
        child: Drawer(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeaderContent(fetchNameFuture: _fetchNameFuture),
                    const SizedBox(height: 8),
                    _HomeTile(
                      icon: HugeIcons.strokeRoundedHome03,
                      title: 'Home',
                    ),
                    _HomeTile(
                      icon: HugeIcons.strokeRoundedUser,
                      title: 'Profile',
                      route: '/profile',
                    ),_HomeTile(
                      icon: HugeIcons.strokeRoundedMoneySend01,
                      title: 'Sales Ledger',
                      route: '/sales_ledger',
                    ),
                  ],
                ),
              ),
              const _LogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 8, right: 8, bottom: 8),
      color: AppColor.green100,
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(context).openDrawer(); // ✅ Works now
              },
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedMenu03,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "Home",
            style: GoogleFonts.poppins(fontSize: 24, color: Colors.black),
          ),
          const Spacer(),
          IconButton(
            onPressed: _calculateRevenue,
            icon: HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _revenueNotifier.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

class DrawerHeaderContent extends StatelessWidget {
  final Future<String> fetchNameFuture;
  const DrawerHeaderContent({super.key, required this.fetchNameFuture});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.green100,
      child: Column(
        children: [
          SvgPicture.asset("assets/farmer_body.svg", width: 175, height: 225),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: fetchNameFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                );
              }
              return Text(
                snapshot.data!,
                style: GoogleFonts.poppins(fontSize: 24, color: Colors.black),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String? route;
  const _HomeTile({required this.icon, required this.title, this.route});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: HugeIcon(icon: icon, color: Colors.black, size: 28),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
      ),
      onTap: () {
        Navigator.pop(context);
        if (route != null) Navigator.pushNamed(context, route!);
      },
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: InkWell(
        onTap: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          await FirebaseAuth.instance.signOut();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
          );
        },
        splashColor: AppColor.errorRipple,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
          decoration: BoxDecoration(
            color: AppColor.error,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              "Logout",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Helper Widgets & Functions
// ----------------------------------------------------------------------

Future<String> getName() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return "Guest";
  final ref = FirebaseDatabase.instance.ref("Users/${user.uid}/Profile/Name");
  final snapshot = await ref.get();
  return snapshot.value?.toString() ?? "No Name";
}


Widget cropCard({
  required String name,
  required String subtitle,
  required String icon,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, right: 16),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 4,
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                SvgPicture.asset(
                  icon,
                  height: 44,
                  width: 44,
                  cacheColorFilter: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.black.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    )
  );
}

class YearDropdown extends StatefulWidget {
  final String selectedYear;
  final ValueChanged<String> onYearChanged;
  const YearDropdown({
    super.key,
    required this.selectedYear,
    required this.onYearChanged,
  });

  @override
  State<YearDropdown> createState() => _YearDropdownState();
}

class _YearDropdownState extends State<YearDropdown> {
  final int startYear = 2025;
  late List<String> years;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    final totalYears = (currentYear - startYear+1);
    years = List.generate(totalYears, (i) => (startYear + i).toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.green50, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedYear,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          icon: const Icon(Icons.expand_more, color: AppColor.green500),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          items: years
              .map((year) => DropdownMenuItem(value: year, child: Text(year)))
              .toList(),
          onChanged: (value) => widget.onYearChanged(value!),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final double value;
  final List<List<dynamic>> iconPath;
  final NumberFormat format;
  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.iconPath,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
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
                '₹${format.format(value)}',
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

// ----------------------------------------------------------------------
// Revenue Calculator
// ----------------------------------------------------------------------

Future<double> calculateYearRevenueAvgRate(String year) async {
  final dbRef = FirebaseDatabase.instance.ref('Sales_Ledger');
  final snapshot = await dbRef.get();

  if (!snapshot.exists) return 0;

  final data = Map<String, dynamic>.from(snapshot.value as Map);
  double totalRevenue = 0;

  for (final cropData in data.values) {
    final yearData = (cropData as Map)[year];
    if (yearData == null) continue;

    for (final plot in (yearData as Map).values) {
      final entries = Map<String, dynamic>.from(plot['sales_entries'] ?? {});
      if (entries.isEmpty) continue;

      double totalWeight = 0;
      double rateSum = 0;
      int rateCount = 0;

      for (final entry in entries.values) {
        final rate = double.tryParse(entry['rate']?.toString() ?? '0') ?? 0;
        final weight = double.tryParse(entry['totalWeight']?.toString() ?? '0') ?? 0;
        totalWeight += weight;
        rateSum += rate;
        rateCount++;
      }

      if (rateCount > 0) {
        final avgRate = rateSum / rateCount;
        totalRevenue += totalWeight * avgRate;
      }
    }
  }
  return totalRevenue;
}
