import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'SlideableAnimatedList.dart';

// import 'DemoMenu.dart';

import 'Common.dart';
import 'StoreModel.dart';
import 'Home.dart';

class HomeView extends HomeState {

  // Returns index of item with given key
  int _indexOfKey(Key key) {
    return collection.book.indexWhere((CollectionBook d) => d.key == key);
  }

  bool _reorderCallback(Key item, Key newPosition) {
    int draggingIndex = _indexOfKey(item);
    int newPositionIndex = _indexOfKey(newPosition);

    // Uncomment to allow only even target reorder possition
    // if (newPositionIndex % 2 == 1) return false;

    final draggedItem = collection.book[draggingIndex];
    setState(() {
      // debugPrint("Reordering $item -> $newPosition");
      collection.book.removeAt(draggingIndex);
      collection.book.insert(newPositionIndex, draggedItem);
    });
    return true;
  }

  void _reorderDone(Key item) {
    store.writeCollection();
    // final draggedItem = collection.book[_indexOfKey(item)];
    // debugPrint("Reordering finished for ${draggedItem.name}}");
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: scaffoldKey,
      // backgroundColor: Colors.blue,
      body: ReorderableList(
        onReorder: _reorderCallback,
        onReorderDone: _reorderDone,
        child: FutureBuilder(
        future: store.getCollection(),
        builder: (BuildContext context, AsyncSnapshot<Collection> e){
          if (e.hasData){
            collectionGenerate(e.data);
            return _nested();
          } else if (e.hasError) {
            return WidgetError(message: e.error);
          } else {
            return WidgetLoad();
          }
        })
      ),
    );
  }

  Widget _nested() {
    return NestedScrollView(
      controller: store.scrollController,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          new SliverPersistentHeader(pinned: true,floating: true,delegate: new WidgetHeaderSliver(bar,minHeight: 70,maxHeight: 140)),
        ];
      },
      body: _nestedRefresh()
    );
  }

  Widget _nestedRefresh() {
    return RefreshConfiguration(
      // maxOverScrollExtent :100.0,
      child: SmartRefresher(
        enablePullDown: true,
        child: _body(),
        controller: refreshController,
        onRefresh: refreshUpdate,
        header: _refreshHeader()
      )
    );
  }


  Widget _refreshHeader() {
    return CustomHeader(
      refreshStyle: RefreshStyle.Behind,
      onOffsetChange: (offset) {
        if (refreshController.headerMode.value != RefreshStatus.refreshing)
          scaleController.value = offset / 80.0;
      },
      builder: (c, RefreshStatus mode) {
        Widget child;
        switch (mode) {
          case RefreshStatus.failed:
            child = Text("failed, please retry!");
            break;
          case RefreshStatus.completed:
            child = Text("Updated");
            break;
          case RefreshStatus.canRefresh:
            child = Text("Release to update");
            break;
          case RefreshStatus.refreshing:
            child = CircularProgressIndicator(strokeWidth: 1,);
            break;
          default:
            child = Text("Pull down to update");
            break;
        }
        return Container(
          child: FadeTransition(
            opacity: scaleController,
            child: child
          ),
          alignment: Alignment.center
        );
      },
    );
  }

  Widget _body() {
    return CustomScrollView(
      // controller: store.scrollController,
      slivers: <Widget>[
        new SliverPadding(
          padding: EdgeInsets.only(bottom: store.contentBottomPadding),
          sliver: SliverToBoxAdapter(
            child: booksAnimatedList()
          )
        )
      ]
    );
  }

  Widget bar(BuildContext context,double offset,bool overlaps, double stretch,double shrink){
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.lerp(Alignment(-0.5,0.5),Alignment(-0.7,0), stretch),
          child: Container(
            child: Text(
              store.appTitle,
              // 'the Holy Bible',
              style: TextStyle(
                fontFamily: "sans-serif",
                // color: Color.lerp(Colors.white, Colors.white24, stretch),
                color: Colors.black,
                fontWeight: FontWeight.w200,
                // fontWeight: FontWeight.lerp(FontWeight.w200, FontWeight.w300, stretch),
                fontSize:45 - (20*stretch),
                // shadows: <Shadow>[
                //   Shadow(offset: Offset(0, 1),blurRadius:1,color: Colors.black87)
                // ]
              )
            )
          )
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // CupertinoButton(
            //   // padding: EdgeInsets.zero,
            //   child: isUpdating?SizedBox(width:20, height:20,
            //     child:CircularProgressIndicator(strokeWidth: 1)
            //   ):new Icon(CupertinoIcons.refresh_circled,color: Colors.grey, size: 30),
            //   onPressed: updateCollectionCallBack
            // ),
            CupertinoButton(
              // padding: EdgeInsets.zero,
              child: new Icon(Icons.sort,color: isSorting?Colors.red:Colors.grey, size: 30),
              onPressed: (){
                if (isSorting) store.writeCollection();
                setState(() {
                  isSorting = !isSorting;
                });
              }
            ),
            // new DemoMenu()
          ]
        )
      ]
    );
  }

  Widget booksAnimatedList(){
    return AnimatedList(
      key: animatedListKey,
      physics: ScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      initialItemCount: collection.book.length,
      itemBuilder: booksItem
    );
  }

  Widget booksItem(BuildContext context, int index, Animation<double> animation){
    CollectionBook collectionBook = collection.book[index];
    return new SlideableAnimatedList(
      key: collectionBook.key,
      animation: animation,
      menu: booksItemWidget(collectionBook),
      menuRight: <Widget>[
        new RawMaterialButton(
          elevation: 0,
          highlightElevation: 0.0,
          fillColor: Colors.grey,
          shape: new RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(left: Radius.elliptical(100, 100))),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          child: new Icon(Icons.info,color: Colors.white, size: 27),
          onPressed: ()=>this.showSheetInfo(collectionBook)
        )
      ]
    );
  }

  Widget booksItemWidget(CollectionBook collectionBook){
    bool isAvailable = collectionBook.available > 0;
    return ReorderableItem( key: collectionBook.key, childBuilder: (BuildContext context, ReorderableItemState state){
      BoxDecoration decoration;
      Widget dragHandle = this.isSorting
        ? ReorderableListener(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 7.0, horizontal: 7.0),
            decoration: new BoxDecoration(
              color: Color(0x08000000)
            ),
            child: Icon(Icons.reorder, color: Colors.red, size: 25.0)
          )
        ):Container();
      return Container(
        decoration: decoration,
        child: Opacity(
          // hide content for placeholder
          opacity: state == ReorderableItemState.placeholder ? 0.0 : 1.0,
          child: IntrinsicHeight(
            child: new ListTile(
              dense: true,
              title: Text(
                collectionBook.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headline.copyWith(fontSize: 22,color: isAvailable?Colors.black:Colors.grey)
              ),
              subtitle: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAvailable?Colors.grey[500]:Colors.grey[200]
                    ),
                    child: Text(
                      collectionBook.language.name.toUpperCase(),
                      style: Theme.of(context).textTheme.subhead.copyWith(
                        color:isAvailable?Colors.white:Colors.black,
                        fontSize: 10
                      )
                    )
                  ),
                  Text(' '),
                  Text(collectionBook.shortname,style: Theme.of(context).textTheme.subhead.copyWith(color:Colors.black,fontSize: 15))
                ]
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(collectionBook.year.toString(),style: Theme.of(context).textTheme.caption.copyWith(fontSize: 15,color: Colors.black)),
                  Icon(Icons.arrow_forward_ios, color: isAvailable?Colors.black:Colors.grey[200], size: 25),
                  dragHandle
                ]
              ),
              onTap:()=>isAvailable?this.toBible(collectionBook):this.showSheetInfo(collectionBook)
            )
          )
        )
      );
    });
  }
}