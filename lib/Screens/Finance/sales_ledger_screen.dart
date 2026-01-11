import 'dart:async';
import 'package:desaifarms/custom_widget/snack_bar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../Utils/app_color.dart';
import 'add_crop_screen.dart';
import 'add_plot_screen.dart';

/// ===============================
/// MAIN SALES LEDGER SCREEN
/// ===============================
class SalesLedgerScreen extends StatefulWidget {
  const SalesLedgerScreen({super.key});

  @override
  State<SalesLedgerScreen> createState() => _SalesLedgerScreenState();
}

class _SalesLedgerScreenState extends State<SalesLedgerScreen> {
  // Shared notifier to listen for selected year changes
  static final ValueNotifier<String> selectedYearNotifier =
  ValueNotifier(DateTime.now().year.toString());

  // Notifier for number of crops (for FAB control)
  static final ValueNotifier<int> cropCountNotifier = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.green50,
      floatingActionButton: ValueListenableBuilder2<String, int>(
        first: selectedYearNotifier,
        second: cropCountNotifier,
        builder: (context, selectedYear, cropCount, _) {
          final currentYear = DateTime.now().year.toString();
          return selectedYear == currentYear
              ? _AddCropFAB(noOfCrops: cropCount)
              : const SizedBox.shrink();
        },
      ),
      body: Column(
        children: [
          const _SalesLedgerAppBar(),
          const Expanded(child: SalesLedgerBody()),
        ],
      ),
    );
  }
}

/// ===============================
/// CUSTOM APP BAR
/// ===============================
class _SalesLedgerAppBar extends StatelessWidget {
  const _SalesLedgerAppBar();

  @override
  Widget build(BuildContext context) {
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
          const HugeIcon(
            icon: HugeIcons.strokeRoundedMoneySend01,
            color: Colors.black,
            size: 30,
          ),
          const SizedBox(width: 12),
          Text(
            "Sales Ledger",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// ADD CROP FLOATING BUTTON
/// ===============================
class _AddCropFAB extends StatelessWidget {
  final int noOfCrops;
  const _AddCropFAB({required this.noOfCrops});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: AppColor.green500,
      elevation: 4,
      onPressed: () {
        HapticFeedback.lightImpact();
        if (noOfCrops >= 6) {
          CustomSnackBar.show(
            context,
            message: 'Maximum 6 crops allowed',
            type: SnackBarType.warning,
            fromTop: false,
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddCropScreen(
              selectedYear: DateTime.now().year.toString(),
            ),
          ),
        );
      },
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        "Add Crop",
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// ===============================
/// SALES LEDGER BODY
/// ===============================
class SalesLedgerBody extends StatefulWidget {
  const SalesLedgerBody({super.key});

  @override
  State<SalesLedgerBody> createState() => _SalesLedgerBodyState();
}

class _SalesLedgerBodyState extends State<SalesLedgerBody>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<String> _selectedYear =
  ValueNotifier(DateTime.now().year.toString());
  final ValueNotifier<Map<dynamic, dynamic>> _cropDataNotifier =
  ValueNotifier({});
  StreamSubscription<DatabaseEvent>? _cropListener;
  String? _currentListeningYear;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _listenToYear(_selectedYear.value);
    _selectedYear.addListener(_onYearChanged);
    _SalesLedgerScreenState.selectedYearNotifier.value = _selectedYear.value;
  }

  void _onYearChanged() {
    _listenToYear(_selectedYear.value);
    _SalesLedgerScreenState.selectedYearNotifier.value = _selectedYear.value;
  }

  void _listenToYear(String year) {
    if (_currentListeningYear == year) return; // Avoid reattaching listener
    _currentListeningYear = year;
    _cropListener?.cancel();

    final ref = FirebaseDatabase.instance.ref("Crops/$year");
    _cropListener = ref.onValue.listen((event) {
      final value = event.snapshot.value;
      final Map<dynamic, dynamic> crops =
      value != null ? Map<dynamic, dynamic>.from(value as Map) : {};
      _cropDataNotifier.value = crops;
      _SalesLedgerScreenState.cropCountNotifier.value = crops.length;
    });
  }

  @override
  void dispose() {
    _cropListener?.cancel();
    _selectedYear.removeListener(_onYearChanged);
    _selectedYear.dispose();
    _cropDataNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        ValueListenableBuilder<String>(
          valueListenable: _selectedYear,
          builder: (_, year, __) => _YearSelector(
            selectedYear: year,
            onYearChanged: (value) => _selectedYear.value = value!,
          ),
        ),
        const _SectionTitle(title: "Your Crops"),
        Expanded(
          child: ValueListenableBuilder<Map<dynamic, dynamic>>(
            valueListenable: _cropDataNotifier,
            builder: (context, data, _) {
              if (data.isEmpty) return const _NoCropsView();

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final key = data.keys.elementAt(index);
                  final crop = Map<String, dynamic>.from(data[key]);
                  return _CropCard(
                    name: crop["name"] ?? "Unknown",
                    icon: crop["icon"],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddPlotDetailsScreen(
                            selectedYear: _selectedYear.value,
                            cropName: crop["name"],
                            cropIcon: crop["icon"],
                            cropKey: key,
                            cropSubtitle: crop['subtitle'],
                          )
                        )
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ===============================
/// YEAR SELECTOR DROPDOWN
/// ===============================
class _YearSelector extends StatelessWidget {
  final String selectedYear;
  final ValueChanged<String?> onYearChanged;

  const _YearSelector({
    required this.selectedYear,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final int startYear = 2025;
    final currentYear = DateTime.now().year;
    final years =
    List.generate(currentYear - startYear + 1, (i) => (startYear + i).toString());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.green50, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedYear,
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
          onChanged: onYearChanged,
        ),
      ),
    );
  }
}

/// ===============================
/// SECTION TITLE
/// ===============================
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

/// ===============================
/// NO CROPS VIEW
/// ===============================
class _NoCropsView extends StatelessWidget {
  const _NoCropsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined,
              size: 64, color: AppColor.green500.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "No crops yet",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// CROP CARD
/// ===============================
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
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

/// ===============================
/// HELPER BUILDER FOR MULTIPLE NOTIFIERS
/// ===============================
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, valueA, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, valueB, child) =>
              builder(context, valueA, valueB, child),
        );
      },
    );
  }
}
