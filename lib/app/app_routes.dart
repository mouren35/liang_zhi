import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liangzhi/features/add_food/add_food_page.dart';
import 'package:liangzhi/features/expirations/expirations_page.dart';
import 'package:liangzhi/features/food_detail/food_detail_page.dart';
import 'package:liangzhi/features/foods/foods_page.dart';
import 'package:liangzhi/features/home/home_page.dart';
import 'package:liangzhi/features/mine/mine_page.dart';
import 'package:liangzhi/features/mine/notification_settings_page.dart';
import 'package:liangzhi/features/scan/scan_page.dart';
import 'package:liangzhi/app/app_shell.dart';
import 'package:liangzhi/app/route_error_page.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/core/providers/service_providers.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/models/product_lookup.dart';

abstract final class AppRoutes {
  static const String home = '/home';
  static const String expirations = '/expirations';
  static const String scan = '/scan';
  static const String foods = '/foods';
  static const String addFood = '/add';
  static const String mine = '/mine';
  static const String notificationSettings = '/mine/notifications';
  static const String foodDetailPattern = '/foods/:foodId';

  static String foodDetail(String foodId) => '/foods/${Uri.encodeComponent(foodId)}';
}

GoRouter createAppRouter({
  String initialLocation = AppRoutes.home,
  ScannerViewBuilder? scannerBuilder,
}) {
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
                builder: (BuildContext context, GoRouterState state) => ScanPage(
                  scannerBuilder: scannerBuilder,
                  onProductFound: (ProductLookupResult result) async {
                    await context.push(AppRoutes.addFood, extra: result);
                  },
                  onManualFallback: (String barcode) async {
                    await context.push(
                      Uri(
                        path: AppRoutes.addFood,
                        queryParameters: <String, String>{
                          'barcode': barcode,
                        },
                      ).toString(),
                    );
                  },
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.foods,
                name: 'foods',
                builder: (BuildContext context, GoRouterState state) => FoodsPage(
                  onAddFood: () => context.push(AppRoutes.addFood),
                  onOpenFood: (String id) => context.push(AppRoutes.foodDetail(id)),
                ),
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
                      return FoodDetailPage(
                        foodId: foodId,
                        onBack: () => context.pop(),
                        onEdit: () {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('编辑能力将在后续版本完善')));
                        },
                      );
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
                builder: (BuildContext context, GoRouterState state) {
                  final ProviderContainer container = ProviderScope.containerOf(
                    context,
                  );
                  return MinePage(
                    config: AppConfig.current,
                    onOpenNotificationSettings: () => context.push(AppRoutes.notificationSettings),
                    onClearData: () => container.read(clearLocalDataServiceProvider).clear(),
                    onCleared: () => context.go(AppRoutes.home),
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'notifications',
                    name: 'notificationSettings',
                    builder: (BuildContext context, GoRouterState state) =>
                        NotificationSettingsPage(
                          onBack: () => context.pop(),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addFood,
        name: 'addFood',
        builder: (BuildContext context, GoRouterState state) {
          final ProductLookupResult? lookup = state.extra is ProductLookupResult
              ? state.extra! as ProductLookupResult
              : null;
          final ProductSuggestion? product = lookup?.product;
          return AddFoodPage(
            initialBarcode: product?.barcode ?? state.uri.queryParameters['barcode'],
            initialName: product?.name,
            initialBrand: product?.brand,
            initialSpecification: product?.specification,
            initialRemoteImageUrl: product?.imageUrl,
            initialCategoryId: product?.suggestedCategoryId,
            showRemoteDataWarning: lookup?.requiresConfirmation ?? false,
            onSaved: (Food food) {
              context.go(AppRoutes.foods);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('食品已添加')));
            },
            onCancel: () => context.pop(),
          );
        },
      ),
    ],
  );
}
