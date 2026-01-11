import 'dart:async';
import 'package:desaifarms/Screens/Comman/login_screen.dart';
import 'package:desaifarms/Utils/app_color.dart';
import 'package:desaifarms/Utils/weather_api.dart';
import 'package:desaifarms/custom_widget/snack_bar.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../Utils/location_service.dart';
import '../../Utils/responsive_size.dart';
import '../Finance/home_screen_finance.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  double? lat, long;
  String? cityName;
  bool isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<String?> _getCityFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.last;

        debugPrint("Placemark => ${place.toJson()}");

        String? pick(String? s) {
          if (s == null) return null;
          final value = s.trim();
          return value.isEmpty ? null : value;
        }

        return pick(place.locality) ??
            pick(place.subLocality) ??
            pick(place.subAdministrativeArea) ??
            pick(place.administrativeArea) ??
            pick(place.country);
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
    return null;
  }


  Future<void> _fetchLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (!mounted) return;

      // Get city name asynchronously
      final city = await _getCityFromCoordinates(
          position.latitude,
          position.longitude,
      );

      if (!mounted) return;

      setState(() {
        lat = position.latitude;
        long = position.longitude;
        cityName = city ?? 'Unknown Location';
        isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingLocation = false;
        cityName = 'Unknown Location';
      });
      CustomSnackBar.show(
        context,
        message: 'Failed to fetch location',
        type: SnackBarType.error,
        fromTop: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.green50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: responsiveHeight(context, 32)),
            const GreetingCard(),
            SizedBox(height: responsiveHeight(context, 24)),
            WeatherWidget(
              lat: lat,
              lon: long,
              cityName: cityName,
              isLoading: isLoadingLocation,
              onRetry: _fetchLocation,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 32, bottom: 8),
              child: Text(
                'Quick Access',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Navigate(
              title: 'Finance',
              icon: HugeIcons.strokeRoundedAnalyticsUp,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreenFinance(),
                  ),
                );
              },
            ),
            // Uncomment when ready
            // Navigate(
            //   title: 'Agrochemicals',
            //   icon: HugeIcons.strokeRoundedAiChemistry02,
            //   onTap: () {},
            // ),
          ],
        ),
      ),
    );
  }
}

class Navigate extends StatelessWidget {
  final String title;
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;

  const Navigate({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        elevation: 3,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          splashColor: AppColor.green200.withOpacity(0.3),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: AppColor.green200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: icon,
                      size: 26,
                      color: AppColor.green800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black54,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key});

  static String _getGreetingMessage(int hour) {
    if (hour < 5) return 'Good Night';
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy').format(now);
    final dayName = DateFormat('EEEE').format(now);
    final greeting = _getGreetingMessage(now.hour);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsiveWidth(context, 15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Hello, ',
                        style: GoogleFonts.poppins(
                          fontSize: responsiveFont(context, 22),
                          color: AppColor.green700,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      TextSpan(
                        text: greeting,
                        style: GoogleFonts.poppins(
                          fontSize: responsiveFont(context, 22),
                          color: AppColor.green700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsiveHeight(context, 6)),
                Text(
                  '$dayName, $formattedDate',
                  style: GoogleFonts.poppins(
                    fontSize: responsiveFont(context, 14),
                    color: AppColor.green700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showLogoutDialog(context);
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              size: 28,
              color: AppColor.green700,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.black45),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                      (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherWidget extends StatefulWidget {
  final double? lat;
  final double? lon;
  final String? cityName;
  final bool isLoading;
  final VoidCallback onRetry;

  const WeatherWidget({
    super.key,
    required this.lat,
    required this.lon,
    required this.cityName,
    required this.isLoading,
    required this.onRetry,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget>
    with WidgetsBindingObserver {
  Future<Map<String, dynamic>>? _weatherFuture;
  Timer? _timer;
  late final WeatherService _weatherService;

  // Constants
  static const Duration _refreshInterval = Duration(minutes: 10);
  static const double _containerHeight = 163.0;
  static const double _borderRadius = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _weatherService = WeatherService(
      apiKey: dotenv.env['WEATHER_API_KEY']!,
    );
    _initializeWeather();
  }

  @override
  void didUpdateWidget(WeatherWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh weather if coordinates changed
    if (oldWidget.lat != widget.lat || oldWidget.lon != widget.lon) {
      _initializeWeather();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _cancelTimer();
    } else if (state == AppLifecycleState.resumed) {
      _startTimer();
      // Refresh weather when app resumes
      if (widget.lat != null && widget.lon != null) {
        _fetchWeather();
      }
    }
  }

  void _initializeWeather() {
    _cancelTimer();
    if (widget.lat != null && widget.lon != null) {
      _fetchWeather();
      _startTimer();
    }
  }

  void _fetchWeather() {
    if (widget.lat != null && widget.lon != null) {
      setState(() {
        _weatherFuture =
            _weatherService.fetchCurrentWeather(widget.lat!, widget.lon!);
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(_refreshInterval, (timer) {
      if (widget.lat != null && widget.lon != null) {
        _fetchWeather();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: responsiveWidth(context, 16)),
      padding: EdgeInsets.all(responsiveHeight(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.lat == null || widget.lon == null || _weatherFuture == null) {
      return _buildErrorState('Location not available');
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        } else if (snapshot.hasError) {
          return _buildErrorState('Unable to fetch weather 😞');
        } else if (!snapshot.hasData) {
          return _buildErrorState('No weather data available');
        }

        return _buildWeatherContent(snapshot.data!);
      },
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: _containerHeight,
      child: Center(
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return SizedBox(
      height: _containerHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(Map<String, dynamic> data) {
    final weatherData = _parseWeatherData(data);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationHeader(),
                  const SizedBox(height: 8),
                  _buildTemperatureDisplay(weatherData),
                ],
              ),
            ),
            Image.asset(
              'assets/weather_icon.png',
              height: 100,
              width: 100,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const DottedLine(
          dashLength: 12,
          dashGapLength: 4,
          dashColor: Colors.grey,
          lineThickness: 1.0,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSubDetails('Humidity', weatherData.humidity),
            _buildSubDetails('Rain', weatherData.rain),
            _buildSubDetails('Probability', weatherData.probability),
            _buildSubDetails('UV Index', weatherData.uvIndex),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationHeader() {
    return Row(
      children: [
        const HugeIcon(
          icon: HugeIcons.strokeRoundedLocation04,
          size: 20,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            widget.cityName ?? 'Loading...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureDisplay(_WeatherData data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: data.currentTemp,
                style: const TextStyle(
                  fontSize: 48,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              WidgetSpan(
                child: Transform.translate(
                  offset: const Offset(2, -16),
                  child: const Text(
                    '°C',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'H: ${data.maxTemp}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            Text(
              'L: ${data.minTemp}',
              style: GoogleFonts.poppins(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubDetails(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  _WeatherData _parseWeatherData(Map<String, dynamic> data) {
    // Safe parsing with null checks
    final temperature = data['temperature'];
    final currentTemp = temperature is Map
        ? (temperature['degrees']?.toString() ?? 'N/A')
        : 'N/A';

    final minMaxTemp = data['currentConditionsHistory'];
    final minTemp = (minMaxTemp is Map && minMaxTemp['minTemperature'] is Map)
        ? (minMaxTemp['minTemperature']['degrees']?.toString() ?? 'N/A')
        : 'N/A';
    final maxTemp = (minMaxTemp is Map && minMaxTemp['maxTemperature'] is Map)
        ? (minMaxTemp['maxTemperature']['degrees']?.toString() ?? 'N/A')
        : 'N/A';

    final relativeHumidity = data["relativeHumidity"];
    final humidity = relativeHumidity != null ? '$relativeHumidity %' : 'N/A';

    final precipData = data["precipitation"];
    String rain = 'N/A';
    if (precipData is Map && precipData['qpf'] is Map) {
      final qpfData = precipData['qpf'];
      final quantity = qpfData['quantity'];
      rain = quantity != null ? '$quantity mm' : 'N/A';
    }

    final uvIndexValue = data["uvIndex"];
    final uvIndex = uvIndexValue?.toString() ?? 'N/A';

    String probability = 'N/A';
    if (precipData is Map && precipData['probability'] is Map) {
      final probData = precipData['probability'];
      final percent = probData['percent'];
      probability = percent != null ? '$percent %' : 'N/A';
    }

    return _WeatherData(
      currentTemp: currentTemp,
      minTemp: minTemp,
      maxTemp: maxTemp,
      humidity: humidity,
      rain: rain,
      uvIndex: uvIndex,
      probability: probability,
    );
  }
}

// Helper class to store parsed weather data
class _WeatherData {
  final String currentTemp;
  final String minTemp;
  final String maxTemp;
  final String humidity;
  final String rain;
  final String uvIndex;
  final String probability;

  _WeatherData({
    required this.currentTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.humidity,
    required this.rain,
    required this.uvIndex,
    required this.probability,
  });
}