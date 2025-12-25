import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../models/log_entry.dart';

class LogsState {
  var selectedIndex = (-0).obs;
  var selectedName = "".obs;
  var selectedTime = DateFormat('yyyy-MM-dd').format(DateTime.now()).obs;
  var currentTime = DateFormat('yyyy-MM-dd').format(DateTime.now());

  final RxList<String> dateList = <String>[].obs;
  final RxList<LogEntry> logs = <LogEntry>[].obs;
  final RxList<DateTime?> selectedDates = <DateTime>[].obs;
  final RxBool isLoading = true.obs;

}
