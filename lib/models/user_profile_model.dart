import 'user_model.dart';
import 'pembeli_model.dart';
import 'penitip_model.dart';

class UserProfileModel {
  final UserModel user;
  final PembeliModel? pembeli;
  final PenitipModel? penitip;

  UserProfileModel({required this.user, this.pembeli, this.penitip});

  String get name {
    if (user.role == 'Pembeli' && pembeli != null) {
      return pembeli!.namaPembeli;
    } else if (user.role == 'Penitip' && penitip != null) {
      return penitip!.namaPenitip;
    }
    return 'User';
  }

  String get phone {
    if (user.role == 'Pembeli' && pembeli != null) {
      return pembeli!.noHpDefault;
    } else if (user.role == 'Penitip' && penitip != null) {
      return penitip!.noTelepon;
    }
    return '';
  }

  String? get address {
    if (user.role == 'Penitip' && penitip != null) {
      return penitip!.alamat;
    }
    return null;
  }

  int get poin {
    if (user.role == 'Pembeli' && pembeli != null) {
      return pembeli!.jumlahPoin;
    } else if (user.role == 'Penitip' &&
        penitip != null &&
        penitip!.jumlahPoin != null) {
      return penitip!.jumlahPoin!;
    }
    return 0;
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final user = UserModel.fromJson(json);

    // Parse pembeli data if available
    PembeliModel? pembeli;
    if (json['pembeli'] != null && user.role == 'Pembeli') {
      pembeli = PembeliModel.fromJson(json['pembeli']);
    }

    // Parse penitip data if available
    PenitipModel? penitip;
    if (json['penitip'] != null && user.role == 'Penitip') {
      penitip = PenitipModel.fromJson(json['penitip']);
    }

    return UserProfileModel(user: user, pembeli: pembeli, penitip: penitip);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'user': user.toJson()};

    if (pembeli != null) {
      data['pembeli'] = pembeli!.toJson();
    }

    if (penitip != null) {
      data['penitip'] = penitip!.toJson();
    }

    return data;
  }
}
