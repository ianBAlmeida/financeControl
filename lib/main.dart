import 'package:finance_control/app_router.dart';
import 'package:finance_control/shared/app_theme.dart';
import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  runApp(
    Provider<FinanceRepository>(
      create: (_) => FinanceRepository(LocalStorage()),
      child: const FinanceApp(),
    ),
  );
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: AppTheme.light.appBarTheme.copyWith(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      routerConfig: appRouter,
      builder: (ctx, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 60, 17, 134),
                Color.fromARGB(255, 136, 124, 158),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      },
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
