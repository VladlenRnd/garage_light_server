import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

import 'user_model.dart';

const String _pathToFileUsers = "users.json";
const String _pathToFileLog = "logs.json";

Future<List<GarageUser>> readUsersFromFile() async {
  final file = File(_pathToFileUsers);

  if (!await file.exists()) {
    throw Exception('File not found: $_pathToFileUsers');
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

//******************LOGER*********************** */

Future<String> getLogActionJson() async {
  final File logFile = File(_pathToFileLog);

  // Читаем существующие логи
  //String logs = "Log file is Empty";
  if (await logFile.exists()) {
    final content = await logFile.readAsString();
    if (content.isNotEmpty) {
      return content;
    }
  }

  //Возвращаем Логи
  return "";
}

Future<List<dynamic>> getLogAction() async {
  final File logFile = File(_pathToFileLog);

  // Читаем существующие логи
  //String logs = "Log file is Empty";
  if (await logFile.exists()) {
    final content = await logFile.readAsString();
    if (content.isNotEmpty) {
      return jsonDecode(content);
    }
  }

  //Возвращаем Логи
  return [];
}

Future<void> setLogAction({required String garageNumber, required String userKey, required String action}) async {
  final File logFile = File('logs.json');

  // Читаем существующие логи
  List<dynamic> logs = [];
  if (await logFile.exists()) {
    final content = await logFile.readAsString();
    if (content.isNotEmpty) {
      logs = jsonDecode(content);
    }
  }

  // Добавляем новый лог
  logs.add({
    'time': DateFormat("dd/MM/yyyy  HH:mm:ss").format(DateTime.now()),
    'key': userKey,
    'garage_number': garageNumber,
    'action': action,
  });

  // Сохраняем обновлённые логи
  await logFile.writeAsString(jsonEncode(logs), mode: FileMode.write, flush: true);
}
