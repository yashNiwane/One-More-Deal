import '../models/property_model.dart';
import '../models/enquiry_model.dart';
import 'database_service.dart';
import 'auth_service.dart';

/// Business-logic layer for property CRUD and discovery.
/// All methods delegate to [DatabaseService.instance] for DB I/O.
class PropertyService {
  PropertyService._();

  // ── Add ────────────────────────────────────────────────────────────────

  /// Posts a new property listing.
  /// Automatically sets auto_delete_at (Rent=30d, Resale/New=60d).
  /// [userId] should come from the logged-in user (AuthService.currentUserId).
  static Future<PropertyModel?> addProperty(PropertyModel property) async {
    return DatabaseService.instance.addProperty(property);
  }

  // ── Edit ───────────────────────────────────────────────────────────────

  /// Updates editable fields; non-editable fields (city, type) stay fixed.
  static Future<void> updateProperty(PropertyModel property) async {
    return DatabaseService.instance.updateProperty(property);
  }

  // ── Delete ─────────────────────────────────────────────────────────────

  /// Soft-deletes: sets is_visible = false (keeps DB row for audit).
  static Future<void> deleteProperty(int propertyId, int userId) async {
    return DatabaseService.instance.deleteProperty(propertyId, userId);
  }

  // ── Refresh ────────────────────────────────────────────────────────────

  /// Resets posted_date and auto_delete timer so the listing stays visible.
  /// Rent → 30 days, Resale/New/Plot → 60 days.
  static Future<void> refreshProperty(int propertyId, int userId, ListingType listingType) async {
    return DatabaseService.instance.refreshProperty(propertyId, userId, listingType);
  }

  // ── My Properties ──────────────────────────────────────────────────────

  /// Returns all properties posted by the logged-in user (including hidden/expired).
  static Future<List<PropertyModel>> getMyProperties(int userId) async {
    // Run auto-expire first so status is current
    await DatabaseService.instance.expireOldProperties();
    return DatabaseService.instance.getMyProperties(userId);
  }

  // ── Discovery ─────────────────────────────────────────────────────────

  /// Returns all visible, non-expired properties with optional filters.
  /// Builder listings are grouped by society and appear first.
  static Future<List<PropertyModel>> getProperties({PropertyFilter? filter}) async {
    await DatabaseService.instance.expireOldProperties();
    return DatabaseService.instance.getProperties(filter: filter);
  }

  // ── Enquiry (Call / WhatsApp) ─────────────────────────────────────────

  /// Log an enquiry when a user taps Call or WhatsApp.
  static Future<void> logEnquiry({
    required int propertyId,
    required EnquiryType type,
  }) async {
    // Get enquirer's DB id (may be null if not fetched yet)
    final enquirerId = AuthService.currentUserId;
    await DatabaseService.instance.logEnquiry(
      propertyId: propertyId,
      enquirerId: enquirerId,
      type: type,
    );
  }

  // ── Helper: derive floor category from number ──────────────────────────

  /// Low = 1–2, Mid = 3–5, High = 6+
  static FloorCategory? deriveFloorCategory(int? floorNumber) =>
      PropertyModel.floorCategoryFromNumber(floorNumber);

  // ── Helper: get poster phone number ────────────────────────────────────

  /// Fetches the phone number of the user who posted the property.
  static Future<String?> getPosterPhone(int userId) async {
    return DatabaseService.instance.getUserPhoneById(userId);
  }

  // ── Area Autocomplete ──────────────────────────────────────────────────

  /// Searches for city areas matching the query string.
  static Future<List<String>> searchCityAreas(String query) async {
    return DatabaseService.instance.searchCityAreas(query);
  }

  // ── Brokers List ───────────────────────────────────────────────────────
  
  static Future<List<Map<String, dynamic>>> getAllBrokers() async {
    return DatabaseService.instance.getAllBrokers();
  }
}
