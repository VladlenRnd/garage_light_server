String getHtmlLogs(List<dynamic> logs) {
  // Группируем логи по номеру гаража
  Map<String, List<dynamic>> groupedLogs = {};

  for (var log in logs) {
    final garageNumber = log['garage_number'];
    if (!groupedLogs.containsKey(garageNumber)) {
      groupedLogs[garageNumber] = [];
    }
    groupedLogs[garageNumber]?.add(log);
  }

  // Генерируем HTML для каждой группы гаражей
  String groupedLogsHtml = groupedLogs.entries.map((entry) {
    final garageNumber = entry.key;
    final logsForGarage = entry.value;

    // Группируем логи по датам
    Map<String, Map<String, List<dynamic>>> groupedByDateAndMonth = {};

    for (var log in logsForGarage) {
      final date = log['time'].split(' ')[0]; // Извлекаем только дату
      final month = log['time'].split(' ')[0].split('/')[1]; // Извлекаем месяц

      if (!groupedByDateAndMonth.containsKey(month)) {
        groupedByDateAndMonth[month] = {};
      }

      if (!groupedByDateAndMonth[month]!.containsKey(date)) {
        groupedByDateAndMonth[month]![date] = [];
      }

      groupedByDateAndMonth[month]![date]?.add(log);
    }

    // Генерируем HTML для раскрывающихся списков по месяцам и дням
    String monthAndDateCollapsibleHtml = groupedByDateAndMonth.entries.map((monthEntry) {
      final month = monthEntry.key;
      final groupedByDate = monthEntry.value;

      String dateCollapsibleHtml = groupedByDate.entries.map((dateEntry) {
        final date = dateEntry.key;
        final logsForDate = dateEntry.value;

        String logsHtml = logsForDate.map((log) {
          return '''
            <p class="log-time">
              <span class="log-date">${log['time']}</span>
              <span class="log-action">${log['action']}</span>
              <br>
              <span class="log-action">${log['key']}</span>
            </p>
            <hr class="log-divider">
          ''';
        }).join();

        return '''
          <button class="collapsible">$date</button>
          <div class="content">
            $logsHtml
          </div>
        ''';
      }).join();

      return '''
        <button class="collapsible">Месяц $month</button>
        <div class="content">
          $dateCollapsibleHtml
        </div>
      ''';
    }).join();

    // Подсчитываем количество записей, включений и выключений
    final totalRecords = logsForGarage.length;
    final lightOns = logsForGarage.where((log) => log['action'] == 'ON').length;
    final lightOffs = logsForGarage.where((log) => log['action'] == 'OFF').length;

    return '''
      <h2>Garage $garageNumber</h2>
      <p>Total records: $totalRecords</p>
      <p>Lights turned ON: $lightOns</p>
      <p>Lights turned OFF: $lightOffs</p>
      <div>
        $monthAndDateCollapsibleHtml
      </div>
      <br>
    ''';
  }).join();

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Logs</title>
  <style>
    table {
      width: 100%;
      border-collapse: collapse;
    }
    th, td {
      padding: 8px;
      text-align: left;
      border: 1px solid #ddd;
    }
    th {
      background-color: #f2f2f2;
    }
    .log-time {
      margin-bottom: 15px;
      padding-left: 10px;
    }
    .log-date {
      font-weight: bold;
      color: #333;
      margin-right: 10px;
    }
    .log-divider {
  border: none;
  border-top: 1px solid #ddd;
  margin: 10px 0;
}
    .collapsible {
      background-color: #777;
      color: white;
      cursor: pointer;
      padding: 10px;
      width: 100%;
      border: none;
      text-align: left;
      outline: none;
      font-size: 15px;
    }
    .active, .collapsible:hover {
      background-color: #555;
    }
    .content {
      padding: 0 18px;
      display: none;
      overflow: hidden;
      background-color: #f1f1f1;
    }
    .log-entry {
      margin-bottom: 15px;
      padding-left: 10px;
    }
    .log-time {
      font-weight: bold;
      color: #333;
      margin-bottom: 5px;
    }
    .log-action {
      color: #666;
    }
  </style>
</head>
<body>
  <h1>Logs</h1>
  $groupedLogsHtml
  <script>
    var coll = document.getElementsByClassName("collapsible");
    for (var i = 0; i < coll.length; i++) {
      coll[i].addEventListener("click", function() {
        this.classList.toggle("active");
        var content = this.nextElementSibling;
        if (content.style.display === "block") {
          content.style.display = "none";
        } else {
          content.style.display = "block";
        }
      });
    }
  </script>
</body>
</html>
''';
}
