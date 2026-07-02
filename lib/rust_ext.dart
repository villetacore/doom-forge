// Convenience helpers over the FRB-generated (immutable) model classes.
import 'src/rust/domain/models.dart';

const Object _keep = Object();

extension ProfileX on Profile {
  Profile copyWith({
    String? name,
    String? description,
    Object? enginePath = _keep,
    Object? iwad = _keep,
    List<LoadEntry>? loadOrder,
    List<String>? extraArgs,
    String? updatedAt,
  }) =>
      Profile(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        enginePath: enginePath == _keep ? this.enginePath : enginePath as String?,
        iwad: iwad == _keep ? this.iwad : iwad as String?,
        loadOrder: loadOrder ?? this.loadOrder,
        extraArgs: extraArgs ?? this.extraArgs,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastPlayedAt: lastPlayedAt,
      );

  int get enabledCount => loadOrder.where((e) => e.enabled).length;
}

extension LoadEntryX on LoadEntry {
  LoadEntry copyWith({bool? enabled, ModGroup? group}) => LoadEntry(
        path: path,
        name: name,
        group: group ?? this.group,
        enabled: enabled ?? this.enabled,
      );
}

/// CSS-group → accent colour mapping (mirrors the web `.g-*` classes).
extension ModGroupX on ModGroup {
  String get label {
    switch (this) {
      case ModGroup.maps:
        return 'MAPS';
      case ModGroup.gameplay:
        return 'GAMEPLAY';
      case ModGroup.audio:
        return 'AUDIO';
      case ModGroup.visuals:
        return 'VISUALS';
      case ModGroup.patch:
        return 'PATCH';
      case ModGroup.other:
        return 'OTHER';
    }
  }
}
