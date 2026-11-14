class UpdateProfileRequest {
  final String? name;
  final String? email;
  final String? dietaryPreference;
  final String? avatar;

  const UpdateProfileRequest({
    this.name,
    this.email,
    this.dietaryPreference,
    this.avatar,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null && name!.isNotEmpty) data['name'] = name;
    if (email != null && email!.isNotEmpty) data['email'] = email;
    if (dietaryPreference != null && dietaryPreference!.isNotEmpty) {
      data['dietaryPreference'] = dietaryPreference;
    }
    if (avatar != null && avatar!.isNotEmpty) data['avatar'] = avatar;
    return data;
  }
}
