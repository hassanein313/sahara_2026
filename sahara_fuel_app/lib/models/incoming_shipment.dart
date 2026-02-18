class IncomingShipment {
  final String supplier;
  final String company;
  final int quantity;
  final double density;
  final String color;
  final String voucher;
  final double price;
  final double cost;
  final String driver;
  final String vehicleNo;
  final String date;

  IncomingShipment({
    required this.supplier,
    required this.company,
    required this.quantity,
    this.density = 0.0,
    required this.color,
    required this.voucher,
    required this.price,
    required this.cost,
    required this.driver,
    required this.vehicleNo,
    required this.date,
  });

  factory IncomingShipment.fromMap(Map<String, dynamic> map) {
    return IncomingShipment(
      supplier: map['supplier'] ?? '',
      company: map['company'] ?? '',
      quantity: map['quantity'] is int ? map['quantity'] : int.tryParse(map['quantity'].toString()) ?? 0,
      density: map['density'] is num ? (map['density'] as num).toDouble() : double.tryParse(map['density'].toString()) ?? 0.0,
      color: map['color'] ?? '',
      voucher: map['voucher'] ?? '',
      price: map['price'] is num ? (map['price'] as num).toDouble() : double.tryParse(map['price'].toString()) ?? 0.0,
      cost: map['cost'] is num ? (map['cost'] as num).toDouble() : double.tryParse(map['cost'].toString()) ?? 0.0,
      driver: map['driver'] ?? '',
      vehicleNo: map['vehicleNo'] ?? '',
      date: map['date'] ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'supplier': supplier,
      'company': company,
      'quantity': quantity,
      'density': density,
      'color': color,
      'voucher': voucher,
      'price': price,
      'cost': cost,
      'driver': driver,
      'vehicleNo': vehicleNo,
      'date': date,
    };
  }
}

