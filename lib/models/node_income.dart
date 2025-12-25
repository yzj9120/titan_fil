class NodeIncomeData {
  final String nodeId;
  final List<NodeIncomeDetail> list;

  NodeIncomeData({
    required this.nodeId,
    required this.list,
  });

  factory NodeIncomeData.fromJson(Map<String, dynamic> json) {
    return NodeIncomeData(
      nodeId: json["node_id"] ?? "",
      list: (json["list"] as List<dynamic>?)
              ?.map((e) => NodeIncomeDetail.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "node_id": nodeId,
      "list": list.map((e) => e.toJson()).toList(),
    };
  }
}

class NodeIncomeDetail {
  final double income;
  final double incomeU;
  final int createdAt;
  final int nodes;
  final double averageIncome;
  bool bSelected = false;

  NodeIncomeDetail({
    required this.income,
    required this.incomeU,
    required this.createdAt,
    required this.nodes,
    required this.averageIncome,
    this.bSelected = false,
  });

  factory NodeIncomeDetail.fromJson(Map<String, dynamic> json) {
    return NodeIncomeDetail(
      income: (json["income"] ?? 0).toDouble(),
      incomeU: (json["income_u"] ?? 0).toDouble(),
      createdAt: json["created_at"] ?? 0,
      nodes: json["nodes"] ?? 0,
      averageIncome: (json["average_income"] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "income": income,
      "created_at": createdAt,
      "nodes": nodes,
      "average_income": averageIncome,
    };
  }
}
