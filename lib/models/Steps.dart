class Steps {
  bool isActive = false;
  bool status = false;
  String subtitle = '';
  String? des;
  String? txt;
  Function? onTap;
  Function? onRetry;
  String title;

  @override
  String toString() {
    return 'Steps{isActive: $isActive, status: $status, subtitle: $subtitle, des: $des, txt: $txt, onTap: $onTap, title: $title}';
  }

  Steps({required this.title});
}
