/* import 'package:flutter/material.dart';
import 'package:masarak_driver/core/widget/rating/screen/complain_screen.dart';
import 'package:masarak_driver/core/widget/splash_screen.dart';
import 'package:masarak_driver/features/activity/presentation/pages/ride_details_screen.dart';
import 'package:masarak_driver/features/auth/presentation/pages/auth_screen.dart';
import 'package:masarak_driver/features/auth/presentation/pages/otp_screen.dart';
import 'package:masarak_driver/features/home/presentation/pages/account_number_screen.dart';
import 'package:masarak_driver/features/home/presentation/pages/base_info_screen.dart';
import 'package:masarak_driver/features/home/presentation/pages/captain_register_screen.dart';
import 'package:masarak_driver/features/home/presentation/pages/car_info_screen.dart';
import 'package:masarak_driver/features/home/presentation/pages/driving_license_screen.dart';
import 'package:masarak_driver/features/home/presentation/pages/home_address_screen.dart';
import 'package:masarak_driver/features/home/presentation/pages/home_screen.dart';
import 'package:masarak_driver/features/home/presentation/pages/main_screen.dart';
import 'package:masarak_driver/features/home/presentation/pages/registered_home_screen.dart';
import 'package:masarak_driver/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:masarak_driver/features/onboarding/presentaion/onboarding_screen.dart';
import 'package:masarak_driver/features/settings/account/presentation/pages/account_Phone_screen.dart';
import 'package:masarak_driver/features/settings/account/presentation/pages/account_email_screen.dart';
import 'package:masarak_driver/features/settings/account/presentation/pages/account_name_screen.dart';
import 'package:masarak_driver/features/settings/account/presentation/pages/account_password_screen.dart';
import 'package:masarak_driver/features/settings/account/presentation/pages/account_screen.dart';
import 'package:masarak_driver/features/settings/help/domain/entity/help_page_entity.dart';
import 'package:masarak_driver/features/settings/help/presentation/help_screen.dart';
import 'package:masarak_driver/features/settings/help/presentation/pages/amount_paid_contact_screen.dart';
import 'package:masarak_driver/features/settings/help/presentation/pages/driver_asked_more_contact_screen.dart';
import 'package:masarak_driver/features/settings/help/presentation/pages/help_ride_screen.dart';
import 'package:masarak_driver/features/settings/help/presentation/pages/helper_contact_message_screen.dart';
import 'package:masarak_driver/features/settings/help/presentation/pages/lost_something_contact_screen.dart';
import 'package:masarak_driver/features/settings/help/presentation/pages/ride_problem_screen.dart';
import 'package:masarak_driver/features/settings/settings_screen/presentation/pages/chat_screen.dart';
import 'package:masarak_driver/features/settings/settings_screen/presentation/pages/language_screen.dart';
import 'package:masarak_driver/features/settings/settings_screen/presentation/pages/logout_screen.dart';
import 'package:masarak_driver/features/settings/settings_screen/presentation/pages/privacy_screen.dart';
import 'package:masarak_driver/features/settings/settings_screen/presentation/pages/who_are_we_screen.dart';
import 'package:masarak_driver/features/settings/wallet_screens/presentation/pages/add_paymentCard_screen.dart';
import 'package:masarak_driver/features/settings/wallet_screens/presentation/pages/add_paymentMethod_screen.dart';
import 'package:masarak_driver/features/settings/wallet_screens/presentation/pages/wallet_add_paymentMethod_screen.dart';
import 'package:masarak_driver/features/settings/wallet_screens/presentation/pages/wallet_charged_screen.dart';
import 'package:masarak_driver/features/trip/presentation/pages/select_trip_address_from_map.dart';
import 'package:masarak_driver/features/trip/presentation/pages/trip_details_screen_.dart';

import 'router_names.dart'; // Import the router names

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouterNames.init:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case RouterNames.onboardingScreen:
        // Accepting arguments
        //   final args = settings.arguments;
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case RouterNames.homeScreen:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouterNames.registeredHomeScreen:
        return MaterialPageRoute(builder: (_) => const RegisteredHomeScreen());
      case RouterNames.captainRegister:
        return MaterialPageRoute(builder: (_) => const CaptainRegisterScreen());
      case RouterNames.baseInfo:
        return MaterialPageRoute(builder: (_) => const BaseInfoScreen());
      case RouterNames.drivingLicenses:
        return MaterialPageRoute(builder: (_) => const DrivingLicenseScreen());
      case RouterNames.carInfo:
        return MaterialPageRoute(builder: (_) => const CarInfoScreen());
      case RouterNames.homeAddress:
        return MaterialPageRoute(builder: (_) => const HomeAddressScreen());
      case RouterNames.accountNumber:
        return MaterialPageRoute(builder: (_) => const AccountNumberScreen());
      case RouterNames.mainScreen:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case RouterNames.selectAddressFromInMap:
        return MaterialPageRoute(
            builder: (_) => const SelectTripAddressFromMapScreen());
      case RouterNames.tripDetailsMap:
        return MaterialPageRoute(builder: (_) => const TripDetailsScreen());
      case RouterNames.complainsScreen:
        return MaterialPageRoute(builder: (_) => const ComplainScreen());
      case RouterNames.chatScreen:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case RouterNames.notificationsScreen:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case RouterNames.authScreen:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case RouterNames.otpScreen:
        return MaterialPageRoute(builder: (_) => const OtpScreen());
      case RouterNames.rideDetailsScreen:
        return MaterialPageRoute(builder: (_) => const RideDetailsScreen());
      case RouterNames.walletAddPaymentMethodScreen:
        return MaterialPageRoute(
            builder: (_) => const WalletAddPaymentMethodScreen());
      case RouterNames.walletAddChargeScreen:
        return MaterialPageRoute(builder: (_) => const WalletAddChargeScreen());
      case RouterNames.addPaymentCardScreen:
        return MaterialPageRoute(builder: (_) => const AddPaymentCardScreen());
      case RouterNames.addPaymentMethodScreen:
        return MaterialPageRoute(
            builder: (_) => const AddPaymentMethodScreen());
      case RouterNames.accountScreen:
        return MaterialPageRoute(builder: (_) => const AccountScreen());
      case RouterNames.accountEmailScreen:
        return MaterialPageRoute(builder: (_) => const AccountEmailScreen());
      case RouterNames.accountPasswordScreen:
        return MaterialPageRoute(builder: (_) => const AccountPasswordScreen());
      case RouterNames.accountPhoneScreen:
        return MaterialPageRoute(builder: (_) => const AccountPhoneScreen());
      case RouterNames.accountNameScreen:
        return MaterialPageRoute(builder: (_) => const AccountNameScreen());
      case RouterNames.whoAreWeScreen:
        return MaterialPageRoute(builder: (_) => const WhoAreWeScreen());
      case RouterNames.privacyScreen:
        return MaterialPageRoute(builder: (_) => const PrivacyScreen());
      case RouterNames.languageScreen:
        return MaterialPageRoute(builder: (_) => const LanguageScreen());
      case RouterNames.logoutScreen:
        return MaterialPageRoute(builder: (_) => const LogoutScreen());
      case RouterNames.helpMainScreen:
        return MaterialPageRoute(builder: (_) => const HelpMainScreen());
      case RouterNames.helpRideScreen:
        return MaterialPageRoute(builder: (_) => const HelpRideScreen());
      case RouterNames.rideProblemScreen:
        return MaterialPageRoute(builder: (_) => const RideProblemScreen());
      case RouterNames.helperContactMessageScreen:
        final args = settings.arguments as HelpPageEntity;
        return MaterialPageRoute(
            builder: (_) => HelperContactMessageScreen(
                  helpPageEntity: args,
                ));
      case RouterNames.driverAskedMoreContactScreen:
        return MaterialPageRoute(
            builder: (_) => const DriverAskedMoreContactScreen());
      case RouterNames.amountPaidContactScreen:
        return MaterialPageRoute(
            builder: (_) => const AmountPaidContactScreen());
      case RouterNames.lostSomethingContactScreen:
        return MaterialPageRoute(
            builder: (_) => const LostSomethingContactScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
 */
