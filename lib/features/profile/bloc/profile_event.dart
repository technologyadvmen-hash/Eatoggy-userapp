import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchProfileEvent extends ProfileEvent {
  const FetchProfileEvent();
}

class RefreshProfileEvent extends ProfileEvent {
  const RefreshProfileEvent();
}

class UpdateCustomerProfileEvent extends ProfileEvent {
  final String? name;
  final String? email;
  final String? dietaryPreference;
  final String? avatar;

  const UpdateCustomerProfileEvent({
    this.name,
    this.email,
    this.dietaryPreference,
    this.avatar,
  });

  @override
  List<Object?> get props => [name, email, dietaryPreference, avatar];
}
