import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import '../classes/item.dart';
import '../classes/store.dart';
import '../my_widgets/item_card.dart';
import '../my_widgets/reorderable_card_list.dart';
import '../storage/local_storage.dart';

class ItemList extends StatefulWidget {
  const ItemList({super.key});

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  List<Item> itemList = [];
  String storeName = 'Store';
  final textController = TextEditingController();
  late Store store;
  double progress = 0;
  bool alphaOrder = false;
  bool keyboardOpen = false;
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();

    var keyboardVisibilityController = KeyboardVisibilityController();

    keyboardSubscription = keyboardVisibilityController.onChange.listen(
      (bool visible) {
        debugPrint(visible ? "UP" : "DOWN");
        keyboardOpen = visible;
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    Map args = ModalRoute.of(context)!.settings.arguments as Map;
    store = args['store'];
    storeName = store.name;
    List<int> idItemList = store.storeItemList;
    itemList = await Storage.loadAllItems(idItemList);
    alphaOrder = await Storage.loadAlphaOrder(2);
    updateProgressBar();
    setState(() {});
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  addItemToList(String itemName) async {
    Item? item = await Storage.checkIfItemExists(itemName);
    if (item != null) {
      if (store.storeItemList.contains(item.id)) {
        showSnackbar(
            'This item is already on your ${store.name} shopping list.');
        textController.clear();

        return;
      }
      item.storeList.add(store.id);
      itemList.add(item);
      store.storeItemList.add(item.id);
      Storage.saveItem(item);
    } else {
      int newId = await Storage.generateIdNumber(false);
      Item newItem = Item(
        name: itemName,
        id: newId,
        isChecked: false,
        storeList: [],
      );
      newItem.storeList.add(store.id);
      itemList.add(newItem);
      Storage.saveItem(newItem);
      store.storeItemList.add(newItem.id);
    }
    Storage.saveStore(store);
    textController.clear();
    updateProgressBar();
    setState(() {});
  }

  Future<dynamic> showNewItemSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15.0),
        ),
      ),
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Wrap(
            children: [
              TextField(
                onSubmitted: (value) {
                  addItemToList(textController.text);
                  Navigator.pop(context);
                },
                autofocus: true,
                controller: textController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'Name of new item',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: TextButton(
                  onPressed: () {
                    addItemToList(textController.text);
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void updateProgressBar() {
    if (itemList.isEmpty) {
      progress = 0;
    } else {
      int numberOfIsChecked = 0;
      for (Item item in itemList) {
        if (item.isChecked) numberOfIsChecked++;
      }
      progress = numberOfIsChecked / itemList.length;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(storeName),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        actions: [
          Visibility(
            visible: kDebugMode,
            child: IconButton(
              onPressed: () {
                Storage.printAllSavedData();
              },
              icon: const Icon(Icons.print),
            ),
          ),
          Semantics(
            container: true,
            label: 'Alphabetical switch',
            checked: alphaOrder,
            value: 'Feature is ${alphaOrder ? 'enabled' : 'disabled'}',
            increasedValue: 'Tap to disable feature',
            decreasedValue: 'Tap to enable feature',
            child: Switch(
              onChanged: (bool value) async {
                await Storage.saveAlphaOrder(value, 2);
                alphaOrder = value;
                setState(() {});
              },
              value: alphaOrder,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Visibility(
            visible: itemList.isNotEmpty,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 20,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                        minHeight: 20,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          alphaOrder
              ? Expanded(
                  child: ListView.builder(
                    itemCount: itemList.length + 1,
                    itemBuilder: (context, index) {
                      if (index < itemList.length) {
                        itemList.sort(
                          (a, b) {
                            if (a.isChecked && !b.isChecked) {
                              return 1;
                            } else if (!a.isChecked && b.isChecked) {
                              return -1;
                            } else {
                              return a.name
                                  .toLowerCase()
                                  .compareTo(b.name.toLowerCase());
                            }
                          },
                        );
                        return ItemCard(
                          list: itemList,
                          store: store,
                          index: index,
                          updateProgressBar: updateProgressBar,
                        );
                      } else {
                        return Card(
                          color: Colors.grey[850],
                          child: const SizedBox(height: 150),
                        );
                      }
                    },
                  ),
                )
              : Expanded(
                  child: ReorderableCardList(
                    list: itemList,
                    store: store,
                    updateProgressBarOrRemoveStore: updateProgressBar,
                  ),
                ),
        ],
      ),
      floatingActionButton: keyboardOpen
          ? const SizedBox()
          : FloatingActionButton(
              heroTag: 'addItem',
              child: const Icon(Icons.add, semanticLabel: 'Add new item'),
              onPressed: () {
                showNewItemSheet(context);
              },
            ),
    );
  }
}
