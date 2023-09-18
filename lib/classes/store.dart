class Store {
  String name;
  int id;
  int order;
  String imageLocation;
  List<int> storeItemList;

  Store({
    required this.name,
    required this.id,
    required this.order,
    required this.imageLocation,
    required this.storeItemList,
  });

  Store.empty()
      : name = '',
        id = 0,
        order = 0,
        imageLocation = '',
        storeItemList = [];
}
