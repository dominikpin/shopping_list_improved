import 'package:flutter/material.dart';

import '../classes/item.dart';
import '../classes/store.dart';
import '../storage/local_storage.dart';

class ItemCard extends StatefulWidget {
  final List<Item> list;
  final Store store;
  final int index;
  final Function updateProgressBar;

  const ItemCard({
    super.key,
    required this.list,
    required this.store,
    required this.index,
    required this.updateProgressBar,
  });

  @override
  State<ItemCard> createState() => _ItemCard();
}

class _ItemCard extends State<ItemCard> {
  bool canChangeName = false;

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
              value: widget.list[widget.index].isChecked,
              onChanged: (value) {
                setState(() {
                  widget.list[widget.index].isChecked = value!;
                  Storage.saveItem(widget.list[widget.index]);
                  widget.updateProgressBar();
                });
              },
              fillColor:
                  MaterialStateColor.resolveWith((states) => Colors.grey[900]!),
              side: const BorderSide(
                width: 2.0,
                style: BorderStyle.solid,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: canChangeName
                ? TextField(
                    onSubmitted: (newName) async {
                      Item? item = await Storage.checkIfItemExists(newName);
                      if (item != null) {
                        if (widget.list
                            .any((element) => element.id == item.id)) {
                          canChangeName = false;
                          setState(() {});
                          showSnackbar(
                              'This item already exists on your ${widget.store.id} shopping list');
                          return;
                        }
                        if (widget.list[widget.index].storeList.length < 2) {
                          Storage.deleteStoreOrItem(false,
                              widget.list[widget.index].id, widget.store.id);
                        } else {
                          widget.list[widget.index].storeList
                              .remove(widget.store.id);
                          widget.store.storeItemList.removeAt(widget.index);
                        }
                        debugPrint(
                            '${widget.index.toString()}, ${widget.list[widget.index].id}');
                        widget.list.removeAt(widget.index);
                        widget.list.insert(widget.index, item);
                        item.storeList.add(widget.store.id);
                        widget.store.storeItemList
                            .insert(widget.index, item.id);
                        await Storage.saveStore(widget.store);
                      } else {
                        widget.list[widget.index].name = newName;
                      }
                      await Storage.saveItem(widget.list[widget.index]);
                      canChangeName = false;
                      setState(() {});
                      widget.updateProgressBar();
                    },
                    onTapOutside: (oldName) {
                      canChangeName = false;
                      setState(() {});
                    },
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: widget.list[widget.index].name,
                    ),
                  )
                : Text(
                    widget.list[widget.index].name,
                    style: !widget.list[widget.index].isChecked
                        ? const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )
                        : TextStyle(
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.lineThrough,
                            decorationThickness: 3.0,
                          ),
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
                  Storage.deleteStoreOrItem(
                      false, widget.list[widget.index].id, widget.store.id);
                  widget.store.storeItemList.removeWhere(
                      (element) => element == widget.list[widget.index].id);
                  widget.list.removeAt(widget.index);
                  widget.updateProgressBar();
                  setState(() {});
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
