import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../classes/store.dart';
import '../storage/local_storage.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final Function updateStoreList;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    Map args = ModalRoute.of(context)!.settings.arguments as Map;
    updateStoreList = args['updateStoreList'];
  }

  void showSnackbar(String message, bool isDelete) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Yes',
          onPressed: () async {
            if (isDelete) {
              Storage.deleteAll();
              List<Store> storeList = [];
              updateStoreList(storeList);
            } else {
              await Storage.importNewData();
              List<Store> storeList = await Storage.loadAllStores();
              Storage.printAllSavedData();
              updateStoreList(storeList);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store list'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.delete),
                title: const Text('Delete everything'),
                onPressed: (value) {
                  showSnackbar(
                    'Are you sure you want to delete all the data?',
                    true,
                  );
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('Export data'),
                onPressed: (value) {
                  Storage.exportAllData();
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Import data'),
                onPressed: (value) async {
                  showSnackbar(
                    'Are you sure you want to delete all current data and import new data?',
                    false,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      //   Column(
      //     children: [
      //       TextButton(
      //         onPressed: () {
      //           showSnackbar(
      //             'Are you sure you want to delete all the data?',
      //             true,
      //           );
      //         },
      //         child: const Text('Delete everything'),
      //       ),
      //       TextButton(
      //         onPressed: () {
      //           Storage.exportAllData();
      //         },
      //         child: const Text('Export data'),
      //       ),
      //       TextButton(
      //         onPressed: () async {
      //           showSnackbar(
      //             'Are you sure you want to delete all current data and import new data?',
      //             false,
      //           );
      //         },
      //         child: const Text('Import data'),
      //       ),
      //     ],
      //   ),
    );
  }
}
