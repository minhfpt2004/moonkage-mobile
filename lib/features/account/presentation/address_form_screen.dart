import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/reference/vietnam_provinces.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/features/account/data/address_api.dart';
import 'package:moonkage_verify/features/account/domain/delivery_address.dart';
import 'package:moonkage_verify/features/auth/presentation/widgets/auth_form_support.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({this.address, super.key});

  final DeliveryAddress? address;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _recipientName;
  late final TextEditingController _recipientPhone;
  late final TextEditingController _wardName;
  late final TextEditingController _detail;
  late final TextEditingController _label;
  late String _provinceCode;
  late bool _isDefault;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _recipientName = TextEditingController(text: address?.recipientName ?? '');
    _recipientPhone = TextEditingController(text: address?.recipientPhone ?? '');
    _wardName = TextEditingController(text: address?.wardName ?? '');
    _detail = TextEditingController(text: address?.detail ?? '');
    _label = TextEditingController(text: address?.label ?? '');
    _provinceCode = address?.provinceCode ?? vietnamProvinces.first.code;
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _recipientName.dispose();
    _recipientPhone.dispose();
    _wardName.dispose();
    _detail.dispose();
    _label.dispose();
    super.dispose();
  }

  String? _requiredLimited(String? value, int maxLength) {
    final requiredError = AuthValidators.required(value);
    if (requiredError != null) return requiredError;
    return value!.trim().length <= maxLength ? null : 'Không được vượt quá $maxLength ký tự.';
  }

  String? _phoneValidator(String? value) {
    final requiredError = AuthValidators.required(value);
    return requiredError ?? AuthValidators.phone(value);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final province = provinceByCode(_provinceCode);
    final draft = AddressDraft(
      recipientName: _recipientName.text.trim(),
      recipientPhone: _recipientPhone.text.trim(),
      provinceCode: province.code,
      provinceName: province.name,
      wardName: _wardName.text.trim(),
      detail: _detail.text.trim(),
      label: _label.text.trim().isEmpty ? null : _label.text.trim(),
      isDefault: _isDefault,
    );
    try {
      final api = ref.read(addressApiProvider);
      if (_editing) {
        await api.update(widget.address!.id, draft);
      } else {
        await api.create(draft);
      }
      if (mounted) context.pop(true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = Strings.failure(failure));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_editing ? 'Chỉnh sửa địa chỉ' : 'Thêm địa chỉ')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _recipientName,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Tên người nhận'),
              validator: (value) => _requiredLimited(value, 100),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _recipientPhone,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Số điện thoại người nhận'),
              validator: _phoneValidator,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _provinceCode,
              decoration: const InputDecoration(labelText: 'Tỉnh / thành phố'),
              items: [
                for (final province in vietnamProvinces)
                  DropdownMenuItem(value: province.code, child: Text(province.name)),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _provinceCode = value);
                    },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _wardName,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Phường / xã'),
              validator: (value) => _requiredLimited(value, 100),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _detail,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Số nhà, tên đường'),
              validator: (value) => _requiredLimited(value, 255),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _label,
              enabled: !_saving,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Nhãn địa chỉ (không bắt buộc)',
                hintText: 'Nhà riêng, Văn phòng…',
              ),
              validator: (value) =>
                  (value?.trim().length ?? 0) <= 30 ? null : 'Nhãn không được vượt quá 30 ký tự.',
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đặt làm địa chỉ mặc định'),
              subtitle: const Text('Địa chỉ mặc định được ưu tiên khi thanh toán.'),
              value: _isDefault,
              onChanged: _saving ? null : (value) => setState(() => _isDefault = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_editing ? 'Lưu thay đổi' : 'Thêm địa chỉ'),
            ),
          ],
        ),
      ),
    ),
  );
}
