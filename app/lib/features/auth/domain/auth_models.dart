class AuthUser {
  const AuthUser({
    required this.id,
    required this.nickname,
    this.email,
    this.phone,
    this.avatarUrl,
    this.gender = UserGender.unspecified,
  });

  final String id;
  final String nickname;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final UserGender gender;

  AuthUser copyWith({
    String? nickname,
    String? email,
    String? phone,
    String? avatarUrl,
    UserGender? gender,
  }) {
    return AuthUser(
      id: id,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
    );
  }
}

enum UserGender {
  male,
  female,
  unspecified,
}

UserGender userGenderFromApi(String? value) {
  return switch (value) {
    'MALE' => UserGender.male,
    'FEMALE' => UserGender.female,
    _ => UserGender.unspecified,
  };
}

String userGenderToApi(UserGender gender) {
  return switch (gender) {
    UserGender.male => 'MALE',
    UserGender.female => 'FEMALE',
    UserGender.unspecified => 'UNSPECIFIED',
  };
}

String userGenderLabel(UserGender gender) {
  return switch (gender) {
    UserGender.male => '男',
    UserGender.female => '女',
    UserGender.unspecified => '未设置',
  };
}

String thirdPersonPronoun(UserGender gender) {
  return switch (gender) {
    UserGender.male => '他',
    UserGender.female => '她',
    UserGender.unspecified => 'TA',
  };
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final AuthUser user;
}
