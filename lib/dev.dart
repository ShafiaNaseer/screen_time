import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:device_apps/device_apps.dart';
import 'package:usage_stats/usage_stats.dart';

class Dev extends StatefulWidget {
  const Dev({Key? key}) : super(key: key);

  @override
  _DevState createState() => _DevState();
}

class _DevState extends State<Dev> {
  List<EventUsageInfo> events = [];
  Map<String, String> appIcons = {};
  List<Application> apps = [];
  List sortedMap = [];

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
      List<EventUsageInfo> queryEvents =
      await UsageStats.queryEvents(startDate, endDate);
      List<UsageInfo> usageStats =
      await UsageStats.queryUsageStats(startDate, endDate);
      List<UsageInfo> filteredUsageStats = usageStats
          .where((info) => double.parse(info.totalTimeInForeground!) > 0)
          .toList();

      Map<String, double> usageMap = {};
      for (var info in filteredUsageStats) {
        double usageTime =
            double.parse(info.totalTimeInForeground!) / 1000 / 60;
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
      appIcons.clear();
      for (var app in apps) {
          if (app is ApplicationWithIcon) {
            String appIcon = base64Encode(app.icon);
            appIcons[app.appName] = appIcon;
            print('icons: ${appIcons[app.appName]}');
        }
      }
      setState(() {
        events = queryEvents.reversed.toList();
        sortedMap = usageMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        print("hiii: $sortedMap");

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
            itemCount: sortedMap.length,
            itemBuilder: (context, index) {
              String packageName = sortedMap[index].key;
              double usageTime = sortedMap[index].value;
              String? appName;
              for (var app in apps) {
                if (app.packageName == packageName) {
                  appName = app.appName;
                  break;
                }
              }

              // Check if the app name exists in the sortedMap
              if (appName != null) {
                String? appIcon = appIcons[appName];
                return CustomListTile(
                  leading: appIcon != null
                      ? Image.memory(
                    base64Decode(appIcon),
                    width: 48,
                    height: 48,
                  )
                      : Container(),
                  title: Text(appName),
                  subtitle: Text('Usage Today: ${formatDuration((usageTime ?? 0) * 60 * 1000)}'),
                  trailing: Text("$index"),
                );
              } else {
                // App name not found in sortedMap, return an empty container
                return Container();
              }
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
            width: 30,
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
