import 'package:PiliPlus/common/widgets/pair.dart';
import 'package:PiliPlus/http/live.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/live/live_feed_index/card_data_list_item.dart';
import 'package:PiliPlus/models_new/live/live_feed_index/card_list.dart';
import 'package:PiliPlus/models_new/live/live_feed_index/data.dart';
import 'package:PiliPlus/models_new/live/live_second_list/data.dart';
import 'package:PiliPlus/models_new/live/live_second_list/tag.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/services/account_service.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:flutter/widgets.dart' show ScrollController;
import 'package:get/get.dart';

class LiveController extends CommonListController with AccountMixin {
  @override
  void onInit() {
    super.onInit();
    areaIndex.value = 0;
    queryData();
  }

  int? count;

  // area
  int? areaId;
  String? sortType;
  int? parentAreaId;
  final RxInt areaIndex = 0.obs;

  static const int _lolAreaId = 86;
  List<dynamic> allCategories = [];
  bool _lolAutoSelected = false;

  // tag
  final RxInt tagIndex = 0.obs;
  List<LiveSecondTag>? newTags;

  final Rx<Pair<LiveCardList?, LiveCardList?>> topState =
      Pair<LiveCardList?, LiveCardList?>(first: null, second: null).obs;

  final followController = ScrollController();

  bool showFirstFrame = false;

  @override
  void checkIsEnd(int length) {
    if (count != null && length >= count!) {
      isEnd = true;
    }
  }

  @override
  List? getDataList(response) {
    return response.cardList;
  }

  @override
  bool customHandleResponse(bool isRefresh, Success response) {
    if (isRefresh) {
      final res = response.response;
      if (res is LiveIndexData) {
        if (res.hasMore == 0) {
          isEnd = true;
        }
        topState.value = Pair(
          first: res.followItem,
          second: res.areaItem,
        );
        final catList = res.areaItem?.cardData?.areaEntranceV3?.list;
        if (catList != null && catList.isNotEmpty) {
          allCategories = catList;
        }
        if (!_lolAutoSelected) {
          _lolAutoSelected = true;
          areaId = _lolAreaId;
          parentAreaId = 2;
          final lolIndex = catList?.indexWhere((e) => e.areaV2Id == _lolAreaId) ?? -1;
          if (lolIndex >= 0) {
            areaIndex.value = lolIndex + 1;
          }
          Future.microtask(() {
            count = null;
            page = 1;
            isEnd = false;
            queryData();
          });
        }
      } else if (res is LiveSecondData) {
        count = res.count;
        newTags = res.newTags;
        if (sortType != null) {
          tagIndex.value =
              newTags?.indexWhere((e) => e.sortType == sortType) ?? -1;
        }
      }
    }
    return false;
  }

  @override
  Future<LoadingState> customGetData() {
    if (areaIndex.value != 0) {
      return LiveHttp.liveSecondList(
        pn: page,
        areaId: areaId,
        parentAreaId: parentAreaId,
        sortType: sortType,
      );
    }
    return LiveHttp.liveFeedIndex(pn: page);
  }

  @override
  Future<void> onRefresh() {
    count = null;
    page = 1;
    isEnd = false;
    if (areaIndex.value != 0) {
      queryTop().whenComplete(followController.jumpToTop);
      return queryData();
    }
    return queryData().whenComplete(followController.jumpToTop);
  }

  Future<void> queryTop() async {
    final res = await LiveHttp.liveFeedIndex(pn: page, moduleSelect: true);
    if (res case Success(:final response)) {
      topState.value = Pair(
        first: response.followItem,
        second: response.areaItem,
      );
      areaIndex.value =
          (response.areaItem?.cardData?.areaEntranceV3?.list?.indexWhere(
                (e) => e.areaV2Id == areaId && e.areaV2ParentId == parentAreaId,
              ) ??
              -2) +
          1;
    }
  }

  void onSelectArea(int index, CardLiveItem? cardLiveItem) {
    if (isLoading) {
      return; // areaIndex conflict
    }
    if (index == areaIndex.value) {
      return;
    }
    tagIndex.value = 0;
    newTags = null;
    sortType = null;
    areaIndex.value = index;
    areaId = cardLiveItem?.areaV2Id;
    parentAreaId = cardLiveItem?.areaV2ParentId;

    count = null;
    page = 1;
    isEnd = false;
    queryData();
  }

  void onSelectTag(int index, String? sortType) {
    if (isLoading) {
      return;
    }
    tagIndex.value = index;
    this.sortType = sortType;

    count = null;
    page = 1;
    isEnd = false;
    queryData();
  }

  @override
  void onChangeAccount(bool isLogin) => onReload();

  @override
  void onClose() {
    followController.dispose();
    super.onClose();
  }

  void showOtherSheet(BuildContext context) {
    final others = allCategories.where((e) {
      try {
        final id = e.areaV2Id?.toString() ?? '';
        return id != _lolAreaId.toString() && id.isNotEmpty;
      } catch (_) {
        return true;
      }
    }).toList();
    final showList = others.isNotEmpty ? others : allCategories;
    if (showList.isEmpty) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择分区', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: showList.length,
                itemBuilder: (c, idx) {
                  final it = showList[idx];
                  return ListTile(
                    title: Text(it.title ?? ''),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      final originalIndex = allCategories.indexOf(it);
                      if (originalIndex >= 0) {
                        onSelectArea(originalIndex + 1, it);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void selectLol() {
    final lolIndex = allCategories.indexWhere((e) {
      try {
        return e.areaV2Id == _lolAreaId;
      } catch (_) {
        return false;
      }
    });
    if (lolIndex >= 0) {
      onSelectArea(lolIndex + 1, allCategories[lolIndex]);
    } else if (areaId != _lolAreaId) {
      areaId = _lolAreaId;
      parentAreaId = 2;
      count = null;
      page = 1;
      isEnd = false;
      queryData();
    }
  }
}
