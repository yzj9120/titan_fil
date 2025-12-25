class NoticeBean {
  final List<NoticeItemBean> list;

  NoticeBean({
    required this.list,
  });

  factory NoticeBean.fromJson(Map<String, dynamic> json) {
    return NoticeBean(
      list: (json["list"] as List<dynamic>?)
              ?.map((e) => NoticeItemBean.fromMap(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "list": list.map((e) => e.toJson()).toList(),
    };
  }
}

class NoticeItemBean {
  final int id;
  final String name;
  final int adsType;
  final String redirectUrl;
  final int platform;
  final String lang;
  final String desc;
  final bool isText;
  final int weight;
  final int state;
  final int hits;
  final DateTime invalidFrom;
  final DateTime invalidTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 构造函数
  NoticeItemBean({
    required this.id,
    required this.name,
    required this.adsType,
    required this.redirectUrl,
    required this.platform,
    required this.lang,
    required this.desc,
    required this.isText,
    required this.weight,
    required this.state,
    required this.hits,
    required this.invalidFrom,
    required this.invalidTo,
    required this.createdAt,
    required this.updatedAt,
  });

  // 从 Map 转换为 Ad 实体
  factory NoticeItemBean.fromMap(Map<String, dynamic> map) {
    return NoticeItemBean(
      id: map['id'],
      name: map['name'],
      adsType: map['ads_type'],
      redirectUrl: map['redirect_url'] ?? '',
      platform: map['platform'],
      lang: map['lang'],
      desc: map['desc'],
      isText: map['is_text'],
      weight: map['weight'],
      state: map['state'],
      hits: map['hits'],
      invalidFrom: DateTime.parse(map['invalid_from']),
      invalidTo: DateTime.parse(map['invalid_to']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // 将 NoticeItemBean 转换为 Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ads_type': adsType,
      'redirect_url': redirectUrl,
      'platform': platform,
      'lang': lang,
      'desc': desc,
      'is_text': isText,
      'weight': weight,
      'state': state,
      'hits': hits,
      'invalid_from': invalidFrom.toIso8601String(),
      'invalid_to': invalidTo.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
