import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../../couple/data/couple_repository.dart';
import '../../../couple/domain/couple_models.dart';
import '../../../profile/data/user_repository.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_models.dart';

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, SessionState>(
        SessionController.new);

class SessionState {
  const SessionState({
    this.token,
    this.user,
    this.binding = const CoupleBinding(status: CoupleBindingStatus.unknown),
  });

  final String? token;
  final AuthUser? user;
  final CoupleBinding binding;

  bool get isLoggedIn => token != null && user != null;
  bool get isBound => binding.status == CoupleBindingStatus.bound;

  SessionState copyWith({
    String? token,
    AuthUser? user,
    CoupleBinding? binding,
    bool clearToken = false,
    bool clearUser = false,
  }) {
    return SessionState(
      token: clearToken ? null : token ?? this.token,
      user: clearUser ? null : user ?? this.user,
      binding: binding ?? this.binding,
    );
  }
}

class SessionController extends AsyncNotifier<SessionState> {
  static const _tokenKey = 'auth_token';

  late final SecureStorage _storage;
  late final AuthRepository _authRepository;
  late final CoupleRepository _coupleRepository;
  UserRepository? _userRepository;

  @override
  Future<SessionState> build() async {
    _storage = const SecureStorage(FlutterSecureStorage());
    _authRepository = AuthRepository();
    _coupleRepository = CoupleRepository();

    final token = await _storage.read(_tokenKey);
    if (token == null || token.isEmpty) {
      return const SessionState(
          binding: CoupleBinding(status: CoupleBindingStatus.unbound));
    }

    try {
      final user = await _authRepository.me(token);
      final binding = await _coupleRepository.status(token);
      return SessionState(token: token, user: user, binding: binding);
    } catch (_) {
      await _storage.delete(_tokenKey);
      return const SessionState(
          binding: CoupleBinding(status: CoupleBindingStatus.unbound));
    }
  }

  Future<void> login(String account, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session =
          await _authRepository.login(account: account, password: password);
      await _storage.write(_tokenKey, session.token);
      final binding = await _safeBinding(session.token);
      return SessionState(
          token: session.token, user: session.user, binding: binding);
    });
  }

  Future<void> register(
    String account,
    String password,
    String nickname, {
    UserGender gender = UserGender.unspecified,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await _authRepository.register(
        account: account,
        password: password,
        nickname: nickname,
        gender: gender,
      );
      await _storage.write(_tokenKey, session.token);
      final binding = await _safeBinding(session.token);
      return SessionState(
          token: session.token, user: session.user, binding: binding);
    });
  }

  Future<void> refreshBinding() async {
    final current = state.valueOrNull;
    final token = current?.token;
    if (current == null || token == null) {
      return;
    }
    final binding = await _safeBinding(token);
    state = AsyncData(current.copyWith(binding: binding));
  }

  Future<CoupleInvite> generateCode() async {
    final token = _requireToken();
    final invite = await _coupleRepository.generateCode(token);
    await refreshBinding();
    return invite;
  }

  Future<void> applyByCode(String code) async {
    final token = _requireToken();
    await _coupleRepository.applyByCode(token, code);
    await refreshBinding();
  }

  Future<void> accept(String inviteId) async {
    final token = _requireToken();
    final binding = await _coupleRepository.accept(token, inviteId);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(binding: binding));
    }
  }

  Future<void> reject(String inviteId) async {
    final token = _requireToken();
    await _coupleRepository.reject(token, inviteId);
    await refreshBinding();
  }

  Future<void> cancel(String inviteId) async {
    final token = _requireToken();
    await _coupleRepository.cancel(token, inviteId);
    await refreshBinding();
  }

  Future<void> unbind() async {
    final token = _requireToken();
    await _coupleRepository.unbind(token);
    await refreshBinding();
  }

  Future<void> updateProfile({
    required String nickname,
    String? avatarUrl,
    UserGender? gender,
  }) async {
    final current = state.valueOrNull;
    final token = current?.token;
    if (current == null || token == null) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = _userRepository ??= UserRepository(token: token);
      final user = await repository.updateMe(
        nickname: nickname,
        avatarUrl: avatarUrl,
        gender: gender,
      );
      return current.copyWith(user: user);
    });
  }

  Future<void> logout() async {
    await _storage.delete(_tokenKey);
    state = const AsyncData(SessionState(
        binding: CoupleBinding(status: CoupleBindingStatus.unbound)));
  }

  Future<CoupleBinding> _safeBinding(String token) async {
    try {
      return await _coupleRepository.status(token);
    } on DioException {
      return const CoupleBinding(status: CoupleBindingStatus.unbound);
    }
  }

  String _requireToken() {
    final token = state.valueOrNull?.token;
    if (token == null) {
      throw StateError('未登录');
    }
    return token;
  }
}
