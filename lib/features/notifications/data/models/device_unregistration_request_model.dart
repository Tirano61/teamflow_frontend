class DeviceUnregistrationRequestModel {
  const DeviceUnregistrationRequestModel({required this.token});

  final String token;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'token': token};
  }
}
