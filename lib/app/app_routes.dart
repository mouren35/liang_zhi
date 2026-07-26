import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liangzhi/features/add_food/add_food_page.dart';
import 'package:liangzhi/features/expirations/expirations_page.dart';
import 'package:liangzhi/features/food_detail/food_detail_page.dart';
import 'package:liangzhi/features/foods/foods_page.dart';
import 'package:liangzhi/features/home/home_page.dart';
import 'package:liangzhi/features/mine/mine_page.dart';
import 'package:liangzhi/features/scan/scan_page.dart';
import 'package:liangzhi/app/app_shell.dart';
import 'package:liangzhi/app/route_error_page.dart';

abstract final class AppRoutes {
  static const String home = '/home';
  static const String expirations = '/expirations';
  static const String scan = '/scan';
  static const String foods = '/foods';
  static const String addFood = '/add';
  static const String mine = '/mine';
  static const String foodDetailPattern = '/foods/:foodId';

  static String foodDetail(String foodId) => '/foods/${Uri.encodeComponent(foodId)}';
}

GoRouter createAppRouter({String initialLocation = AppRoutes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (BuildContext context, GoRouterState state) {
      return RouteErrorPage(onReturnHome: () => context.go(AppRoutes.home));
    },
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (BuildContext context, GoRouterState state) => HomePage(
                  onAddFood: () => context.push(AppRoutes.addFood),
                  onOpenExpirations: () => context.go(AppRoutes.expirations),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.expirations,
                name: 'expirations',
                builder: (BuildContext context, GoRouterState state) => ExpirationsPage(
                  onOpenSettings: () => context.go(AppRoutes.mine),
                  onOpenFood: (String id) => context.push(AppRoutes.foodDetail(id)),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.scan,
                name: 'scan',
                builder: (BuildContext context, GoRouterState state) => const ScanPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.foods,
                name: 'foods',
                builder: (BuildContext context, GoRouterState state) => const FoodsPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':foodId',
                    name: 'foodDetail',
                    builder: (BuildContext context, GoRouterState state) {
                      final String foodId = state.pathParameters['foodId'] ?? '';
                      if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(foodId)) {
                        return RouteErrorPage(
                          message: '食品链接无效',
                          onReturnHome: () => context.go(AppRoutes.home),
                        );
                      }
                      return FoodDetailPage(foodId: foodId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.mine,
                name: 'mine',
                builder: (BuildContext context, GoRouterState state) => const MinePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addFood,
        name: 'addFood',
        builder: (BuildContext context, GoRouterState state) => const AddFoodPage(),
      ),
    ],
  );
}
