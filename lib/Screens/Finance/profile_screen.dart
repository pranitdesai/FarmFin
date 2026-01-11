import 'package:desaifarms/Utils/app_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../Comman/login_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late DatabaseReference dbRefPersonalData;
  final mAuth = FirebaseAuth.instance;
  Future<Map<String, dynamic>>? cropStatsFuture;

  @override
  void initState() {
    dbRefPersonalData = FirebaseDatabase.instance.ref().child(
      'Users/${mAuth.currentUser!.uid}/Profile',
    );
    cropStatsFuture = calculateCropStats();
    super.initState();
  }
  Future<Map<String, dynamic>> calculateCropStats() async {
    final currentYear = DateTime.now().year.toString();

    final dbRefCrops = FirebaseDatabase.instance.ref('Crops/$currentYear');
    final dbRefSales = FirebaseDatabase.instance.ref('Sales_Ledger');

    final cropsSnapshot = await dbRefCrops.get();
    final salesSnapshot = await dbRefSales.get();

    if (!cropsSnapshot.exists || !salesSnapshot.exists) return {};

    // Get only crops available in "Crops/currentYear"
    final cropsData = Map<String, dynamic>.from(cropsSnapshot.value as Map);
    final salesData = Map<String, dynamic>.from(salesSnapshot.value as Map);

    double grandTotalArea = 0;
    int totalCrops = 0;

    // Loop only through crops listed under "Crops/currentYear"
    cropsData.forEach((cropName, _) {
      if (!salesData.containsKey(cropName)) return; // Skip if crop not in Sales_Ledger
      final cropSales = Map<String, dynamic>.from(salesData[cropName]);

      // Check only the current year's data
      if (!cropSales.containsKey(currentYear)) return;
      final yearData = Map<String, dynamic>.from(cropSales[currentYear]);

      double cropTotalArea = 0;

      // Add all plots’ area for this crop (current year)
      yearData.forEach((plotName, plotData) {
        if (plotData is Map) {
          final acre = double.tryParse(plotData['acre']?.toString() ?? '0') ?? 0;
          final guntha = double.tryParse(plotData['guntha']?.toString() ?? '0') ?? 0;
          cropTotalArea += acre + (guntha / 40);
        }
      });

      // Count this crop if it has any valid area
      if (cropTotalArea > 0) {
        totalCrops++;
        grandTotalArea += cropTotalArea;
      }
    });

    return {
      'total_area_acre': grandTotalArea,
      'total_crops': totalCrops,
    };
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColor.green500,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Profile',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  )
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                  children: [
                    // <CHANGE> Profile card with better layout
                    StreamBuilder(
                      stream: dbRefPersonalData.onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColor.green500,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Something went wrong',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }

                        final map = snapshot.data!.snapshot.value as Map?;
                        if (map == null) {
                          return const SizedBox.shrink();
                        }

                        final name = map['Name'] ?? 'User';
                        final email = map['Email'] ?? '';
                        final phone = map['Phone'] ?? '';




                        return Column(
                          children: [
                            // Profile card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  // Avatar
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColor.green500.withOpacity(0.2),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(80),
                                      child: SvgPicture.asset(
                                        'assets/farmer_profile_avatar.svg',
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Name
                                  Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),

                                  // <CHANGE> Contact info in organized layout
                                  Container(

                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F5F2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    child: Column(
                                      children: [
                                        _InfoRow(
                                          icon: HugeIcons.strokeRoundedCall,
                                          label: 'Phone',
                                          value: phone,
                                        ),
                                        const SizedBox(height: 8),
                                        _InfoRow(
                                          icon: HugeIcons.strokeRoundedMail01,
                                          label: 'Email',
                                          value: email,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            FutureBuilder<Map<String, dynamic>>(
                              future: cropStatsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No crop data found',
                                      style: GoogleFonts.poppins(color: Colors.grey),
                                    ),
                                  );
                                }

                                final stats = snapshot.data!;
                                return Row(
                                  children: [
                                    _StatCard(
                                      label: 'Crops',
                                      value: '${stats['total_crops']}',
                                      icon: HugeIcons.strokeRoundedLeaf01,
                                    ),
                                    const SizedBox(width: 12),
                                    _StatCard(
                                      label: 'Land Area',
                                      value: '${stats['total_area_acre'].toStringAsFixed(2)} Acre',
                                      icon: HugeIcons.strokeRoundedMapPin,
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // <CHANGE> Logout button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _showLogoutDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(
                                  'Logout',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              mAuth.signOut();
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen())
              );
            },
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// <CHANGE> New helper widget for info rows
class _InfoRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(
          icon: icon,
          color: AppColor.green500,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// <CHANGE> New helper widget for stat cards
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final List<List<dynamic>> icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            HugeIcon(
              icon: icon,
              color: AppColor.green500,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// // <CHANGE> New helper widget for action buttons
// class _ActionButton extends StatelessWidget {
//   final String label;
//   final List<List<dynamic>> icon;
//   final VoidCallback onTap;
//
//   const _ActionButton({
//     required this.label,
//     required this.icon,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: Colors.grey.shade200,
//               width: 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.04),
//                 blurRadius: 4,
//               ),
//             ],
//           ),
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               HugeIcon(
//                 icon: icon,
//                 color: AppColor.green500,
//                 size: 22,
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 label,
//                 style: GoogleFonts.poppins(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }