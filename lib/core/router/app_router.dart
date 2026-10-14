import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../pages/login_page.dart';
import '../../pages/splash_page.dart';
import '../../pages/home_page.dart';
import '../../pages/order_detail_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashPage();
      },
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginPage();
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomePage();
      },
    ),
    GoRoute(
      path: '/order-detail/:docketNo',
      name: 'orderDetail',
      builder: (BuildContext context, GoRouterState state) {
        final docketNo = state.pathParameters['docketNo'] ?? '';
        return OrderDetailPage(docketNo: docketNo);
      },
    ),
  ],
);
