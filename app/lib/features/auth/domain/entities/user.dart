import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.displayName,
    required this.email,
    this.createdAt,
  });

  final String id;
  final String displayName;
  final String email;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, displayName, email, createdAt];
}
