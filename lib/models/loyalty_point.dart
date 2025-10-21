class LoyaltyPoint {
  LoyaltyPoint({
    required this.points,
    required this.updatedAt,
  });

  double points;
  DateTime updatedAt;

  factory LoyaltyPoint.fromJson(Map<String, dynamic> json) => LoyaltyPoint(
        points: json["points"] == null
            ? 0
            : double.tryParse(json["points"].toString()) ?? 0.0,
        updatedAt: json["updated_at"] == null
            ? DateTime.now()
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "points": points,
        "updated_at": updatedAt.toIso8601String(),
      };
}
