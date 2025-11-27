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

  factory CategoryDto.fromJson(Map<String, dynamic> json) => CategoryDto.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  // Helper para converter para entidade de domínio
  // Importação circular evitada assumindo que quem usa faz a conversão se necessário,
  // ou adicionando import se não houver conflito.
  // Mas para manter simples, vamos deixar quem usa converter por enquanto,
  // ou adicionar um método simples se tivermos acesso à entidade.

}


