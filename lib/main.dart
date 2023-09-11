import 'package:flutter/material.dart';
import 'package:shopping_list/pages/item_list.dart';
import 'pages/store_list.dart';

void main() {
  runApp(
    MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const StoreList(),
        '/ItemList': (context) => const ItemList(),
        //'/AllList': (context) => AllList(),
      },
    ),
  );
}
