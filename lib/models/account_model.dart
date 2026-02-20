import 'package:hive/hive.dart';

part 'account_model.g.dart';

@HiveType(typeId: 0)
class AccountModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String issuer;

  @HiveField(3)
  String secret;

  @HiveField(4)
  int digits;

  @HiveField(5)
  int period;

  @HiveField(6)
  String algorithm;

  @HiveField(7)
  DateTime createdAt;

  /// Token type: 'totp' | 'hotp' | 'steam'
  @HiveField(8)
  String type;

  /// Counter for HOTP (increments on each use)
  @HiveField(9)
  int counter;

  AccountModel({
    required this.id,
    required this.name,
    required this.issuer,
    required this.secret,
    this.digits = 6,
    this.period = 30,
    this.algorithm = 'SHA1',
    required this.createdAt,
    this.type = 'totp',
    this.counter = 0,
  });

  bool get isTotp => type == 'totp';
  bool get isHotp => type == 'hotp';
  bool get isSteam => type == 'steam';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'issuer': issuer,
        'secret': secret,
        'digits': digits,
        'period': period,
        'algorithm': algorithm,
        'createdAt': createdAt.toIso8601String(),
        'type': type,
        'counter': counter,
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        name: json['name'] as String,
        issuer: json['issuer'] as String,
        secret: json['secret'] as String,
        digits: json['digits'] as int? ?? 6,
        period: json['period'] as int? ?? 30,
        algorithm: json['algorithm'] as String? ?? 'SHA1',
        createdAt: DateTime.parse(json['createdAt'] as String),
        type: json['type'] as String? ?? 'totp',
        counter: json['counter'] as int? ?? 0,
      );

  String get otpAuthUri {
    final encodedIssuer = Uri.encodeComponent(issuer);
    final encodedName = Uri.encodeComponent(name);
    if (type == 'hotp') {
      return 'otpauth://hotp/$encodedIssuer:$encodedName'
          '?secret=$secret&issuer=$encodedIssuer'
          '&digits=$digits&counter=$counter&algorithm=$algorithm';
    }
    return 'otpauth://totp/$encodedIssuer:$encodedName'
        '?secret=$secret&issuer=$encodedIssuer'
        '&digits=$digits&period=$period&algorithm=$algorithm';
  }

  String get initials {
    if (issuer.isNotEmpty) return issuer[0].toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }
}
