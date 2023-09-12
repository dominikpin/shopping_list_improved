import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../classes/item.dart';
import '../classes/store.dart';
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

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    Map args = ModalRoute.of(context)!.settings.arguments as Map;
    store = args['store'];
    storeName = store.name;
    List<int> idItemList = store.storeItemList;
    itemList = await Storage.loadAllItems(idItemList);
    updateProgressBar();
    setState(() {});
  }

  printItemList() {
    for (var item in itemList) {
      {
        debugPrint('${item.name}, ${item.id}, ${item.isChecked}');
      }
    }
  }

  addItemToList(String itemName) async {
    // TODO if already on widget.list, notify user its alredy there
    Item? item = await Storage.checkIfItemExists(itemName);
    if (item != null) {
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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(storeName),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        actions: [
          Visibility(
            visible: kDebugMode,
            child: IconButton(
              onPressed: () {
                printItemList();
              },
              icon: const Icon(Icons.print),
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
              decoration: BoxDecoration(
                color: Colors.grey[800],
                border: const Border(
                  bottom: BorderSide(
                    color: Colors.grey,
                  ),
                ),
              ),
              child: SizedBox(
                height: 20,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[700],
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ReorderableCardList(
              list: itemList,
              isChangeNameSelectedList:
                  List.generate(itemList.length, (index) => false),
              store: store,
              updateProgressBar: updateProgressBar,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addItem',
        child: const Icon(Icons.add),
        onPressed: () {
          showNewItemSheet(context);
        },
      ),
    );
  }
}
