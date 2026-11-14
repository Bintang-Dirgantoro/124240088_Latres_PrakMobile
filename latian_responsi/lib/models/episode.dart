class Episode {
  final int id;
  final String name;
  final String airDate;
  final String episode;

  Episode({
    required this.id,
    required this.name,
    required this.airDate,
    required this.episode,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? 'Unknown Episode',
      airDate: json['air_date'] ?? 'Unknown Date',
      episode: json['episode'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'air_date': airDate,
      'episode': episode,
    };
  }
}
