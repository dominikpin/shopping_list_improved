import 'dart:io';

import 'package:flutter/material.dart';

import '../classes/store.dart';
import '../storage/local_storage.dart';

class StoreCard extends StatefulWidget {
  final Store store;
  final int index;
  final Function removeStore;

  const StoreCard({
    super.key,
    required this.store,
    required this.index,
    required this.removeStore,
  });

  @override
  State<StoreCard> createState() => _StoreCard();
}

class _StoreCard extends State<StoreCard> {
  bool canChangeName = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/ItemList',
                  arguments: {
                    'store': widget.store,
                  },
                );
              },
              title: canChangeName
                  ? TextField(
                      onSubmitted: (newName) {
                        widget.store.name = newName;
                        Storage.saveStore(widget.store);
                        canChangeName = false;
                        setState(() {});
                      },
                      onTapOutside: (oldName) {
                        canChangeName = false;
                        setState(() {});
                      },
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: widget.store.name,
                      ),
                    )
                  : Text(widget.store.name),
              leading: widget.store.imageLocation.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.all(3),
                      child: File(widget.store.imageLocation).existsSync()
                          ? Image.file(File(widget.store.imageLocation))
                          : const Icon(Icons.shopping_cart_rounded),
                    )
                  : const Icon(Icons.shopping_cart_rounded),
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: '1',
                  child: Text('Change name'),
                ),
                const PopupMenuItem<String>(
                  value: '2',
                  child: Text('Add/change image'),
                ),
                const PopupMenuItem<String>(
                  value: '3',
                  child: Text('Delete'),
                ),
              ];
            },
            onSelected: (String value) async {
              switch (value) {
                case '1':
                  canChangeName = true;
                  setState(() {});
                  break;
                case '2':
                  await Storage.saveStoreImage(widget.store);
                  setState(() {});
                  break;
                case '3':
                  widget.removeStore(widget.index);
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
