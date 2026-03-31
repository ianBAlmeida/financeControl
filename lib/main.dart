import 'package:finance_control/app_router.dart';
import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/shared/theme/app_theme.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  runApp(
    MultiProvider(
      providers: [
        Provider<FinanceRepository>(
          create: (_) => FinanceRepository(LocalStorage()),
        ),
        ChangeNotifierProvider<DateFilterController>(
          create: (_) => DateFilterController(),
        ),
      ],
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
      theme: AppTheme.dark(),
      routerConfig: appRouter,
      builder: (ctx, child) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3C1186), Color(0xFF887C9E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
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
