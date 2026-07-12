/// A delivery neighbourhood / area a customer can be located in when they
/// call the restaurant for a delivery order. Managed from Settings → Locations.
class Location {
  final String id;
  final String name;

  const Location({required this.id, required this.name});

  Location copyWith({String? id, String? name}) =>
      Location(id: id ?? this.id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
