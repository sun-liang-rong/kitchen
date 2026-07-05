import '../../auth/domain/auth_models.dart';

enum CoupleBindingStatus {
  unknown,
  unbound,
  pending,
  waitingForMe,
  bound,
}

class CoupleInvite {
  const CoupleInvite({
    required this.id,
    required this.code,
    required this.expiresAt,
    this.inviter,
    this.inviteeId,
  });

  final String id;
  final String code;
  final DateTime expiresAt;
  final AuthUser? inviter;
  final String? inviteeId;
}

class CoupleBinding {
  const CoupleBinding({
    required this.status,
    this.invite,
    this.activeInvite,
    this.partner,
    this.coupleId,
  });

  final CoupleBindingStatus status;
  final CoupleInvite? invite;
  final CoupleInvite? activeInvite;
  final AuthUser? partner;
  final String? coupleId;

  String? get inviteCode => invite?.code ?? activeInvite?.code;
}
