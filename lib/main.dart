import 'package:flutter/material.dart';
import 'pages/item_list.dart';
import 'pages/settings.dart';
import 'pages/store_list.dart';

void main() {
  runApp(
    MaterialApp(
      showSemanticsDebugger: true,
      title: 'Shopping list',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const StoreList(),
        '/ItemList': (context) => const ItemList(),
        '/Settings': (context) => const Settings(),
      },
    ),
  );
}
