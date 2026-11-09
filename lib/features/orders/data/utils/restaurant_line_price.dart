/// Restaurant share of an items voucher. Delivery vouchers return 0.
double restaurantVoucherShare({
  required double restaurantGross,
  required double voucherDiscount,
  required String? voucherType,
  required double customerItemsPrice,
}) {
  const itemVouchers = {'order', 'pickup', 'restaurant'};
  if (voucherDiscount <= 0 || restaurantGross <= 0) return 0;
  if (!itemVouchers.contains(voucherType)) return 0;
  if (customerItemsPrice <= 0) return 0;
  final share = voucherDiscount * (restaurantGross / customerItemsPrice);
  if (share < 0) return 0;
  if (share > restaurantGross) return restaurantGross;
  return share;
}

/// Restaurant-facing line total.
///
/// New orders store [restaurantTotal] / [restaurantUnitPrice] without the
/// platform margin. Older orders only have the customer [totalPrice].
abstract final class RestaurantLinePrice {
  static double totalOf(Map<String, dynamic> line) {
    final restaurantTotal = line['restaurantTotal'];
    if (restaurantTotal is num) return restaurantTotal.toDouble();

    final quantity = (line['quantity'] as num?)?.toInt() ?? 1;
    final restaurantUnit = line['restaurantUnitPrice'];
    if (restaurantUnit is num) return restaurantUnit.toDouble() * quantity;

    final lineType = line['lineType']?.toString() ?? 'dish';
    if (lineType == 'restaurant_extra') {
      final totalPrice = line['totalPrice'];
      if (totalPrice is num && totalPrice.toDouble() > 0) {
        return totalPrice.toDouble();
      }
      final unit = line['unitPrice'];
      if (unit is num) return unit.toDouble() * quantity;
      return 0;
    }

    var price = 0.0;
    if (line['unitPrice'] is num) {
      price = (line['unitPrice'] as num).toDouble();
    } else if (line['selectedSize'] is Map) {
      final selectedSize = line['selectedSize'] as Map;
      if (selectedSize['price'] is num) {
        price = (selectedSize['price'] as num).toDouble();
      }
    } else if (line['item'] is Map) {
      final itemData = line['item'] as Map;
      if (itemData['price'] is num) {
        price = (itemData['price'] as num).toDouble();
      }
    }

    if (line['totalPrice'] is num) {
      return (line['totalPrice'] as num).toDouble();
    }
    return price * quantity;
  }
}
