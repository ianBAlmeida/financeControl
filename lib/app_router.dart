import 'package:finance_control/features/categories/presentation/category_page.dart';
import 'package:finance_control/features/debit/debit_page.dart';
import 'package:finance_control/features/credit/installments_page.dart';
import 'package:finance_control/features/dashboard/dashboard_page.dart';
import 'package:finance_control/features/credit/credit_month.dart';
import 'package:finance_control/features/history/history_page.dart';
import 'package:finance_control/features/summary/summary_page.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardPage(),
      routes: [
        GoRoute(path: 'debit', builder: (context, state) => const DebitPage()),
        GoRoute(
          path: 'credit',
          builder: (context, state) => const CreditPage(),
        ),
        GoRoute(
          path: 'installments',
          builder: (context, state) => const InstallmentsPage(),
        ),
        GoRoute(
          path: 'summary',
          builder: (context, state) => const SummaryPage(),
        ),
        GoRoute(
          path: 'history',
          builder: (context, state) => const HistoryPage(),
        ),
        GoRoute(
          path: 'category',
          builder: (context, state) => const CategoriesPage(),
        ),
      ],
    ),
  ],
);
