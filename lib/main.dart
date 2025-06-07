// lib/main.dart
//a

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 서비스 임포트
import 'package:health_app/services/auth_service.dart';
import 'package:health_app/services/data_service.dart';

// 화면 임포트
import 'package:health_app/screens/login_screen.dart';
import 'package:health_app/screens/main_screen.dart';
import 'package:health_app/screens/signup_screen.dart'; // 이 파일은 SignupHealthScreen으로 대체될 예정입니다.
import 'package:health_app/screens/signup_profile_screen.dart';
import 'package:health_app/screens/signup_health_screen.dart';
import 'package:health_app/screens/potential_disease_management_screen.dart';
import 'package:health_app/screens/add_medication_screen.dart';
import 'package:health_app/screens/manage_concerned_diseases_screen.dart';
import 'package:health_app/screens/my_account_screen.dart';
import 'package:health_app/screens/app_settings_screen.dart';
import 'package:health_app/screens/terms_of_service_screen.dart';
import 'package:health_app/screens/privacy_policy_screen.dart';
import 'package:health_app/screens/manage_diagnosed_diseases_screen.dart';
import 'package:health_app/screens/vital_signs_screen.dart'; // VitalSignsScreen 임포트 추가

// 모델 임포트 (필요한 경우)
import 'package:health_app/models/potential_disease_memo.dart';
import 'package:health_app/models/medication.dart';

// 앱 전체의 테마 상태를 관리하기 위한 ValueNotifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

// 서비스 인스턴스 (전역적으로 접근 가능하도록 선언)
final AuthService authService = AuthService();
// DataService 생성 시 authService 인스턴스 전달
final DataService dataService = DataService(authService);

// main 함수
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await authService.init();

  final prefs = await SharedPreferences.getInstance();
  final String? themeModeName = prefs.getString('themeMode');
  ThemeMode initialThemeMode;
  if (themeModeName == 'dark') {
    initialThemeMode = ThemeMode.dark;
  } else if (themeModeName == 'light') {
    initialThemeMode = ThemeMode.light;
  } else {
    initialThemeMode = ThemeMode.system;
  }

  runApp(MyApp(initialThemeMode: initialThemeMode));
}

// MyApp 클래스: 앱의 최상위 위젯, 테마 및 라우팅 관리
class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  const MyApp({Key? key, required this.initialThemeMode}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _currentThemeMode;

  @override
  void initState() {
    super.initState();
    _currentThemeMode = widget.initialThemeMode;
    themeNotifier.value = _currentThemeMode;
    themeNotifier.addListener(() {
      if (mounted && _currentThemeMode != themeNotifier.value) {
        setState(() {
          _currentThemeMode = themeNotifier.value;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '건강 관리 앱',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.teal)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Colors.teal)),
        cardTheme: CardTheme(elevation: 2.0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 0)),
        listTileTheme: ListTileThemeData(iconColor: Colors.teal[700]),
        appBarTheme: AppBarTheme(backgroundColor: Colors.teal, foregroundColor: Colors.white),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.dark(
            primary: Colors.tealAccent,
            secondary: Colors.tealAccent,
            surface: Colors.grey[850]!,
            background: Colors.grey[900]!,
            onPrimary: Colors.black,
            onSecondary: Colors.black,
            onSurface: Colors.white,
            onBackground: Colors.white,
            error: Colors.redAccent,
            onError: Colors.black),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey[600]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.tealAccent)),
            filled: true,
            fillColor: Colors.grey[800]),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)))),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Colors.tealAccent)),
        cardTheme: CardTheme(elevation: 2.0, color: Colors.grey[850], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 0)),
        listTileTheme: ListTileThemeData(iconColor: Colors.tealAccent[100]),
        appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900], foregroundColor: Colors.white),
      ),
      themeMode: _currentThemeMode,
      home: authService.isLoggedIn() ? MainScreen() : LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupProfileScreen(), // SignUpScreen 대신 SignupProfileScreen으로 변경
        '/main': (context) => MainScreen(),
        '/potential_disease_management': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          PotentialDiseaseMemo? memoToEdit;
          if (args is PotentialDiseaseMemo) memoToEdit = args;
          return PotentialDiseaseManagementScreen(memoToEdit: memoToEdit);
        },
        '/add_medication': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? initialDiseaseName;
          if (args is String) {
            initialDiseaseName = args;
          }
          return AddMedicationScreen(initialDiseaseName: initialDiseaseName);
        },
        '/manage_concerned_diseases': (context) => ManageConcernedDiseasesScreen(),
        '/my_account': (context) => MyAccountScreen(),
        '/app_settings': (context) => AppSettingsScreen(),
        '/terms_of_service': (context) => TermsOfServiceScreen(),
        '/privacy_policy': (context) => PrivacyPolicyScreen(),
        '/manage_diagnosed_diseases': (context) => ManageDiagnosedDiseasesScreen(),
      },
    );
  }
}