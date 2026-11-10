import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/account/domain/delivery_region_provider.dart';
import 'package:moonkage_verify/features/catalog/data/catalog_api.dart';
import 'package:moonkage_verify/features/catalog/domain/catalog_filter.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';
import 'package:moonkage_verify/features/catalog/presentation/widgets/product_card.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  late CatalogFilter _filter;
  List<Product> _products = const [];
  List<CakeAttribute> _attributes = const [];
  ProductFacets? _facets;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  int _requestId = 0;
  String _provinceCode = '';

  @override
  void initState() {
    super.initState();
    _filter = const CatalogFilter(provinceCode: '01');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload({CatalogFilter? filter}) async {
    final nextFilter = filter ?? _filter;
    final requestId = ++_requestId;
    setState(() {
      _filter = nextFilter;
      _loading = true;
      _error = null;
      _products = const [];
      _page = 0;
    });
    try {
      final api = ref.read(catalogApiProvider);
      final results = await Future.wait<Object>([
        api.search(nextFilter),
        api.getFacets(nextFilter.provinceCode, query: nextFilter.query),
        if (_attributes.isEmpty) api.getCakeAttributes() else Future.value(_attributes),
      ]);
      if (!mounted || requestId != _requestId) return;
      final page = results[0] as ProductPage;
      setState(() {
        _products = page.content;
        _page = page.page;
        _totalPages = page.totalPages;
        _totalElements = page.totalElements;
        _facets = results[1] as ProductFacets;
        _attributes = results[2] as List<CakeAttribute>;
      });
    } on AppFailure catch (failure) {
      if (mounted && requestId == _requestId) {
        setState(() => _error = Strings.failure(failure));
      }
    } finally {
      if (mounted && requestId == _requestId) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page + 1 >= _totalPages) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(catalogApiProvider).search(_filter, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _products = [..._products, ...page.content];
        _page = page.page;
        _totalPages = page.totalPages;
        _totalElements = page.totalElements;
      });
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(Strings.failure(failure))));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _reload(filter: _filter.copyWith(query: value)),
    );
  }

  String _attributeLabel(String code) =>
      _attributes
          .where((attribute) => attribute.code == code)
          .map((attribute) => attribute.label)
          .firstOrNull ??
      code;

  int get _activeFilterCount =>
      _filter.brands.length +
      _filter.crusts.length +
      _filter.fillings.length +
      (_filter.priceMin == null && _filter.priceMax == null ? 0 : 1);

  Future<void> _showFilters() async {
    final facets = _facets;
    if (facets == null) return;
    var brands = {..._filter.brands};
    var crusts = {..._filter.crusts};
    var fillings = {..._filter.fillings};
    final facetMin = facets.priceMin ?? 0;
    final facetMax = facets.priceMax ?? facetMin;
    var range = RangeValues(
      (_filter.priceMin ?? facetMin).toDouble(),
      (_filter.priceMax ?? facetMax).toDouble(),
    );
    final result = await showModalBottomSheet<CatalogFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          maxChildSize: 0.95,
          builder: (context, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Bộ lọc sản phẩm', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    TextButton(
                      onPressed: () => setModalState(() {
                        brands = {};
                        crusts = {};
                        fillings = {};
                        range = RangeValues(facetMin.toDouble(), facetMax.toDouble());
                      }),
                      child: const Text('Xóa lọc'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _FilterSection(
                      title: 'Vỏ bánh',
                      values: facets.crusts,
                      selected: crusts,
                      labelOf: _attributeLabel,
                      onToggle: (value) => setModalState(() => crusts = _toggle(crusts, value)),
                    ),
                    _FilterSection(
                      title: 'Vị nhân',
                      values: facets.fillings,
                      selected: fillings,
                      labelOf: _attributeLabel,
                      onToggle: (value) => setModalState(() => fillings = _toggle(fillings, value)),
                    ),
                    _FilterSection(
                      title: 'Thương hiệu',
                      values: facets.brands,
                      selected: brands,
                      labelOf: (value) => value,
                      onToggle: (value) => setModalState(() => brands = _toggle(brands, value)),
                    ),
                    if (facetMax > facetMin) ...[
                      const SizedBox(height: 16),
                      Text('Khoảng giá', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text('${formatVnd(range.start.round())} – ${formatVnd(range.end.round())}'),
                      RangeSlider(
                        values: range,
                        min: facetMin.toDouble(),
                        max: facetMax.toDouble(),
                        onChanged: (value) => setModalState(() => range = value),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    CatalogFilter(
                      provinceCode: _filter.provinceCode,
                      query: _filter.query,
                      brands: brands,
                      crusts: crusts,
                      fillings: fillings,
                      priceMin: facetMax > facetMin && range.start.round() > facetMin
                          ? range.start.round()
                          : null,
                      priceMax: facetMax > facetMin && range.end.round() < facetMax
                          ? range.end.round()
                          : null,
                      sort: _filter.sort,
                    ),
                  ),
                  child: const Text('Áp dụng bộ lọc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) await _reload(filter: result);
  }

  Set<String> _toggle(Set<String> values, String value) =>
      values.contains(value) ? ({...values}..remove(value)) : {...values, value};

  @override
  Widget build(BuildContext context) {
    final province = ref.watch(deliveryProvinceProvider);
    if (_provinceCode != province.code) {
      _provinceCode = province.code;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reload(filter: _filter.copyWith(provinceCode: province.code));
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục bánh'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.location_on_outlined, size: 17),
              label: Text(province.name),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: _searchChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                _reload(filter: _filter.copyWith(query: value));
              },
              decoration: InputDecoration(
                hintText: 'Tìm bánh, thương hiệu…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          _reload(filter: _filter.copyWith(query: ''));
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: _activeFilterCount > 0,
                  label: Text('$_activeFilterCount'),
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _showFilters,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Bộ lọc'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_filter.sort),
                    initialValue: _filter.sort,
                    decoration: const InputDecoration(
                      labelText: 'Sắp xếp',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'rating', child: Text('Đánh giá cao')),
                      DropdownMenuItem(value: 'newest', child: Text('Mới nhất')),
                      DropdownMenuItem(value: 'price-asc', child: Text('Giá tăng dần')),
                      DropdownMenuItem(value: 'price-desc', child: Text('Giá giảm dần')),
                    ],
                    onChanged: _loading
                        ? null
                        : (value) {
                            if (value != null) _reload(filter: _filter.copyWith(sort: value));
                          },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) return const LoadingState(message: 'Đang tải danh sách bánh…');
    if (_error != null) return ErrorState(message: _error!, onRetry: _reload);
    if (_products.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy sản phẩm',
        message: 'Thử thay đổi từ khóa hoặc bỏ bớt bộ lọc.',
        actionLabel: _filter.hasFilters ? 'Xóa bộ lọc' : null,
        onAction: _filter.hasFilters
            ? () {
                _search.clear();
                _reload(filter: CatalogFilter(provinceCode: _filter.provinceCode));
              }
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Tìm thấy $_totalElements sản phẩm',
                style: const TextStyle(color: MoonkageColors.mutedInk),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid.builder(
              itemCount: _products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (_, index) => ProductCard(product: _products[index]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _page + 1 < _totalPages
                  ? OutlinedButton(
                      onPressed: _loadingMore ? null : _loadMore,
                      child: _loadingMore
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Xem thêm sản phẩm'),
                    )
                  : const SizedBox(height: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
  });

  final String title;
  final List<FacetValue> values;
  final Set<String> selected;
  final String Function(String) labelOf;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in values)
                FilterChip(
                  selected: selected.contains(item.value),
                  onSelected: (_) => onToggle(item.value),
                  label: Text('${labelOf(item.value)} (${item.count})'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
