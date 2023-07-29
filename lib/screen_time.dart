import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';

class MyAppTwo extends StatefulWidget {
  const MyAppTwo({super.key});

  @override
  _MyAppTwoState createState() => _MyAppTwoState();
}

class _MyAppTwoState extends State<MyAppTwo> {
  List<AppUsageInfo> _infos = [];

  @override
  void initState() {
    super.initState();
  }

  void getUsageStats() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(hours: 1));
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(startDate, endDate);

      // Filter out system apps and background running apps
      List<AppUsageInfo> filteredApps = infoList.where((info) {
        if (info.packageName.startsWith("com.android") ||
            info.packageName.startsWith("com.google.android")) {
          return false;
        }
        return info.usage.inSeconds > 0;
      }).toList();

      // Sort the apps in descending order based on usage time
      filteredApps.sort((a, b) => b.usage.inSeconds.compareTo(a.usage.inSeconds));

      setState(() => _infos = filteredApps);

      for (var info in filteredApps) {
        print(info.toString());
      }
    } on AppUsageException catch (exception) {
      print(exception);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('App Usage Example'),
          backgroundColor: Colors.green,
        ),
        body: ListView.builder(
          itemCount: _infos.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_infos[index].appName),
              trailing: Text(_infos[index].usage.toString()),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: getUsageStats,
          child: Icon(Icons.file_download),
        ),
      ),
    );
  }
}
