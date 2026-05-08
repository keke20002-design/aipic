import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'services/ad_service.dart';
import 'viewmodels/analysis_viewmodel.dart';
import 'views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await MobileAds.instance.initialize();
    AdService().preloadRewardedAd();
  }

  // 저장된 언어 복원, 없으면 기기 언어 자동 감지
  final prefs = await SharedPreferences.getInstance();
  const supported = ['ko', 'en', 'ja', 'vi'];
  final saved = prefs.getString('app_locale');
  final String localeCode;
  if (saved != null) {
    localeCode = saved;
  } else {
    final deviceLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    localeCode = supported.contains(deviceLang) ? deviceLang : 'ko';
  }

  runApp(AipicApp(initialLocale: Locale(localeCode)));
}

class LocaleProvider extends ChangeNotifier {
  Locale _locale;
  LocaleProvider(this._locale);

  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', locale.languageCode);
    notifyListeners();
  }
}

class AipicApp extends StatelessWidget {
  final Locale initialLocale;
  const AipicApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnalysisViewModel()),
        ChangeNotifierProvider(create: (_) => LocaleProvider(initialLocale)),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
          title: 'A.I Room Roast',
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C5CE7),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F8FA),
            useMaterial3: true,
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shadowColor: Colors.black.withAlpha(20),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            textTheme: const TextTheme(
              titleLarge: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
                height: 1.4,
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
                height: 1.4,
              ),
              titleSmall: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
                height: 1.4,
              ),
              bodyLarge: TextStyle(
                fontSize: 15,
                color: Color(0xFF444444),
                height: 1.5,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.5,
              ),
              bodySmall: TextStyle(
                fontSize: 13,
                color: Color(0xFF888888),
                height: 1.5,
              ),
            ),
          ),
          home: const HomeView(),
        ),
      ),
    );
  }
}
