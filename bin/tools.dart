import 'dart:convert';
import 'dart:io';

import 'user_model.dart';

const String _filePath = "users.json";

Future<List<GarageUser>> readUsersFromFile() async {
  final filePath = '${Directory.current.path}\\$_filePath';

  final file = File(filePath);

  if (!await file.exists()) {
    throw Exception('File not found: $filePath');
  }

  final content = await file.readAsString();

  // Преобразуем каждый элемент в объект GarageUser
  List<GarageUser> users = List<GarageUser>.from(jsonDecode(content).map((userJson) => GarageUser.fromJson(userJson)));

  return users;
}

Future<bool> getIsUserValid(GarageUser user) async {
  for (GarageUser savedUser in await readUsersFromFile()) {
    if (user.isSameUser(savedUser)) {
      return true;
    }
  }
  return false;
}
