import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../classes/store.dart';
import '../my_widgets/reorderable_card_list.dart';
import '../storage/local_storage.dart';

class StoreList extends StatefulWidget {
  const StoreList({super.key});

  @override
  State<StoreList> createState() => _StoreListState();
}

class _StoreListState extends State<StoreList> {
  List<Store> storeList = [];
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadStores();
  }

  Future<void> loadStores() async {
    storeList = await Storage.loadAllStores();
    setState(() {});
  }

  printStoreList() {
    for (var store in storeList) {
      {
        debugPrint(
          'Store name: ${store.name}, id: ${store.id}, order: ${store.order}, Store IMGpath: ${store.imageLocation} Store items: ${store.storeItemList.map((item) => item).join(', ')}',
        );
      }
    }
  }

  void updateStoreList(List<Store> updatedList) {
    setState(() {
      storeList = updatedList;
    });
  }

  addShopToList(String storeName) async {
    int newId = await Storage.generateIdNumber(true);
    Store newStore = Store(
      name: storeName,
      id: newId,
      order: storeList.length,
      imageLocation: '',
      storeItemList: [],
    );
    storeList.add(newStore);
    Storage.saveStore(newStore);
    textController.clear();
    setState(() {});
  }

  Future<dynamic> showNewStoreSheet(BuildContext context) {
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
                  addShopToList(textController.text);
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
                    addShopToList(textController.text);
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

  void emptyFunction() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Store list'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        actions: [
          Visibility(
            visible: kDebugMode,
            child: IconButton(
              onPressed: () {
                printStoreList();
              },
              icon: const Icon(Icons.print),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/Settings',
                arguments: {
                  'updateStoreList': updateStoreList,
                },
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ReorderableCardList(
        list: storeList,
        isChangeNameSelectedList:
            List.generate(storeList.length, (index) => false),
        store: Store(
            name: '', id: 0, order: 0, imageLocation: '', storeItemList: []),
        updateProgressBar: emptyFunction,
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 20.0,
            left: 50.0,
            child: FloatingActionButton(
              heroTag: 'showAll',
              child: const Icon(Icons.list),
              onPressed: () async {
                // Navigator.pushNamed(
                //   context,
                //   '/AllList',
                //   arguments: {
                //     'storeList': storeList,
                //     'saveShopList': saveShopList,
                //   },
                // );
              },
            ),
          ),
          Positioned(
            bottom: 20.0,
            right: 20.0,
            child: FloatingActionButton(
              heroTag: 'addStore',
              child: const Icon(Icons.add),
              onPressed: () {
                showNewStoreSheet(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
