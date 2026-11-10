import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/account/data/address_api.dart';
import 'package:moonkage_verify/features/account/domain/delivery_address.dart';
import 'package:moonkage_verify/router.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, [DeliveryAddress? address]) async {
    final changed = await context.push<bool>(AppRoutes.addressForm, extra: address);
    if (changed == true) ref.invalidate(addressesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, DeliveryAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa chỉ?'),
        content: Text(
          'Bạn có chắc muốn xóa địa chỉ “${address.label.isEmpty ? address.fullAddress : address.label}”?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(addressApiProvider).delete(address.id);
      ref.invalidate(addressesProvider);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.failure(failure))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ địa chỉ'),
        actions: [
          IconButton(
            onPressed: () => _openForm(context, ref),
            tooltip: 'Thêm địa chỉ',
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: addresses.when(
        loading: () => const LoadingState(message: 'Đang tải địa chỉ…'),
        error: (error, _) => ErrorState(
          message: error is AppFailure ? Strings.failure(error) : 'Không thể tải sổ địa chỉ.',
          onRetry: () => ref.invalidate(addressesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.location_on_outlined,
              title: 'Chưa có địa chỉ nhận hàng',
              message: 'Thêm địa chỉ để thanh toán nhanh hơn trong những lần mua tiếp theo.',
              actionLabel: 'Thêm địa chỉ',
              onAction: () => _openForm(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(addressesProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = items[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(Icons.location_on_outlined, color: MoonkageColors.royalRed),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    address.label.isEmpty ? 'Địa chỉ nhận hàng' : address.label,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  if (address.isDefault)
                                    const Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text('Mặc định'),
                                      backgroundColor: MoonkageColors.paleGold,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${address.recipientName} · ${address.recipientPhone}'),
                              const SizedBox(height: 5),
                              Text(
                                address.fullAddress,
                                style: const TextStyle(color: MoonkageColors.mutedInk),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _openForm(context, ref, address);
                            if (value == 'delete') _delete(context, ref, address);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                            PopupMenuItem(value: 'delete', child: Text('Xóa')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: addresses.hasValue && addresses.requireValue.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm địa chỉ'),
            )
          : null,
    );
  }
}
