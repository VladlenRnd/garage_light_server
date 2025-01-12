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

    return '''
      <h2>Garage $garageNumber</h2>
      <table id="logTable_$garageNumber">
        <thead>
          <tr>
            <th class="sortable" onclick="sortTable(0, '$garageNumber')">Time</th>
            <th class="sortable" onclick="sortTable(1, '$garageNumber')">Key</th>
            <th class="sortable" onclick="sortTable(2, '$garageNumber')">Action</th>
          </tr>
        </thead>
        <tbody>
          ${logsForGarage.map((log) {
      return '''
              <tr>
                <td>${log['time']}</td>
                <td>${log['key']}</td>
                <td>${log['action']}</td>
              </tr>
            ''';
    }).join()}
        </tbody>
      </table>
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
    .sortable:hover {
      cursor: pointer;
    }
  </style>
</head>
<body>
  <h1>Logs</h1>
  $groupedLogsHtml
  <script>
    function sortTable(n, garageNumber) {
      var table = document.getElementById("logTable_" + garageNumber);
      var rows = table.rows;
      var switching = true;
      var dir = "asc"; 
      while (switching) {
        switching = false;
        var shouldSwitch = false;
        for (var i = 1; i < (rows.length - 1); i++) {
          var x = rows[i].getElementsByTagName("TD")[n];
          var y = rows[i + 1].getElementsByTagName("TD")[n];
          if (dir == "asc" && x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase() || 
              dir == "desc" && x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
            shouldSwitch = true;
            break;
          }
        }
        if (shouldSwitch) {
          rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
          switching = true;
        } else {
          if (dir == "asc") {
            dir = "desc";
          } else {
            break;
          }
        }
      }
    }
  </script>
</body>
</html>
''';
}
