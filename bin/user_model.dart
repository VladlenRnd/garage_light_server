import 'package:equatable/equatable.dart';

class GarageUser extends Equatable {
  final String? garageNumber;
  final String? key;

  GarageUser({required this.key, required this.garageNumber});

  factory GarageUser.fromJson(Map<String, dynamic> json) {
    return GarageUser(
      key: json["key"],
      garageNumber: json["garageNumber"],
    );
  }

  bool isSameUser(GarageUser other) => other.key == key && other.garageNumber == garageNumber;

  @override
  List<Object?> get props => [garageNumber, key];
}
