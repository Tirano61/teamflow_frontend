class DeviceRegistrationRequestModel {
  const DeviceRegistrationRequestModel({
    required this.token,
    required this.platform,
  });

  final String token;
  final String platform;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'token': token, 'platform': platform};
  }
}
