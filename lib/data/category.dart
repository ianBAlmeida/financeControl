//enum de todas as categorias disponíveis, pode ser mudado
enum Category {
  alimentacao,
  transporte,
  lazer,
  carro,
  servico,
  mercado,
  cosmetico,
  outros,
}

//rótulo legível
extension CategoryLabel on Category {
  String get label => switch (this) {
    Category.alimentacao => 'Comida',
    Category.transporte => 'Transporte',
    Category.lazer => 'Lazer',
    Category.carro => 'Carro',
    Category.servico => 'Serviço',
    Category.mercado => 'Mercado',
    Category.cosmetico => 'Cosméticos',
    Category.outros => 'Outros',
  };
}

//Converte para string (salva JSON) de volta para o enum
Category categoryFormString(String value) {
  return Category.values.firstWhere(
    (c) => c.name == value,
    orElse: () => Category.outros,
  );
}
