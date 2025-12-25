const String rspKeyIncome = "income";
const String rspKeyMonthIncomes = "month_incomes";
const String rspKeyAccount = "account";
const String rspKeyEpoch = "epoch";
const String rspKeyNodeInfo = "info";

const int nodeOnlineStatus = 1;

class IncomeData {
  IncomeData({required this.x, required this.y});
  String x;
  double y;
  bool bSelected = false;

  @override
  String toString() {
    return 'IncomeData{x: $x, y: $y, bSelected: $bSelected}';
  }
}

class RspIncome {
  RspIncome({required this.today, required this.total});

  double today; // index
  double total; // value

  factory RspIncome.fromMap(Map<String, dynamic> map) {
    dynamic today = map['today'] ?? 0;
    double todayDouble = today is int ? today.toDouble() : today as double;

    dynamic total = map['total'] ?? 0;
    double totalDouble = total is int ? total.toDouble() : total as double;
    return RspIncome(
      today: todayDouble,
      total: totalDouble,
    );
  }

  @override
  String toString() {
    return 'RspIncome{today: $today, total: $total}';
  }
}

class RspEpoch {
  RspEpoch({required this.token});

  String token;

  factory RspEpoch.fromMap(Map<String, dynamic> map) {
    return RspEpoch(
      token: map['token'] as String,
    );
  }

  @override
  String toString() {
    return 'RspEpoch{token: $token}';
  }
}

class RspNodeInfo {
  RspNodeInfo({required this.incr});

  double incr;

  factory RspNodeInfo.fromMap(Map<String, dynamic> map) {
    dynamic incomeIncr = map['income_incr'] ?? 0;
    double incrDouble =
        incomeIncr is int ? incomeIncr.toDouble() : incomeIncr as double;

    return RspNodeInfo(
      incr: incrDouble,
    );
  }

  @override
  String toString() {
    return 'RspNodeInfo{incr: $incr}';
  }
}

class RspAccount {
  RspAccount(
      {required this.account, required this.address, required this.code});

  String account;
  String address;
  String code;

  factory RspAccount.fromMap(Map<String, dynamic> map) {
    return RspAccount(
      account: map['user_id'] as String,
      address: map['wallet_address'] as String,
      code: map['code'] as String,
    );
  }

  @override
  String toString() {
    return 'RspAccount{account: $account, address: $address, code: $code}';
  }
}

class RspIncomes {
  RspIncomes({required this.incomeList});

  List<IncomeData> incomeList; // index

  factory RspIncomes.fromMap(List<dynamic> list) {
    List<IncomeData> incomes = [];

    for (final dynamic info in list) {
      dynamic income = info['v'] ?? 0;
      double incrDouble = income is int ? income.toDouble() : income as double;

      var incomeD = IncomeData(x: info['k'], y: incrDouble);
      incomes.add(incomeD);
    }

    return RspIncomes(
      incomeList: incomes,
    );
  }

  @override
  String toString() {
    return 'RspIncomes{incomeList: $incomeList}';
  }
}

class RspData {
  RspData({
    this.income,
    this.monthIncomes,
    required this.since,
    this.accountInfo,
    this.epochInfo,
    this.nodeInfo,
  });

  RspIncome? income;
  RspIncomes? monthIncomes;
  int since;
  RspAccount? accountInfo;
  RspEpoch? epochInfo;
  RspNodeInfo? nodeInfo;

  factory RspData.fromMap(Map<String, dynamic> map) {
    return RspData(
      income: map[rspKeyIncome] != null
          ? RspIncome.fromMap(map[rspKeyIncome] as Map<String, dynamic>)
          : null,
      monthIncomes: map[rspKeyMonthIncomes] != null
          ? RspIncomes.fromMap(map[rspKeyMonthIncomes] as List<dynamic>)
          : null,
      epochInfo: map[rspKeyEpoch] != null
          ? RspEpoch.fromMap(map[rspKeyEpoch] as Map<String, dynamic>)
          : null,
      nodeInfo: map[rspKeyNodeInfo] != null
          ? RspNodeInfo.fromMap(map[rspKeyNodeInfo] as Map<String, dynamic>)
          : null,
      since: map['since'] != null ? map['since'] as int : 0,
      accountInfo: map[rspKeyAccount] != null
          ? RspAccount.fromMap(map[rspKeyAccount] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'RspData{income: $income, monthIncomes: $monthIncomes, since: $since, accountInfo: $accountInfo, epochInfo: $epochInfo, nodeInfo: $nodeInfo}';
  }
}

class NodeInfoRsp {
  NodeInfoRsp({required this.code, required this.data});

  int code;
  RspData? data; // value

  factory NodeInfoRsp.fromMap(Map<dynamic, dynamic> map) {
    return NodeInfoRsp(
      code: map['code'] as int,
      data: map['data'] != null
          ? RspData.fromMap(map['data'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'NodeInfoRsp{code: $code, data: $data}';
  }
}
