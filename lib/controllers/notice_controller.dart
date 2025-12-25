import 'package:get/get.dart';

import '../models/notice_bean.dart';
import '../network/api_service.dart';
import '../services/global_service.dart';

class NoticeController extends GetxController {
  final GlobalService globalService;

  NoticeController({
    required this.globalService,
  });


  RxList<NoticeItemBean> notices = <NoticeItemBean>[].obs;
  // 记录上次调用 getNotice 的时间
  DateTime? _lastFetchedTime;
  void upDataNotices(list) {
    notices.value = list;
  }

  /// 获取通知信息：
  Future<void> getNotice() async {
    DateTime now = DateTime.now();
    // 如果已经执行过，且距离上次调用小于 5分钟，则跳过
    if (_lastFetchedTime != null &&
        now.difference(_lastFetchedTime!).inMinutes < 5) {
      return;
    }
    _lastFetchedTime = now; // 更新上次调用时间
    NoticeBean? bean = await ApiService.notice();

    if (bean != null) {
      final List<NoticeItemBean> list = bean.list;
      upDataNotices(list);
    }
  }
}
