import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/orders/views/home_screen.dart';
import '../../features/orders/views/order_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/order-detail/:docketNo',
      name: 'orderDetail',
      builder: (BuildContext context, GoRouterState state) {
        final docketNo = state.pathParameters['docketNo'] ?? '';
        return OrderDetailScreen(docketNo: docketNo);
      },
    ),
  ],
);
