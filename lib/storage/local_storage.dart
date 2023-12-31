import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../classes/item.dart';
import '../classes/store.dart';

class Storage {
  static const String itemKeyPrefix = 'item_';
  static const String storeKeyPrefix = 'store_';
  static const String alphaOrderKey = 'alphaOrder';

  static Future<void> saveAlphaOrder(bool alphaOrder, int number) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('$alphaOrderKey$number', alphaOrder.toString());
  }

  static Future<bool> loadAlphaOrder(int number) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? alphaOrderString = prefs.getString('$alphaOrderKey$number');
    if (alphaOrderString == null) {
      return false;
    }
    return alphaOrderString.toLowerCase() == 'true';
  }

  static Future<void> saveAllStores(List<Store> stores) async {
    for (Store store in stores) {
      saveStore(store);
    }
  }

  static Future<void> saveStore(Store store) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = '$storeKeyPrefix${store.id}';
    final value = {
      'name': store.name,
      'id': store.id,
      'order': store.order,
      'imageLocation': store.imageLocation,
      'storeItemList': store.storeItemList
    };
    final valueJson = json.encode(value);
    await prefs.setString(key, valueJson);
  }

  static saveStoreImage(Store store) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    int lastId = 0;
    if (store.imageLocation != '') {
      int dirLength = directory.path.length;
      lastId = int.parse(
          store.imageLocation.substring(dirLength + 9, dirLength + 9 + 8));
      if (File(store.imageLocation).existsSync()) {
        File(store.imageLocation).deleteSync();
      }
    }
    late int newId;
    do {
      newId = generateRandomIdNumber(8);
    } while (newId == lastId);

    final String imagePath = '${directory.path}/${store.id}${newId}Image.png';
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final image = File(pickedFile.path);
      await image.copy(imagePath);
      store.imageLocation = imagePath;
      Storage.saveStore(store);
    }
  }

  static Future<void> deleteAllImages() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory(directory.path);

    if (imagesDirectory.existsSync()) {
      final List<FileSystemEntity> files = imagesDirectory.listSync();

      for (final FileSystemEntity file in files) {
        if (file is File && file.path.endsWith('.png')) {
          file.deleteSync();
        }
      }
    }
  }

  static Future<List<Store>> loadAllStores() async {
    List<Store> stores = [];
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(storeKeyPrefix));
    for (String key in keys) {
      Store? loadedStore = await loadStore(key);
      if (loadedStore != null) stores.add(loadedStore);
    }
    stores.sort((a, b) => a.order.compareTo(b.order));
    return stores;
  }

  static Future<Store?> loadStore(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final valueJson = prefs.getString(key);
    if (valueJson != null) {
      final value = json.decode(valueJson);
      final store = Store(
        name: value['name'],
        id: value['id'],
        order: value['order'],
        imageLocation: value['imageLocation'],
        storeItemList: List<int>.from(value['storeItemList']),
      );
      return store;
    }
    return null;
  }

  static Future<void> saveAllItems(List<Item> items) async {
    for (Item item in items) {
      saveItem(item);
    }
  }

  static Future<void> saveItem(Item item) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$itemKeyPrefix${item.id}';
    final value = {
      'name': item.name,
      'id': item.id,
      'isChecked': item.isChecked,
      'storeList': item.storeList,
    };
    final valueJson = json.encode(value);
    await prefs.setString(key, valueJson);
  }

  static Future<Item?> checkIfItemExists(String name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(itemKeyPrefix));
    for (String key in keys) {
      Item? loadedItem = await loadItem(key);
      if (loadedItem != null && loadedItem.name == name) return loadedItem;
    }
    return null;
  }

  static Future<List<Item>> loadAllItems(List<int> listOfIds) async {
    List<Item> items = [];
    for (int id in listOfIds) {
      Item? loadedItem = await loadItem('$itemKeyPrefix$id');
      if (loadedItem != null) items.add(loadedItem);
    }
    return items;
  }

  static Future<Item?> loadItem(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final valueJson = prefs.getString(key);
    if (valueJson != null) {
      final value = json.decode(valueJson);
      final item = Item(
        name: value['name'],
        id: value['id'],
        isChecked: value['isChecked'],
        storeList: List<int>.from(value['storeList']),
      );
      return item;
    }
    return null;
  }

  static Future<int> generateIdNumber(bool isStore) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (key) =>
              key.startsWith(storeKeyPrefix) && isStore ||
              key.startsWith(itemKeyPrefix) && !isStore,
        );
    late int newId;
    do {
      newId = generateRandomIdNumber(8);
    } while (
        keys.contains('${isStore ? storeKeyPrefix : itemKeyPrefix}$newId'));
    return newId;
  }

  static int generateRandomIdNumber(int n) {
    final int min = pow(10, n - 1) as int;
    final int max = pow(10, n) - 1 as int;

    final Random random = Random();
    final int randomNumber = min + random.nextInt(max - min + 1);

    return randomNumber;
  }

  static printAllSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (key) =>
              key.startsWith(storeKeyPrefix) || key.startsWith(itemKeyPrefix),
        );
    for (final key in keys) {
      if (key.startsWith(storeKeyPrefix)) {
        Store? store = await loadStore(key);
        if (store != null) {
          debugPrint(
              'STORE. name: ${store.name}, id: ${store.id}, order: ${store.order}, storeList: ${store.storeItemList.toString()}');
        }
      } else {
        Item? item = await loadItem(key);
        if (item != null) {
          debugPrint(
              'ITEM. name: ${item.name}, id: ${item.id}, storeList: ${item.storeList.toString()}');
        }
      }
    }
  }

  static exportAllData() async {
    try {
      List<String> allJsonItems = [];
      List<String> allJsonStores = [];
      List<String> allAlphaOrder = [];

      bool alphaOrder1 = await loadAlphaOrder(1);
      allAlphaOrder.add(alphaOrder1.toString());
      bool alphaOrder2 = await loadAlphaOrder(2);
      allAlphaOrder.add(alphaOrder2.toString());

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
            (key) =>
                key.startsWith(storeKeyPrefix) || key.startsWith(itemKeyPrefix),
          );
      for (String key in keys) {
        if (key.contains(itemKeyPrefix)) {
          Item? item = await loadItem(key);
          if (item != null) {
            final value = {
              'name': item.name,
              'id': item.id,
              'isChecked': item.isChecked,
              'storeList': item.storeList,
            };
            final valueJson = json.encode(value);
            allJsonItems.add(valueJson);
          }
        } else {
          Store? store = await loadStore(key);
          if (store != null) {
            final value = {
              'name': store.name,
              'id': store.id,
              'order': store.order,
              'imageLocation': store.imageLocation,
              'storeItemList': store.storeItemList
            };
            final valueJson = json.encode(value);
            allJsonStores.add(valueJson);
          }
        }
      }
      final allData = {
        'stores': allJsonStores,
        'items': allJsonItems,
        'alphaOrder': allAlphaOrder,
      };

      final String? directoryPath =
          await FilePicker.platform.getDirectoryPath();

      if (directoryPath != null) {
        final directory = Directory(directoryPath);

        if (await directory.exists()) {
          final file = File(
              '${directory.path}/combined_data${generateRandomIdNumber(8)}.json');
          final encodedData = jsonEncode(allData);
          await file.writeAsString(encodedData);
          debugPrint('Combined data saved to ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('ERROR');
    }
  }

  static importNewData() async {
    try {
      deleteAll();
      String? filePath;

      FilePickerResult? result;
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        filePath = result.files.first.path;
      }

      if (filePath != null) {
        String jsonData = await File(filePath).readAsString();

        Map<String, dynamic> data = json.decode(jsonData);

        List<Store> stores = List<Store>.from(
          data['stores'].map(
            (storeJson) {
              Map<String, dynamic> storeData = json.decode(storeJson);
              return Store(
                name: storeData['name'],
                id: storeData['id'],
                order: storeData['order'],
                imageLocation: storeData['imageLocation'],
                storeItemList: List<int>.from(storeData['storeItemList']),
              );
            },
          ),
        );

        saveAllStores(stores);

        List<Item> items = List<Item>.from(
          data['items'].map(
            (itemJson) {
              Map<String, dynamic> itemData = json.decode(itemJson);
              return Item(
                name: itemData['name'],
                id: itemData['id'],
                isChecked: itemData['isChecked'],
                storeList: List<int>.from(itemData['storeList']),
              );
            },
          ),
        );
        saveAllItems(items);

        List<bool> alphaOrderList = List<bool>.from(
          data['alphaOrder'].map(
            (alphaOrderJson) {
              bool alphaOrderData = json.decode(alphaOrderJson);
              return alphaOrderData;
            },
          ),
        );
        saveAlphaOrder(alphaOrderList[0], 1);
        saveAlphaOrder(alphaOrderList[1], 2);
      }
    } catch (e) {
      debugPrint('Error');
    }
  }

  static Future<void> deleteStoreOrItem(
      bool isStore, int id, int storeId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!isStore) {
      Item? item = await loadItem('$itemKeyPrefix$id');
      Store? store = await loadStore('$storeKeyPrefix$storeId');
      if (item != null) {
        item.storeList.remove(storeId);
        await Storage.saveItem(item);
        if (item.storeList.isEmpty) {
          await prefs.remove('$itemKeyPrefix$id');
        }
      }
      if (store != null) {
        store.storeItemList.remove(id);
        saveStore(store);
      }
    } else {
      Store? store = await loadStore('$storeKeyPrefix$id');
      if (store != null) {
        List<Item> items = await loadAllItems(store.storeItemList);
        for (Item item in items) {
          deleteStoreOrItem(false, item.id, store.id);
        }
        if (store.imageLocation != '') {
          if (File(store.imageLocation).existsSync()) {
            File(store.imageLocation).deleteSync();
          }
        }
      }
      await prefs.remove('$storeKeyPrefix$id');
    }
  }

  static Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (key) =>
              key.startsWith(storeKeyPrefix) ||
              key.startsWith(itemKeyPrefix) ||
              key.startsWith(alphaOrderKey),
        );
    for (final key in keys) {
      if (key.contains(storeKeyPrefix)) {
        Store? store = await loadStore(key);
        if (store != null &&
            store.imageLocation != '' &&
            File(store.imageLocation).existsSync()) {
          File(store.imageLocation).deleteSync();
        }
      }
      await prefs.remove(key);
    }
  }
}
