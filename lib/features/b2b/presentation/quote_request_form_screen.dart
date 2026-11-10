import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/features/account/data/address_api.dart';
import 'package:moonkage_verify/features/account/domain/delivery_address.dart';
import 'package:moonkage_verify/features/b2b/data/quotation_api.dart';
import 'package:moonkage_verify/features/b2b/domain/quotation.dart';
import 'package:moonkage_verify/router.dart';

class QuoteRequestFormScreen extends ConsumerStatefulWidget {
  const QuoteRequestFormScreen({this.initialVendorId, super.key});

  final String? initialVendorId;

  @override
  ConsumerState<QuoteRequestFormScreen> createState() => _QuoteRequestFormScreenState();
}

class _QuoteRequestFormScreenState extends ConsumerState<QuoteRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '50');
  final _budgetController = TextEditingController();
  final _specController = TextEditingController();
  late QuoteRequestType _type;
  String? _vendorId;
  String? _addressId;
  final _customTypes = <CustomType>{};
  late DateTime _deadline;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _vendorId = widget.initialVendorId;
    _type = _vendorId == null ? QuoteRequestType.open : QuoteRequestType.direct;
    _deadline = DateTime.now().add(const Duration(days: 21));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _budgetController.dispose();
    _specController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _deadline = selected);
  }

  Future<void> _submit(List<DeliveryAddress> addresses) async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    final address = addresses.where((item) => item.id == _addressId).firstOrNull;
    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final created = await ref
          .read(quotationApiProvider)
          .create(
            QuoteRequestDraft(
              type: _type,
              targetVendorId: _vendorId,
              quantity: int.parse(_quantityController.text),
              budget: int.tryParse(_budgetController.text.replaceAll(RegExp(r'\D'), '')),
              customTypes: _customTypes,
              customSpec: _specController.text,
              deliveryDeadline: _deadline,
              delivery: QuoteDelivery(
                recipientName: address.recipientName,
                recipientPhone: address.recipientPhone,
                provinceCode: address.provinceCode,
                addressDetail: address.fullAddress.isNotEmpty
                    ? address.fullAddress
                    : '${address.detail}, ${address.wardName}, ${address.provinceName}',
              ),
            ),
          );
      ref.invalidate(quoteRequestsProvider);
      if (mounted) context.go(AppRoutes.quoteRequest(created.id));
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(addressesProvider);
    final suppliers = ref.watch(suppliersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo yêu cầu báo giá')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SegmentedButton<QuoteRequestType>(
              segments: QuoteRequestType.values
                  .map((type) => ButtonSegment(value: type, label: Text(type.label)))
                  .toList(growable: false),
              selected: {_type},
              onSelectionChanged: (value) => setState(() {
                _type = value.single;
                if (_type == QuoteRequestType.open) _vendorId = null;
              }),
            ),
            const SizedBox(height: 18),
            if (_type == QuoteRequestType.direct)
              suppliers.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => OutlinedButton(
                  onPressed: () => ref.invalidate(suppliersProvider),
                  child: const Text('Tải lại nhà cung cấp'),
                ),
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: items.any((item) => item.id == _vendorId) ? _vendorId : null,
                  decoration: const InputDecoration(labelText: 'Nhà cung cấp'),
                  items: items
                      .where((item) => !item.isOwn)
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.businessName, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _vendorId = value),
                  validator: (value) => value == null ? 'Hãy chọn nhà cung cấp' : null,
                ),
              ),
            if (_type == QuoteRequestType.direct) const SizedBox(height: 14),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số lượng cần đặt'),
              validator: (value) {
                final quantity = int.tryParse(value ?? '');
                return quantity == null || quantity <= 0 ? 'Số lượng phải lớn hơn 0' : null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ngân sách dự kiến (không bắt buộc)',
                suffixText: 'đ',
              ),
            ),
            const SizedBox(height: 18),
            Text('Tùy chỉnh mong muốn', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CustomType.values
                  .map(
                    (type) => FilterChip(
                      label: Text(type.label),
                      selected: _customTypes.contains(type),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _customTypes.add(type);
                        } else {
                          _customTypes.remove(type);
                        }
                      }),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _specController,
              maxLength: 2000,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mô tả yêu cầu',
                hintText: 'Màu sắc, nội dung in, cách đóng gói…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.event_outlined),
              title: const Text('Hạn giao mong muốn'),
              subtitle: Text(_formatDate(_deadline)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDeadline,
            ),
            const SizedBox(height: 8),
            addresses.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => OutlinedButton(
                onPressed: () => ref.invalidate(addressesProvider),
                child: const Text('Tải lại địa chỉ'),
              ),
              data: (items) {
                _addressId ??= items.where((item) => item.isDefault).firstOrNull?.id;
                _addressId ??= items.firstOrNull?.id;
                return DropdownButtonFormField<String>(
                  initialValue: _addressId,
                  decoration: const InputDecoration(labelText: 'Địa chỉ giao hàng'),
                  items: items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.fullAddress, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _addressId = value),
                  validator: (value) => value == null ? 'Hãy chọn địa chỉ giao hàng' : null,
                );
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: addresses.hasValue && !_submitting
                  ? () => _submit(addresses.requireValue)
                  : null,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_submitting ? 'Đang gửi…' : 'Gửi yêu cầu báo giá'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
