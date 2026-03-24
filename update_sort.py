import sys

# 1. properties_feed_screen.dart
feed_path = r'C:\Users\niwan\Desktop\One More Deal\lib\screens\properties\properties_feed_screen.dart'
with open(feed_path, 'r', encoding='utf-8') as f:
    feed = f.read()

feed = feed.replace(
    """  final int? initialPropertyId;
  final PropertyFilter? initialFilter;

  const PropertiesFeedScreen({
    super.key,
    this.initialPropertyId,
    this.initialFilter,
  });""",
    """  final int? initialPropertyId;
  final PropertyFilter? initialFilter;
  final int? initialSortIndex;

  const PropertiesFeedScreen({
    super.key,
    this.initialPropertyId,
    this.initialFilter,
    this.initialSortIndex,
  });"""
)

feed = feed.replace(
    """  void initState() {
    super.initState();
    _highlightedPropertyId = widget.initialPropertyId;
    if (widget.initialFilter != null) {
      _currentFilter = PropertyFilter.from(widget.initialFilter!);
    }
    _loadProperties();
  }""",
    """  void initState() {
    super.initState();
    _highlightedPropertyId = widget.initialPropertyId;
    if (widget.initialFilter != null) {
      _currentFilter = PropertyFilter.from(widget.initialFilter!);
    }
    if (widget.initialSortIndex != null && widget.initialSortIndex! >= 0 && widget.initialSortIndex! < _SortOption.values.length) {
      _sortOption = _SortOption.values[widget.initialSortIndex!];
    }
    _loadProperties();
  }"""
)

with open(feed_path, 'w', encoding='utf-8') as f:
    f.write(feed)

# 2. home_screen.dart
home_path = r'C:\Users\niwan\Desktop\One More Deal\lib\screens\home_screen.dart'
with open(home_path, 'r', encoding='utf-8') as f:
    home = f.read()

home = home.replace(
    "PropertyFilter? _discoverFocusFilter;",
    "PropertyFilter? _discoverFocusFilter;\n  int? _discoverFocusSortIndex;"
)

home = home.replace(
    """  void _openPropertyInDiscover(int propertyId, UserTypeFilter? userTypeHint) {
    setState(() {
      _discoverFocusPropertyId = propertyId;
      _discoverFocusFilter = userTypeHint != null 
          ? (PropertyFilter(city: 'Pune')..userTypeFilter = userTypeHint)
          : null;
      _discoverFocusToken++;
      _currentIndex = 1;
    });
  }

  void _openDiscoverWithFilter(PropertyFilter filter) {
    setState(() {
      _discoverFocusPropertyId = null;
      _discoverFocusFilter = filter;
      _discoverFocusToken++;
      _currentIndex = 1;
    });
  }""",
    """  void _openPropertyInDiscover(int propertyId, UserTypeFilter? userTypeHint) {
    setState(() {
      _discoverFocusPropertyId = propertyId;
      _discoverFocusFilter = userTypeHint != null 
          ? (PropertyFilter(city: 'Pune')..userTypeFilter = userTypeHint)
          : null;
      _discoverFocusSortIndex = null;
      _discoverFocusToken++;
      _currentIndex = 1;
    });
  }

  void _openDiscoverWithFilter(PropertyFilter filter) {
    setState(() {
      _discoverFocusPropertyId = null;
      _discoverFocusFilter = filter;
      _discoverFocusSortIndex = null;
      _discoverFocusToken++;
      _currentIndex = 1;
    });
  }

  void _openDiscoverWithSort(int sortIndex) {
    setState(() {
      _discoverFocusPropertyId = null;
      _discoverFocusFilter = null;
      _discoverFocusSortIndex = sortIndex;
      _discoverFocusToken++;
      _currentIndex = 1; // Discover tab
    });
  }"""
)

home = home.replace(
    """      HomePageScreen(
        onOpenDiscoverProperty: _openPropertyInDiscover,
        onOpenDiscoverWithFilter: _openDiscoverWithFilter,
      ),
      PropertiesFeedScreen(
        key: ValueKey('discover_focus_$_discoverFocusToken'),
        initialPropertyId: _discoverFocusPropertyId,
        initialFilter: _discoverFocusFilter,
      ),""",
    """      HomePageScreen(
        onOpenDiscoverProperty: _openPropertyInDiscover,
        onOpenDiscoverWithFilter: _openDiscoverWithFilter,
        onOpenDiscoverWithSort: _openDiscoverWithSort,
      ),
      PropertiesFeedScreen(
        key: ValueKey('discover_focus_$_discoverFocusToken'),
        initialPropertyId: _discoverFocusPropertyId,
        initialFilter: _discoverFocusFilter,
        initialSortIndex: _discoverFocusSortIndex,
      ),"""
)

with open(home_path, 'w', encoding='utf-8') as f:
    f.write(home)

# 3. home_page_screen.dart
home_page_path = r'C:\Users\niwan\Desktop\One More Deal\lib\screens\home_page_screen.dart'
with open(home_page_path, 'r', encoding='utf-8') as f:
    home_page = f.read()

home_page = home_page.replace(
    """class HomePageScreen extends StatefulWidget {
  final void Function(int propertyId, UserTypeFilter? userTypeHint)? onOpenDiscoverProperty;
  final void Function(PropertyFilter filter)? onOpenDiscoverWithFilter;

  const HomePageScreen({
    super.key, 
    this.onOpenDiscoverProperty,
    this.onOpenDiscoverWithFilter,
  });""",
    """class HomePageScreen extends StatefulWidget {
  final void Function(int propertyId, UserTypeFilter? userTypeHint)? onOpenDiscoverProperty;
  final void Function(PropertyFilter filter)? onOpenDiscoverWithFilter;
  final void Function(int sortIndex)? onOpenDiscoverWithSort;

  const HomePageScreen({
    super.key, 
    this.onOpenDiscoverProperty,
    this.onOpenDiscoverWithFilter,
    this.onOpenDiscoverWithSort,
  });"""
)

home_page = home_page.replace(
    """enum _HomeSortOption {
  newest('Newest'),
  priceLow('Price Low-High'),
  priceHigh('Price High-Low'),
  area('Largest Area');

  const _HomeSortOption(this.label);
  final String label;
}""",
    """enum _HomeSortOption {
  newest('Newest First', 0),
  priceLow('Price Low-High', 2),
  priceHigh('Price High-Low', 3),
  area('Largest Area', 4);

  const _HomeSortOption(this.label, this.feedIndex);
  final String label;
  final int feedIndex;
}"""
)

home_page = home_page.replace(
    """    ).then((selected) {
      if (selected != null) {
        setState(() => _sortOption = selected);
      }
    });""",
    """    ).then((selected) {
      if (selected != null) {
        widget.onOpenDiscoverWithSort?.call(selected.feedIndex);
        setState(() => _sortOption = selected);
      }
    });"""
)

with open(home_page_path, 'w', encoding='utf-8') as f:
    f.write(home_page)

print("Update completed for passing sort index to discover")
