import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shopping_list/my_widgets/item_card.dart';
import 'package:shopping_list/my_widgets/store_card.dart';

import '../classes/item.dart';
import '../classes/store.dart';
import '../storage/local_storage.dart';

class ReorderableCardList<T> extends StatefulWidget {
  final List<T> list;
  final Store store;
  final Function updateProgressBarOrRemoveStore;

  const ReorderableCardList({
    super.key,
    required this.list,
    required this.store,
    required this.updateProgressBarOrRemoveStore,
  });
  @override
  State<ReorderableCardList> createState() => _ReorderableCardListState();
}

class _ReorderableCardListState<T> extends State<ReorderableCardList> {
  @override
  Widget build(BuildContext context) {
    if (widget.list.isEmpty || widget.list[0] is Store) {
      widget.list.sort((a, b) => a.order.compareTo(b.order));
    } else {
      widget.list.sort((a, b) {
        final indexA = widget.store.storeItemList.indexOf(a.id);
        final indexB = widget.store.storeItemList.indexOf(b.id);
        return indexA.compareTo(indexB);
      });
    }
    final List<Widget> cards = <Widget>[
      for (int index = 0; index < widget.list.length; index++)
        widget.list[index] is Store
            ? StoreCard(
                key: Key('$index'),
                store: widget.list[index],
                index: index,
                removeStore: widget.updateProgressBarOrRemoveStore,
              )
            : ItemCard(
                key: Key('$index'),
                list: widget.list as List<Item>,
                store: widget.store,
                index: index,
                updateProgressBar: widget.updateProgressBarOrRemoveStore,
              )
    ];

    cards.add(
      Card(
        color: Colors.grey[850],
        key: const Key('emptyCard'),
        child: const SizedBox(height: 150),
      ),
    );

    Widget proxyDecorator(
        Widget child, int index, Animation<double> animation) {
      if (index == cards.length - 1) {
        return child;
      }
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double scale = lerpDouble(1, 1.02, animValue)!;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: child,
      );
    }

    return ReorderableListView(
      proxyDecorator: proxyDecorator,
      onReorder: (int oldIndex, int newIndex) {
        debugPrint('$oldIndex');
        if (oldIndex < cards.length - 1) {
          setState(
            () {
              if (newIndex == cards.length) {
                newIndex -= 1;
              }
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
        }
      },
      children: [
        for (int index = 0; index < cards.length - 1; index++) cards[index],
        GestureDetector(
          key: const Key('emptyCard'),
          onLongPress: () {},
          child: cards.last,
        ),
      ],
    );
  }
}
