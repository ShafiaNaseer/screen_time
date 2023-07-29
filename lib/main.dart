import 'dart:convert';
import 'package:screen_time/screen_time.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:usage_stats/usage_stats.dart';
import 'package:device_apps/device_apps.dart';

import 'dev.dart';

void main() {
  runApp(const Dev());
}
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<EventUsageInfo> events = [];
  Map<String, double> _usageMap = {};
  Map<String, String> _appIcons = {};
  List<Application> apps = [];
  List<String> runningAppNames = [];


  @override
  void initState() {
    initUsage();
    super.initState();
  }
  Future<void> initUsage() async {
    try {
      UsageStats.grantUsagePermission();
      DateTime endDate = DateTime.now();
      DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);
      List<EventUsageInfo> queryEvents = await UsageStats.queryEvents(startDate, endDate);
      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      List<UsageInfo> filteredUsageStats = usageStats
          .where((info) => double.parse(info.totalTimeInForeground!) > 0)
          .toList();

      Map<String, double> usageMap = {};
      for (var info in filteredUsageStats) {
        double usageTime = double.parse(info.totalTimeInForeground!) / 1000 / 60;
        if (usageMap.containsKey(info.packageName)) {
          usageMap[info.packageName!] =
              (usageMap[info.packageName!] ?? 0) + usageTime;
        } else {
          usageMap[info.packageName!] = usageTime;
        }
      }

      // Retrieve and store app icons
      apps = await DeviceApps.getInstalledApplications(
        onlyAppsWithLaunchIntent: true,
        includeAppIcons: true,
        includeSystemApps: true,
      );
      // Retrieve and store app icons only for running apps
      _appIcons.clear();
      runningAppNames.clear();
      for (var app in apps) {
        if (usageMap.containsKey(app.packageName)) {
          runningAppNames.add(app.appName);
          if (app is ApplicationWithIcon) {
            String appIcon = base64Encode(app.icon);
            _appIcons[app.appName] = appIcon;
          }
        }
      }

      setState(() {
        events = queryEvents.reversed.toList();
        _usageMap = usageMap;
      });
    } catch (err) {
      print(err);
    }
  }

  String formatDuration(double milliseconds) {
    Duration duration = Duration(milliseconds: milliseconds.toInt());
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Usage Stats"),
          actions: const [
            IconButton(
              onPressed: UsageStats.grantUsagePermission,
              icon: Icon(Icons.settings),
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: initUsage,
          child: ListView.builder(
            itemCount: runningAppNames.length,
            itemBuilder: (context, index) {
              String appName = runningAppNames[index];
              String? packageName;
              for (var app in apps) {
                if (app.appName == appName) {
                  packageName = app.packageName;
                  break;
                }
              }
              double? usageTime = packageName != null ? _usageMap[packageName] : null;
              String? appIcon = _appIcons[appName];
              print('iconnn: $appIcon');
              print("Appp: $usageTime");
              return CustomListTile(
                leading: appIcon != null
                    ? Image.memory(
                  base64Decode(appIcon),
                  width: 48,
                  height: 48,
                )
                    : Container(),
                title: Text(appName),
                subtitle: Text(
                    'Usage Today: ${formatDuration((usageTime ?? 0) * 60 * 1000)}'),
                    //'Usage Today: ${formatDuration((usageTime ?? 0) * 60 * 1000)}'),
                trailing: Text("$index"),
              );
            },

          ),
        ),
      ),
    );
  }
}

class CustomListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;

  const CustomListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: leading,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title!,
                subtitle!,
              ],
            ),
          ),
          SizedBox(width: 12),
          trailing!,
        ],
      ),
    );
  }
}
