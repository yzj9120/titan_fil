import 'dart:async';

/// 任务调度服务
class SchedulerService {
  final Map<String, Timer> _timers = {}; // 存储任务的 Map

  /// 启动一个定时任务（只执行一次）
  void scheduleTask(String taskId, Duration duration, void Function() task) {
    cancelTask(taskId); // 避免重复
    _timers[taskId] = Timer(duration, () {
      task();
      _timers.remove(taskId); // 执行后移除任务
    });
  }

  /// 启动一个周期性任务
  void schedulePeriodicTask(
      String taskId, Duration interval, void Function() task) {
    cancelTask(taskId); // 避免重复
    _timers[taskId] = Timer.periodic(interval, (timer) {
      if (!_timers.containsKey(taskId)) {
        timer.cancel(); // 如果任务已被取消，则停止
      } else {
        task();
      }
    });
  }

  /// 取消指定任务
  void cancelTask(String taskId) {
    _timers[taskId]?.cancel();
    _timers.remove(taskId);
  }
  /// 重启周期性任务
  void restartPeriodicTask(
      String taskId,
      Duration interval,
      void Function() task
      ) {
    cancelTask(taskId); // 先取消
    schedulePeriodicTask(taskId, interval, task); // 再启动
  }
  /// 取消所有任务
  void cancelAllTasks() {
    _timers.forEach((_, timer) => timer.cancel());
    _timers.clear();
  }

  /// 检查任务是否正在运行
  bool isTaskRunning(String taskId) {
    return _timers[taskId]?.isActive ?? false;
  }
}
//
// void main() {
//   final scheduler = SchedulerService();
//
//   // 5 秒后执行一次任务
//   scheduler.scheduleTask('oneTimeTask', Duration(seconds: 5), () {
//     print('执行一次性任务');
//   });
//
//   // 每 3 秒执行一次任务
//   scheduler.schedulePeriodicTask('periodicTask', Duration(seconds: 3), () {
//     print('执行周期任务');
//   });
//
//   // 6 秒后检查任务是否还在运行
//   Future.delayed(Duration(seconds: 6), () {
//     print('任务是否还在运行: ${scheduler.isTaskRunning('periodicTask')}'); // true
//   });
//
//   // 10 秒后取消所有任务
//   Future.delayed(Duration(seconds: 10), () {
//     scheduler.cancelAllTasks();
//     print('所有任务已取消');
//   });
// }
