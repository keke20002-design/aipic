import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'viewmodels/analysis_viewmodel.dart';
import 'views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');
  runApp(const AipicApp());
}

class AipicApp extends StatelessWidget {
  const AipicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnalysisViewModel(),
      child: MaterialApp(
        title: 'AiPic',
        debugShowCheckedModeBanner: false,
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
    );
  }
}
