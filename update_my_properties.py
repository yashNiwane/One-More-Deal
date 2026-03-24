import sys

file_path = r'C:\Users\niwan\Desktop\One More Deal\lib\screens\properties\my_properties_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add state variables
state_vars_orig = """class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  bool _isLoading = true;
  List<PropertyModel> _properties = [];"""

state_vars_new = """class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  bool _isLoading = true;
  List<PropertyModel> _properties = [];
  PropertyCategory? _selectedCategory;
  ListingType? _selectedListingType;

  List<PropertyModel> get _filteredProperties {
    return _properties.where((p) {
      if (_selectedCategory != null && p.category != _selectedCategory) return false;
      if (_selectedListingType != null && p.listingType != _selectedListingType) return false;
      return true;
    }).toList();
  }"""

text = text.replace(state_vars_orig, state_vars_new)

# 2. Add `_buildFilterBar` and `_buildChip` 
# Find `Widget _buildMinimalStat(String text, {bool live = false}) {`
minimal_stat = """  Widget _buildMinimalStat(String text, {bool live = false}) {"""

filter_bar_methods = """  Widget _buildFilterBar() {
    return Container(
      height: 34,
      color: const Color(0xFFF3F5F9),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(
            'Residential',
            _selectedCategory == PropertyCategory.residential,
            () => setState(() => _selectedCategory = _selectedCategory == PropertyCategory.residential ? null : PropertyCategory.residential)
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Commercial',
            _selectedCategory == PropertyCategory.commercial,
            () => setState(() => _selectedCategory = _selectedCategory == PropertyCategory.commercial ? null : PropertyCategory.commercial)
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Rent',
            _selectedListingType == ListingType.rent,
            () => setState(() => _selectedListingType = _selectedListingType == ListingType.rent ? null : ListingType.rent)
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Resale',
            _selectedListingType == ListingType.resale,
            () => setState(() => _selectedListingType = _selectedListingType == ListingType.resale ? null : ListingType.resale)
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightGray,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.darkGray,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

"""

text = text.replace(minimal_stat, filter_bar_methods + minimal_stat)

# 3. Modify Slivers build
slivers_orig = """          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else if (_properties.isEmpty)
            SliverFillRemaining(child: Center(child: _buildEmptyState()))
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPropertyCard(_properties[index]),
                  childCount: _properties.length,
                ),
              ),
            ),"""

slivers_new = """          if (_properties.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildFilterBar(),
              ),
            ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else if (_properties.isEmpty)
            SliverFillRemaining(child: Center(child: _buildEmptyState()))
          else if (_filteredProperties.isEmpty)
             SliverFillRemaining(
               child: Center(
                 child: Text(
                   'No listings match the selected filters.',
                   style: GoogleFonts.inter(color: AppColors.darkGray),
                 ),
               ),
             )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPropertyCard(_filteredProperties[index]),
                  childCount: _filteredProperties.length,
                ),
              ),
            ),"""

text = text.replace(slivers_orig, slivers_new)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)

print("my_properties_screen.dart updated successfully.")
