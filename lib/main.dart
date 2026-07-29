import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/auth/presentation/signin_screen.dart';
import 'features/auth/presentation/signup_personal_screen.dart';
import 'features/auth/presentation/signup_vehicle_screen.dart';
import 'features/auth/presentation/otp_screen.dart';
import 'features/auth/presentation/success_screen.dart';
import 'features/auth/presentation/driver_dashboard_screen.dart';
import 'features/home/presentation/driver_home_screen.dart';
import 'features/rides/presentation/available_trips_screen.dart';
import 'features/rides/presentation/schedule_trip_info_screen.dart';
import 'features/rides/presentation/mail_parcels_screen.dart';
import 'features/rides/presentation/mail_parcel_details_screen.dart';
import 'features/home/presentation/driver_map_screen.dart';
import 'features/rides/presentation/ride_active_screen.dart';
import 'features/rides/presentation/trip_history_screen.dart';
import 'features/rides/presentation/scheduled_trips_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/presentation/profile_edit_screen.dart';
import 'features/profile/presentation/payment_method_screen.dart';
import 'features/profile/presentation/add_credit_screen.dart';
import 'features/profile/presentation/card_code_screen.dart';
import 'features/profile/presentation/card_success_screen.dart';
import 'features/profile/presentation/language_screen.dart';
import 'features/profile/presentation/support_screen.dart';
import 'features/profile/presentation/chat_screen.dart';

import 'core/network/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart';
import 'core/providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Background Service safely (non-web only)
  try {
    if (!kIsWeb) {
      await BackgroundServiceInstance.initializeService();
    }
  } catch (e) {
    debugPrint('Background service init error (non-fatal): $e');
  }

  // Initialize Local Notifications safely
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Notification init error (non-fatal): $e');
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final apiService = ApiService();
  final storageService = StorageService();
  final authProvider = AuthProvider(apiService, storageService);
  final socketService = SocketService(storageService);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiService),
        ChangeNotifierProvider.value(value: authProvider),
        Provider.value(value: socketService),
        Provider.value(value: storageService),
        Provider.value(value: NotificationService()),
      ],
      child: const YallaDriverApp(),
    ),
  );
}

class YallaDriverApp extends StatelessWidget {
  const YallaDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yalla Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primaryOrange,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.outfitTextTheme(),
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.black),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup_personal': (context) => const SignUpPersonalScreen(),
        '/signup_vehicle': (context) => const SignUpVehicleScreen(),
        '/otp': (context) {
          final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return OTPVerificationScreen(phone: args?['phone']);
        },
        '/success': (context) => const SuccessScreen(),
        '/home': (context) => const DriverHomeScreen(),
        '/available_trips': (context) => const AvailableTripsScreen(),
        '/available_trips_outside': (context) => const AvailableTripsScreen(isOutsideIraq: true),
        '/schedule_trip_info': (context) => const ScheduleTripInfoScreen(),
        '/mail_parcels': (context) => const MailParcelsScreen(),
        '/parcel_details': (context) => const MailParcelDetailsScreen(),
        '/ride_active': (context) => const RideActiveScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/profile_edit': (context) => const ProfileEditScreen(),
        '/payment': (context) => const PaymentMethodScreen(),
        '/add_credit': (context) => const AddCreditScreen(),
        '/card_code': (context) => const CardCodeScreen(),
        '/card_success': (context) => const CardSuccessScreen(),
        '/trips': (context) => const TripHistoryScreen(),
        '/schedule': (context) => const ScheduledTripsScreen(),
        '/language': (context) => const LanguageScreen(),
        '/support': (context) => const SupportScreen(),
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}
