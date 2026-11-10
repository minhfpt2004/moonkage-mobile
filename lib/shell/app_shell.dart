import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/features/account/domain/delivery_region_provider.dart';
import 'package:moonkage_verify/features/cart/data/cart_api.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final province = ref.watch(deliveryProvinceProvider);
    final cart = ref.watch(cartProvider(province.code));
    final itemCount = cart.hasValue ? cart.requireValue.itemCount : 0;
    Widget cartIcon(IconData icon) => Badge(
      isLabelVisible: itemCount > 0,
      label: Text(itemCount > 99 ? '99+' : '$itemCount'),
      child: Icon(icon),
    );
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Danh mục',
          ),
          NavigationDestination(
            icon: cartIcon(Icons.shopping_bag_outlined),
            selectedIcon: cartIcon(Icons.shopping_bag_rounded),
            label: 'Giỏ hàng',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Đơn hàng',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
