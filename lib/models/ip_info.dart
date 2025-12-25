class IpInfo {
  final String ip;
  final String continent;
  final String province;
  final String city;
  final String country;
  final String latitude;
  final String longitude;
  final String areaCode;
  final String isp;
  final String countryCode;

  IpInfo({
    required this.ip,
    required this.continent,
    required this.province,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.areaCode,
    required this.isp,
    required this.countryCode,
  });

  factory IpInfo.fromJson(Map<String, dynamic> json) {
    return IpInfo(
      ip: json['ip'],
      continent: json['continent'],
      province: json['province'],
      city: json['city'],
      country: json['country'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      areaCode: json['area_code'],
      isp: json['isp'],
      countryCode: json['country_code'],
    );
  }
}
