import sys
import re

# 1. properties_feed_screen.dart
feed_path = r'C:\Users\niwan\Desktop\One More Deal\lib\screens\properties\properties_feed_screen.dart'
with open(feed_path, 'r', encoding='utf-8') as f:
    feed_code = f.read()

feed_code = feed_code.replace(
    """  final int? initialPropertyId;
  final UserTypeFilter? initialUserTypeFilter;

  const PropertiesFeedScreen({
    super.key,
    this.initialPropertyId,
    this.initialUserTypeFilter,
  });""",
    """  final int? initialPropertyId;
  final PropertyFilter? initialFilter;

  const PropertiesFeedScreen({
    super.key,
    this.initialPropertyId,
    this.initialFilter,
  });"""
)

feed_code = feed_code.replace(
    """    if (widget.initialUserTypeFilter != null) {
      _currentFilter.userTypeFilter = widget.initialUserTypeFilter;
    }""",
    """    if (widget.initialFilter != null) {
      _currentFilter = PropertyFilter.from(widget.initialFilter!);
    }"""
)

feed_code = feed_code.replace(
    """    if (!targetExists &&
        !_didRelaxInitialUserTypeFilter &&
        widget.initialUserTypeFilter != null &&
        _currentFilter.userTypeFilter != null) {""",
    """    if (!targetExists &&
        !_didRelaxInitialUserTypeFilter &&
        widget.initialFilter?.userTypeFilter != null &&
        _currentFilter.userTypeFilter != null) {"""
)

with open(feed_path, 'w', encoding='utf-8') as f:
    f.write(feed_code)

# 2. home_screen.dart
home_path = r'C:\Users\niwan\Desktop\One More Deal\lib\screens\home_screen.dart'
with open(home_path, 'r', encoding='utf-8') as f:
    home_code = f.read()

home_code = home_code.replace(
    "UserTypeFilter? _discoverFocusUserType;",
    "PropertyFilter? _discoverFocusFilter;"
)

home_code = home_code.replace(
    """  void _openPropertyInDiscover(int propertyId, UserTypeFilter? userTypeHint) {
    setState(() {
      _discoverFocusPropertyId = propertyId;
      _discoverFocusUserType = userTypeHint;
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
  }"""
)

home_code = home_code.replace(
    """    final List<Widget> pages = [
      HomePageScreen(onOpenDiscoverProperty: _openPropertyInDiscover),
      PropertiesFeedScreen(
        key: ValueKey('discover_focus_$_discoverFocusToken'),
        initialPropertyId: _discoverFocusPropertyId,
        initialUserTypeFilter: _discoverFocusUserType,
      ),""",
    """    final List<Widget> pages = [
      HomePageScreen(
        onOpenDiscoverProperty: _openPropertyInDiscover,
        onOpenDiscoverWithFilter: _openDiscoverWithFilter,
      ),
      PropertiesFeedScreen(
        key: ValueKey('discover_focus_$_discoverFocusToken'),
        initialPropertyId: _discoverFocusPropertyId,
        initialFilter: _discoverFocusFilter,
      ),"""
)

with open(home_path, 'w', encoding='utf-8') as f:
    f.write(home_code)

print("Update completed for feed and home screen")
