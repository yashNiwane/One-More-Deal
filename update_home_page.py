import sys

home_page_path = r'C:\Users\niwan\Desktop\One More Deal\lib\screens\home_page_screen.dart'
with open(home_page_path, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Update constructor
code = code.replace(
    """class HomePageScreen extends StatefulWidget {
  final void Function(int propertyId, UserTypeFilter? userTypeHint)?
  onOpenDiscoverProperty;

  const HomePageScreen({super.key, this.onOpenDiscoverProperty});""",
    """class HomePageScreen extends StatefulWidget {
  final void Function(int propertyId, UserTypeFilter? userTypeHint)? onOpenDiscoverProperty;
  final void Function(PropertyFilter filter)? onOpenDiscoverWithFilter;

  const HomePageScreen({
    super.key, 
    this.onOpenDiscoverProperty,
    this.onOpenDiscoverWithFilter,
  });"""
)

# 2. Update _openFilterBottomSheet
code = code.replace(
    """  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilter: _currentFilter,
        onApply: (newFilter) {
          setState(() => _currentFilter = newFilter);
          _loadProperties();
        },
      ),
    );
  }""",
    """  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilter: PropertyFilter(city: 'Pune'),
        onApply: (newFilter) {
          widget.onOpenDiscoverWithFilter?.call(newFilter);
        },
      ),
    );
  }"""
)

# 3. Update _updateQuickFilter
code = code.replace(
    """  void _updateQuickFilter({
    UserTypeFilter? userTypeFilter,
    PropertyCategory? category,
    ListingType? listingType,
  }) {
    final next = PropertyFilter.from(_currentFilter);
    if (userTypeFilter != null) {
      next.userTypeFilter = next.userTypeFilter == userTypeFilter
          ? null
          : userTypeFilter;
    }
    if (category != null) {
      next.category = next.category == category ? null : category;
    }
    if (listingType != null) {
      next.listingType = next.listingType == listingType ? null : listingType;
    }
    setState(() => _currentFilter = next);
    _loadProperties();
  }""",
    """  void _updateQuickFilter({
    UserTypeFilter? userTypeFilter,
    PropertyCategory? category,
    ListingType? listingType,
  }) {
    final next = PropertyFilter(city: 'Pune');
    if (userTypeFilter != null) next.userTypeFilter = userTypeFilter;
    if (category != null) next.category = category;
    if (listingType != null) next.listingType = listingType;
    widget.onOpenDiscoverWithFilter?.call(next);
  }"""
)

# 4. Remove activeFilter usage
code = code.replace(
    """                                value: _activeFilterCount == 0
                                    ? 'Open'
                                    : '$_activeFilterCount Active',""",
    """                                value: 'Any',"""
)

code = code.replace(
    """                  subtitle: _activeFilterCount == 0
                      ? 'Refine listings'
                      : '$_activeFilterCount applied',""",
    """                  subtitle: 'Refine listings',"""
)

# 5. Make Chips Stateless in appearance (no _currentFilter checks)
code = code.replace(
    """                _buildQuickFilterChip(
                  label: 'Builder',
                  selected:
                      _currentFilter.userTypeFilter == UserTypeFilter.builder,
                  onTap: () => _updateQuickFilter(
                    userTypeFilter: UserTypeFilter.builder,
                  ),
                ),""",
    """                _buildQuickFilterChip(
                  label: 'Builder',
                  selected: false,
                  onTap: () => _updateQuickFilter(
                    userTypeFilter: UserTypeFilter.builder,
                  ),
                ),"""
)

code = code.replace(
    """                _buildQuickFilterChip(
                  label: 'Broker',
                  selected:
                      _currentFilter.userTypeFilter == UserTypeFilter.broker,
                  onTap: () =>
                      _updateQuickFilter(userTypeFilter: UserTypeFilter.broker),
                ),""",
    """                _buildQuickFilterChip(
                  label: 'Broker',
                  selected: false,
                  onTap: () =>
                      _updateQuickFilter(userTypeFilter: UserTypeFilter.broker),
                ),"""
)

code = code.replace(
    """                _buildQuickFilterChip(
                  label: 'Residential',
                  selected:
                      _currentFilter.category == PropertyCategory.residential,
                  onTap: () => _updateQuickFilter(
                    category: PropertyCategory.residential,
                  ),
                ),""",
    """                _buildQuickFilterChip(
                  label: 'Residential',
                  selected: false,
                  onTap: () => _updateQuickFilter(
                    category: PropertyCategory.residential,
                  ),
                ),"""
)

code = code.replace(
    """                _buildQuickFilterChip(
                  label: 'Commercial',
                  selected:
                      _currentFilter.category == PropertyCategory.commercial,
                  onTap: () =>
                      _updateQuickFilter(category: PropertyCategory.commercial),
                ),""",
    """                _buildQuickFilterChip(
                  label: 'Commercial',
                  selected: false,
                  onTap: () =>
                      _updateQuickFilter(category: PropertyCategory.commercial),
                ),"""
)

code = code.replace(
    """                _buildQuickFilterChip(
                  label: 'Rent',
                  selected: _currentFilter.listingType == ListingType.rent,
                  onTap: () =>
                      _updateQuickFilter(listingType: ListingType.rent),
                ),""",
    """                _buildQuickFilterChip(
                  label: 'Rent',
                  selected: false,
                  onTap: () =>
                      _updateQuickFilter(listingType: ListingType.rent),
                ),"""
)

code = code.replace(
    """                _buildQuickFilterChip(
                  label: 'Resale',
                  selected: _currentFilter.listingType == ListingType.resale,
                  onTap: () =>
                      _updateQuickFilter(listingType: ListingType.resale),
                ),""",
    """                _buildQuickFilterChip(
                  label: 'Resale',
                  selected: false,
                  onTap: () =>
                      _updateQuickFilter(listingType: ListingType.resale),
                ),"""
)

with open(home_page_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("home_page_screen.dart refactor complete")
