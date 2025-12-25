import 'Steps.dart';

class StepsWarp {
  final int stepCurrent;
  final List<Steps> list;
  final bool status;

  StepsWarp({
    required this.stepCurrent,
    required this.list,
    required this.status,
  });

  @override
  String toString() {
    return 'StepsWarp{stepCurrent: $stepCurrent, list: $list, status: $status}';
  }
}
