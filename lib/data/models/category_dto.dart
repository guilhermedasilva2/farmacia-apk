class CategoryDto {
  final String id;
  final String name;
  final String? slug;

  const CategoryDto({required this.id, required this.name, this.slug});

  factory CategoryDto.fromMap(Map<String, dynamic> map) => CategoryDto(
        id: (map['id'] ?? '').toString(),
        name: (map['name'] ?? '').toString(),
        slug: map['slug'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'slug': slug,
      };
}


