import 'dart:io';

import 'package:intl/intl.dart';
import 'package:shelf/shelf.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:logging/logging.dart';
import 'package:shelf_router/shelf_router.dart';
import 'tools.dart';
import 'user_model.dart';
import 'package:rxdart/rxdart.dart';
import 'ui_logs.dart';

final Logger _log = Logger('GarageServer');

final PublishSubject<bool> eventLongPollStreamController = PublishSubject<bool>();
final PublishSubject<bool> eventStreamController = PublishSubject<bool>();
bool _lightStatus = false;
bool _neadInitFromRelay = true;

String arduinoFirmwareVersion = "-";

const int _waitMillisecondsRelay = 15000;

const int _waitMillisecondsLongPool = 58000; // 58 sec

Future<Response> getStatusRequest(Request request) async => Response.ok(jsonEncode({'status': 'success', "LightIs": _lightStatus}));

Future<Response> getLogsJsonRequest(Request request) async {
  String logs = await getLogActionJson();

  return Response.ok(logs.isEmpty ? "Logs Is Empty" : logs, headers: {'Content-Type': 'application/json'});
}

Future<Response> getLogsRequest(Request request) async {
  List<dynamic> logs = await getLogAction();

  return Response.ok(logs.isEmpty ? "Logs Is Empty" : getHtmlLogs(logs), headers: {'Content-Type': 'text/html'});
}

Future<Response> handleRequest(Request request) async {
  if (request.method == 'POST') {
    switch (request.url.path) {
      case "turnLightOff":
        {
          GarageUser user = GarageUser.fromJson(jsonDecode(await request.readAsString()));

          if (!await getIsUserValid(user)) {
            await setLogAction(
                action: "Trying to OFF - Incorrect User Error", garageNumber: user.garageNumber ?? "NULL", userKey: user.key ?? "NULL");
            return Response.forbidden(jsonEncode({'status': 'error', 'message': 'Access denied'}));
          }

          eventLongPollStreamController.add(false);

          try {
            final bool state = await eventStreamController.stream.timeout(const Duration(milliseconds: _waitMillisecondsRelay)).first;
            await setLogAction(action: "OFF", garageNumber: user.garageNumber ?? "NULL", userKey: user.key ?? "NULL");
            return Response.ok(jsonEncode({'status': 'success', 'LightIs': state}));
          } catch (e) {
            await setLogAction(action: "Trying to OFF - Timeout error", garageNumber: user.garageNumber ?? "NULL", userKey: user.key ?? "NULL");
            return Response.ok(jsonEncode({'status': 'error', 'message': 'timeout'}));
          }
        }
      case "turnLightOn":
        {
          GarageUser user = GarageUser.fromJson(jsonDecode(await request.readAsString()));

          if (!await getIsUserValid(user)) {
            await setLogAction(action: "Trying to ON - Incorrect User Error", garageNumber: user.garageNumber ?? "NULL", userKey: user.key ?? "NULL");
            return Response.forbidden(jsonEncode({'status': 'error', 'message': 'Access denied'}));
          }

          eventLongPollStreamController.add(true);

          try {
            final bool state = await eventStreamController.stream.timeout(const Duration(milliseconds: _waitMillisecondsRelay)).first;
            await setLogAction(action: "ON", garageNumber: user.garageNumber ?? "NULL", userKey: user.key ?? "NULL");
            return Response.ok(jsonEncode({'status': 'success', 'LightIs': state}));
          } catch (e) {
            await setLogAction(action: "Trying to ON - Timeout error", garageNumber: user.garageNumber ?? "NULL", userKey: user.key ?? "NULL");
            return Response.ok(jsonEncode({'status': 'error', 'message': 'timeout'}));
          }
        }
      case "setCurrentStatusRelay":
        {
          var data = jsonDecode(await request.readAsString());
          GarageUser user = GarageUser.fromJson(data);
          String? message;
          if (await getIsUserValid(user)) {
            _neadInitFromRelay = false;
            _lightStatus = data["LightIs"];
            message = data["message"];
            arduinoFirmwareVersion = data["version"] ?? "Arduino send NULL";
            await setLogAction(
              action: "Relay status is: $_lightStatus",
              garageNumber: user.garageNumber ?? "NULL",
              userKey: "$message",
            );
            eventLongPollStreamController.add(_lightStatus);
            eventStreamController.add(_lightStatus);
            return Response.ok(jsonEncode({'status': 'success'}));
          } else {
            await setLogAction(action: "setCurrentStatusRealy Access denied", garageNumber: user.garageNumber ?? "NULL", userKey: user.key ?? "NULL");
            return Response.forbidden(jsonEncode({'status': 'error', 'message': 'Access denied'}));
          }
        }
    }
  }

  return Response.notFound('Route not found');
}

Future<Response> longPollingHandler(Request request) async {
  if (_neadInitFromRelay) {
    return Response.ok(jsonEncode({'status': 'success', 'message': "neadGetStatus"}));
  }

  try {
    final bool state = await eventLongPollStreamController.stream.timeout(const Duration(milliseconds: _waitMillisecondsLongPool)).first;
    return Response.ok(jsonEncode({'status': 'success', 'LightIs': state}));
  } catch (e) {
    return Response.internalServerError(body: 'long pool timeout');
  }
}

//***************update******************** */
Future<Response> getCurrentVersionFirmware(Request request) async {
  String version = await getVersionFirmware();
  return Response.ok(version, headers: {'Content-Type': 'application/json'});
}

Future<Response> getCurrentFirmware(Request request) async {
  File file = getFirmware();
  if (file.existsSync()) {
    int length = file.lengthSync(); // Получаем размер файла
    return Response.ok(file.openRead(), headers: {
      HttpHeaders.contentTypeHeader: 'application/octet-stream',
      HttpHeaders.contentLengthHeader: length.toString(), // Указываем размер
    });
  } else {
    return Response.notFound('Файл прошивки не найден');
  }
}

//***************************************** */

void main(List<String> args) async {
  Logger.root.level = Level.ALL; // Вывод всех логов
  // Logger.root.level = Level.OFF;
  Logger.root.onRecord.listen((record) {
    print('(${record.level.name}- ${DateFormat("dd-MM-yyyy | HH:mm:ss").format(record.time)}) - ${record.message}');
  });

  final router = Router()
    ..get('/longpoll', longPollingHandler)
    ..get('/getStatus', getStatusRequest)
    ..get('/getLogs', getLogsRequest)
    ..get('/getLogsJson', getLogsJsonRequest)
    ..get('/getSoftware/version', getCurrentVersionFirmware)
    ..get('/getSoftware/firmware', getCurrentFirmware)
    ..post('/turnLightOff', handleRequest)
    ..post('/turnLightOn', handleRequest)
    ..post('/setCurrentStatusRelay', handleRequest);

  final handler = const Pipeline().addMiddleware(logRequests(
    logger: (message, isError) {
      if (isError) {
        Logger('ERROR').warning(message);
      } else {
        Logger('HTTP').info(message);
      }
    },
  )).addHandler(router.call);

  //final server = await shelf_io.serve(handler, '192.168.0.111', 8080);3000

  //real port 3000
  // test 223

  final server = await shelf_io.serve(handler, '0.0.0.0', 3000);
  _log.info('Сервер запущен на http://${server.address.host}:${server.port}');
}
