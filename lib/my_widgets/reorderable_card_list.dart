import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../classes/item.dart';
import '../classes/store.dart';
import '../storage/local_storage.dart';

class ReorderableCardList<T> extends StatefulWidget {
  final List<T> list;
  final List<bool> isChangeNameSelectedList;
  final Store store;
  final Function updateProgressBar;
  const ReorderableCardList({
    super.key,
    required this.list,
    required this.isChangeNameSelectedList,
    required this.store,
    required this.updateProgressBar,
  });
  @override
  State<ReorderableCardList> createState() => _ReorderableCardListState();
}

class _ReorderableCardListState<T> extends State<ReorderableCardList> {
  Widget buildStoreCard(int index) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/ItemList',
                arguments: {
                  'store': widget.list[index],
                },
              );
            },
            title: widget.isChangeNameSelectedList[index]
                ? TextField(
                    onSubmitted: (newName) {
                      widget.list[index].name = newName;
                      Storage.saveStore(widget.list[index]);
                      widget.isChangeNameSelectedList[index] = false;
                      setState(() {});
                    },
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '${widget.list[index].name}',
                    ),
                  )
                : Text(widget.list[index].name),
            leading: widget.list[index].imageLocation.isNotEmpty
                ? Container(
                    margin: const EdgeInsets.all(3),
                    child: File(widget.list[index].imageLocation).existsSync()
                        ? Image.file(File(widget.list[index].imageLocation))
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
                widget.isChangeNameSelectedList[index] = true;
                setState(() {});
                break;
              case '2':
                await Storage.saveStoreImage(widget.list[index]);
                setState(() {});
                break;
              case '3':
                Storage.deleteStoreOrItem(
                    true, widget.list.elementAt(index).id, 0);
                widget.list.removeAt(index);
                setState(() {});
                break;
            }
          },
        ),
      ],
    );
  }

  Widget buildItemCard(int index, Store store) {
    return Row(
      children: [
        Transform.scale(
          scale: 1.5,
          child: Checkbox(
            value: widget.list[index].isChecked,
            onChanged: (value) {
              setState(
                () {
                  widget.list[index].isChecked = value!;
                  Storage.saveItem(widget.list[index]);
                  widget.updateProgressBar();
                },
              );
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
          child: widget.isChangeNameSelectedList[index]
              ? TextField(
                  onSubmitted: (newName) {
                    // TODO check if newName already exists
                    widget.list[index].name = newName;
                    Storage.saveItem(widget.list[index]);
                    widget.isChangeNameSelectedList[index] = false;
                    setState(() {});
                  },
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '${widget.list[index].name}',
                  ),
                )
              : Text(
                  widget.list[index].name,
                  style: !widget.list[index].isChecked
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
                widget.isChangeNameSelectedList[index] = true;
                setState(() {});
                break;
              case '2':
                Storage.deleteStoreOrItem(
                    false, widget.list[index].id, widget.store.id);
                widget.store.storeItemList
                    .removeWhere((element) => element == widget.list[index].id);
                widget.list.removeAt(index);
                widget.updateProgressBar();
                setState(() {});
                break;
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Card> cards = <Card>[
      for (int index = 0; index < widget.list.length; index++)
        widget.list[index] is Store
            ? Card(
                color: Colors.grey[350],
                key: Key('$index'),
                child: buildStoreCard(index),
              )
            : Card(
                color: Colors.grey[900],
                key: Key('$index'),
                child: buildItemCard(index, widget.store),
              ),
    ];

    Widget proxyDecorator(
        Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.02, animValue)!;
          return Transform.scale(
            scale: scale,
            child: Card(
              elevation: elevation,
              color: cards[index].color,
              child: cards[index].child,
            ),
          );
        },
        child: child,
      );
    }

    return ReorderableListView(
      proxyDecorator: proxyDecorator,
      onReorder: (int oldIndex, int newIndex) {
        setState(
          () {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = widget.list.removeAt(oldIndex);
            widget.list.insert(newIndex, item);
            List<int> idList = [];
            for (int i = 0; i < widget.list.length; i++) {
              if (widget.list[i] is Store) {
                (widget.list[i] as Store).order = i;
                Storage.saveStore(widget.list[i]);
              } else if (widget.list[i] is Item) {
                idList.add(widget.list[i].id);
              }
            }
            if (widget.list.isNotEmpty && widget.list[0] is Item) {
              widget.store.storeItemList = idList;
              Storage.saveStore(widget.store);
            }
          },
        );
      },
      children: cards,
    );
  }
}
