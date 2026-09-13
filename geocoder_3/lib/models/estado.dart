// Esta classe representa apenas os dados de um estado brasileiro.
// Ela nao faz chamada para a internet.
class Estado {
  final int codigoUf;
  final String uf;
  final String nome;
  final double latitude;
  final double longitude;
  final String regiao;

  Estado({
    required this.codigoUf,
    required this.uf,
    required this.nome,
    required this.latitude,
    required this.longitude,
    required this.regiao,
  });

  // Cria um Estado usando os dados que vieram no JSON.
  factory Estado.fromJson(Map<String, dynamic> json) {
    return Estado(
      codigoUf: json['codigo_uf'],
      uf: json['uf'],
      nome: json['nome'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      regiao: json['regiao'],
    );
  }
}
