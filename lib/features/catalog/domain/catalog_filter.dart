final class CatalogFilter {
  const CatalogFilter({
    required this.provinceCode,
    this.query = '',
    this.brands = const {},
    this.crusts = const {},
    this.fillings = const {},
    this.priceMin,
    this.priceMax,
    this.sort = 'rating',
  });

  final String provinceCode;
  final String query;
  final Set<String> brands;
  final Set<String> crusts;
  final Set<String> fillings;
  final int? priceMin;
  final int? priceMax;
  final String sort;

  bool get hasFilters =>
      query.isNotEmpty ||
      brands.isNotEmpty ||
      crusts.isNotEmpty ||
      fillings.isNotEmpty ||
      priceMin != null ||
      priceMax != null;

  CatalogFilter copyWith({
    String? provinceCode,
    String? query,
    Set<String>? brands,
    Set<String>? crusts,
    Set<String>? fillings,
    int? priceMin,
    int? priceMax,
    bool clearPrice = false,
    String? sort,
  }) => CatalogFilter(
    provinceCode: provinceCode ?? this.provinceCode,
    query: query ?? this.query,
    brands: brands ?? this.brands,
    crusts: crusts ?? this.crusts,
    fillings: fillings ?? this.fillings,
    priceMin: clearPrice ? null : priceMin ?? this.priceMin,
    priceMax: clearPrice ? null : priceMax ?? this.priceMax,
    sort: sort ?? this.sort,
  );

  Map<String, Object?> toQueryParameters({required int page, int size = 20}) => {
    'provinceCode': provinceCode,
    if (query.trim().isNotEmpty) 'q': query.trim(),
    if (brands.isNotEmpty) 'brand': brands.toList(),
    if (crusts.isNotEmpty) 'crust': crusts.toList(),
    if (fillings.isNotEmpty) 'filling': fillings.toList(),
    if (priceMin != null) 'priceMin': priceMin,
    if (priceMax != null) 'priceMax': priceMax,
    'sort': sort,
    'page': page,
    'size': size,
  };
}

final class FacetValue {
  const FacetValue({required this.value, required this.count, this.label = ''});

  final String value;
  final int count;
  final String label;
}

final class ProductFacets {
  const ProductFacets({
    required this.crusts,
    required this.fillings,
    required this.brands,
    required this.vendors,
    this.priceMin,
    this.priceMax,
  });

  final List<FacetValue> crusts;
  final List<FacetValue> fillings;
  final List<FacetValue> brands;
  final List<FacetValue> vendors;
  final int? priceMin;
  final int? priceMax;
}

final class CakeAttribute {
  const CakeAttribute({
    required this.code,
    required this.label,
    required this.group,
    required this.active,
  });

  final String code;
  final String label;
  final String group;
  final bool active;
}
