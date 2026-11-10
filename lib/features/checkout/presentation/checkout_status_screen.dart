import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/platform/external_url_launcher.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/features/cart/data/cart_api.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';
import 'package:moonkage_verify/features/checkout/data/checkout_api.dart';
import 'package:moonkage_verify/features/checkout/domain/checkout.dart';
import 'package:moonkage_verify/router.dart';

class CheckoutStatusScreen extends ConsumerStatefulWidget {
  const CheckoutStatusScreen({required this.checkoutId, this.created, super.key});

  final String checkoutId;
  final CheckoutCreated? created;

  @override
  ConsumerState<CheckoutStatusScreen> createState() => _CheckoutStatusScreenState();
}

class _CheckoutStatusScreenState extends ConsumerState<CheckoutStatusScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  CheckoutResult? _result;
  String? _error;
  var _loading = true;
  var _opening = false;
  var _polls = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.created != null) await _openPayment();
      await _poll();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _poll();
  }

  Future<void> _openPayment() async {
    final url = widget.created?.paymentUrl;
    if (url == null || url.isEmpty || _opening) return;
    setState(() => _opening = true);
    try {
      final opened = await ref.read(externalUrlLauncherProvider).open(url);
      if (!opened && mounted) setState(() => _error = 'Không thể mở trình duyệt thanh toán.');
    } on Object {
      if (mounted) setState(() => _error = 'Không thể mở trình duyệt thanh toán.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _poll() async {
    if (!mounted || (_result?.status.isFinal ?? false) || _polls >= 30) return;
    _polls++;
    try {
      final result = await ref.read(checkoutApiProvider).get(widget.checkoutId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
        _error = null;
      });
      if (result.status == CheckoutStatus.succeeded) {
        _timer?.cancel();
        ref.invalidate(cartProvider);
      } else if (result.status.isFinal) {
        _timer?.cancel();
      }
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = Strings.failure(failure);
      });
    }
  }

  Future<void> _manualRefresh() async {
    _polls = 0;
    setState(() => _loading = true);
    await _poll();
  }

  @override
  Widget build(BuildContext context) {
    final status = _result?.status ?? CheckoutStatus.pendingPayment;
    final presentation = _presentation(status);
    final amount = _result?.totalAmount ?? widget.created?.totalAmount ?? 0;
    final expiresAt = _result?.expiresAt ?? widget.created?.expiresAt;
    return Scaffold(
      appBar: AppBar(title: const Text('Trạng thái thanh toán')),
      body: RefreshIndicator(
        onRefresh: _manualRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: presentation.background, shape: BoxShape.circle),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Icon(presentation.icon, size: 52, color: presentation.color),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _loading ? 'Đang kiểm tra thanh toán…' : presentation.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              presentation.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MoonkageColors.mutedInk),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _DetailRow(label: 'Mã checkout', value: widget.checkoutId),
                    const Divider(height: 24),
                    _DetailRow(label: 'Tổng thanh toán', value: formatVnd(amount)),
                    if (expiresAt != null) ...[
                      const Divider(height: 24),
                      _DetailRow(label: 'Giữ hàng đến', value: _formatDate(expiresAt)),
                    ],
                    if (_result?.orderIds.isNotEmpty ?? false) ...[
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Đơn đã tạo',
                        value: '${_result!.orderIds.length} đơn',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 22),
            if (status == CheckoutStatus.pendingPayment && widget.created != null)
              FilledButton.icon(
                onPressed: _opening ? null : _openPayment,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(_opening ? 'Đang mở…' : 'Mở lại trang VNPay'),
              ),
            if (status == CheckoutStatus.succeeded)
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.orders),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Xem đơn hàng'),
              ),
            if (status.isFinal && status != CheckoutStatus.succeeded)
              FilledButton(
                onPressed: () => context.go(AppRoutes.cart),
                child: const Text('Quay lại giỏ hàng'),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loading ? null : _manualRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Kiểm tra lại trạng thái'),
            ),
          ],
        ),
      ),
    );
  }

  static _StatusPresentation _presentation(CheckoutStatus status) => switch (status) {
    CheckoutStatus.succeeded => const _StatusPresentation(
      icon: Icons.check_circle_rounded,
      color: MoonkageColors.jade,
      background: MoonkageColors.paleJade,
      title: 'Thanh toán thành công',
      message: 'Backend đã nhận xác nhận từ VNPay và tạo đơn theo từng shop.',
    ),
    CheckoutStatus.failed => const _StatusPresentation(
      icon: Icons.cancel_rounded,
      color: MoonkageColors.royalRed,
      background: Color(0xFFFFE8E5),
      title: 'Thanh toán không thành công',
      message: 'Giao dịch bị từ chối và hàng đã được trả lại kho.',
    ),
    CheckoutStatus.expired => const _StatusPresentation(
      icon: Icons.timer_off_outlined,
      color: MoonkageColors.royalRed,
      background: Color(0xFFFFE8E5),
      title: 'Phiên thanh toán đã hết hạn',
      message: 'Thời gian giữ hàng đã kết thúc. Bạn có thể tạo checkout mới từ giỏ hàng.',
    ),
    CheckoutStatus.refundRequested => const _StatusPresentation(
      icon: Icons.currency_exchange_rounded,
      color: Color(0xFF9B6B00),
      background: MoonkageColors.paleGold,
      title: 'Đang yêu cầu hoàn tiền',
      message: 'Thanh toán đến muộn sau khi hết thời gian giữ hàng. Hệ thống đang xử lý hoàn tiền.',
    ),
    CheckoutStatus.pendingPayment || CheckoutStatus.unknown => const _StatusPresentation(
      icon: Icons.hourglass_top_rounded,
      color: Color(0xFF9B6B00),
      background: MoonkageColors.paleGold,
      title: 'Đang chờ xác nhận',
      message: 'Hệ thống đang chờ xác nhận server-to-server từ VNPay. Bạn có thể kéo xuống để kiểm tra lại.',
    ),
  };

  static String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.hour)}:${two(value.minute)} ${two(value.day)}/${two(value.month)}/${value.year}';
  }
}

final class _StatusPresentation {
  const _StatusPresentation({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String message;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: MoonkageColors.mutedInk)),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
