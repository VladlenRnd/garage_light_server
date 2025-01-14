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

final PublishSubject<bool> eventStreamController = PublishSubject<bool>();
bool _lightStatus = false;

Future<Response> getStatusRequest(Request request) async => Response.ok(jsonEncode({'status': 'success', "LightIs": _lightStatus}));

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
          if (await getIsUserValid(user)) {
            _lightStatus = false;
            eventStreamController.add(_lightStatus);

            setLogAction(action: "OFF", garageNumber: user.garageNumber ?? "NULL", userKey: user.key ?? "NULL");
            return Response.ok(jsonEncode({'status': 'success', "LightIs": _lightStatus}));
          } else {
            return Response.forbidden(jsonEncode({'status': 'error', 'message': 'Access denied'}));
          }
        }
      case "turnLightOn":
        {
          GarageUser user = GarageUser.fromJson(jsonDecode(await request.readAsString()));
          if (await getIsUserValid(user)) {
            _lightStatus = true;
            eventStreamController.add(_lightStatus);

            setLogAction(action: "ON", garageNumber: user.garageNumber ?? "NULL", userKey: user.key ?? "NULL");
            return Response.ok(jsonEncode({'status': 'success', "LightIs": _lightStatus}));
          } else {
            return Response.forbidden(jsonEncode({'status': 'error', 'message': 'Access denied'}));
          }
        }
      case "setCurrentStatus":
        {
          var data = jsonDecode(await request.readAsString());
          GarageUser user = GarageUser.fromJson(data);
          if (await getIsUserValid(user)) {
            _lightStatus = data["LightIs"];
            eventStreamController.add(_lightStatus);
            return Response.ok(jsonEncode({'status': 'success'}));
          } else {
            return Response.forbidden(jsonEncode({'status': 'error', 'message': 'Access denied'}));
          }
        }
    }
  }

  return Response.notFound('Route not found');
}

Future<Response> longPollingHandler(Request request) async {
  // Ждем, пока не изменится состояние света

  await for (bool state in eventStreamController.stream) {
    // Когда состояние изменилось, отправляем ответ на запрос Arduino
    _lightStatus = state;
    return Response.ok(jsonEncode({'status': 'success', 'LightIs': state}));
  }
  return Response.notFound('Error');
}

void main(List<String> args) async {
  Logger.root.level = Level.ALL; // Вывод всех логов
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final router = Router()
    ..get('/longpoll', longPollingHandler)
    ..get('/getStatus', getStatusRequest)
    ..get('/getLogs', getLogsRequest)
    ..post('/turnLightOff', handleRequest)
    ..post('/setCurrentStatus', handleRequest)
    ..post('/turnLightOn', handleRequest);

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  //final server = await shelf_io.serve(handler, '192.168.0.111', 8080);
  final server = await shelf_io.serve(handler, '0.0.0.0', 3000);
  _log.info('Сервер запущен на http://${server.address.host}:${server.port}');
}
