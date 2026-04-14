import 'package:finance_control/app_router.dart';
import 'package:finance_control/core/migrations/migration_v2_categories.dart';
import 'package:finance_control/data/category_budget_repository.dart';
import 'package:finance_control/data/category_repository.dart';
import 'package:finance_control/data/local_storage.dart';
import 'package:finance_control/data/repository.dart';
import 'package:finance_control/features/budgets/presentation/category_budget_controller.dart';
import 'package:finance_control/features/categories/presentation/categories_controller.dart';
import 'package:finance_control/shared/state/date_filter_controller.dart';
import 'package:finance_control/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // iOS/Android status bar (notch area)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // fundo desenhado pelo app
      statusBarIconBrightness: Brightness.light, // Android
      statusBarBrightness: Brightness.dark, // iOS -> ícones claros
      systemNavigationBarColor: Colors.black, // Android
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await initializeDateFormatting('pt_BR');
  await MigrationV2Categories().run();

  runApp(const _Bootstrap());
}

class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FinanceRepository>(
          create: (_) => FinanceRepository(LocalStorage()),
        ),
        ChangeNotifierProvider<DateFilterController>(
          create: (_) => DateFilterController(),
        ),
        ChangeNotifierProvider<CategoriesController>(
          create: (_) => CategoriesController(CategoryRepository())..load(),
        ),
        Provider<CategoryBudgetRepository>(
          create: (_) => CategoryBudgetRepository(),
        ),
        ChangeNotifierProvider<CategoriesController>(
          create: (context) =>
              CategoriesController(context.read<CategoryRepository>())..load(),
        ),
      ],
      child: const FinanceApp(),
    );
  }
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: appRouter,
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
    );
  }
}
