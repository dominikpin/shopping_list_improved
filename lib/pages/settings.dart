import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Store list'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
      ),
      // TODO add options (change color theme)
      body: Column(
        children: [
          TextButton(
            onPressed: () {
              // TODO ask user if they are sure to delete curent data
              Storage.deleteAll();
              List<Store> storeList = [];
              updateStoreList(storeList);
            },
            child: const Text('Delete everything'),
          ),
          TextButton(
            onPressed: () {
              // TODO ask user if they are sure to delete curent data
              Storage.exportAllData();
            },
            child: const Text('Export data'),
          ),
          TextButton(
            onPressed: () async {
              await Storage.importNewData();
              List<Store> storeList = await Storage.loadAllStores();
              Storage.printAllSavedData();
              updateStoreList(storeList);
            },
            child: const Text('Import data'),
          ),
        ],
      ),
    );
  }
}
