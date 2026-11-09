class DeliveryModel {
  final String id;
  final String name;
  final String phone;
  final double rate;
  final String imageUrl;

  DeliveryModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.rate,
    required this.imageUrl,
  });

  factory DeliveryModel.fromMap(Map<String, dynamic> map) {
    return DeliveryModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      rate: (map['rate'] as num).toDouble(),
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'rate': rate,
      'imageUrl': imageUrl,
    };
  }
}
