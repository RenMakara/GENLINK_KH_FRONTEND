import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/settings/data/models/user_settings_model.dart';
import 'package:genlink_frontend/features/settings/domain/entities/user_settings_entity.dart';

void main() {
  test('missing wire language uses the entity English fallback', () {
    final settings = UserSettingsMapper.fromJson(const <String, dynamic>{});

    expect(settings.language, UserSettingsEntity.languageEnglish);
    expect(settings.language, const UserSettingsEntity().language);
  });

  test('explicit wire language is preserved', () {
    final settings = UserSettingsMapper.fromJson(const <String, dynamic>{
      'language': UserSettingsEntity.languageKhmer,
    });

    expect(settings.language, UserSettingsEntity.languageKhmer);
  });
}
