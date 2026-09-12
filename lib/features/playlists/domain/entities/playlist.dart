import 'package:equatable/equatable.dart';

/// A user-created, device-local ordered list of Pirith.
///
/// Only Pirith **ids** are stored: the catalogue is the source of truth for
/// titles, covers and audio URLs, so a Pirith edited in the admin app shows
/// its new details everywhere without a migration. Ids that no longer exist
/// in the catalogue are skipped when the list is resolved for display.
///
/// [coverImagePath] is reserved for a future user-picked cover. Nothing
/// writes it today — covers are auto-collaged from the member Pirith — but
/// keeping the field means adding a picker later is additive rather than a
/// stored-format change.
class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.name,
    required this.pirithIds,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.coverImagePath,
  });

  final String id;
  final String name;
  final String description;
  final String? coverImagePath;
  final List<String> pirithIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get itemCount => pirithIds.length;
  bool get isEmpty => pirithIds.isEmpty;

  Playlist copyWith({
    String? name,
    String? description,
    String? coverImagePath,
    List<String>? pirithIds,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      pirithIds: pirithIds ?? this.pirithIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'coverImagePath': coverImagePath,
    'pirithIds': pirithIds,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  /// Returns `null` for anything that isn't a usable playlist, so one
  /// corrupt entry drops out instead of taking the whole store with it.
  static Playlist? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String) return null;

    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    if (createdAt is! int || updatedAt is! int) return null;

    return Playlist(
      id: id,
      name: name,
      description: json['description'] is String ? json['description'] : '',
      coverImagePath: json['coverImagePath'] is String
          ? json['coverImagePath'] as String
          : null,
      pirithIds: (json['pirithIds'] as List?)?.whereType<String>().toList() ?? const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    coverImagePath,
    pirithIds,
    createdAt,
    updatedAt,
  ];
}
