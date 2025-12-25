


class UserData {
  final String address;
  final String account;
  final String addressEth;

  UserData({
    required this.address,
    required this.account,
    required this.addressEth,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      account: json['account'],
      address: json['address'],
      addressEth: json['address_eth'],
    );
  }

  @override
  String toString() {
    return 'UserData{address: $address, account: $account},address_eth:${addressEth}';
  }
}