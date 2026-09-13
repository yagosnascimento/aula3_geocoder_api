import 'dart:convert';

import 'package:aula3_geocoder_api/models/estado.dart';
import 'package:http/http.dart' as http;

class EstadosService {
  static const String urlEstados =
      'https://raw.githubusercontent.com/kelvins/municipios-brasileiros/refs/heads/main/json/estados.json';

  Future<List<Estado>> buscarEstados() async {
    final response = await http.get(Uri.parse(urlEstados));

    if (response.statusCode != 200) {
      throw Exception('Nao foi possivel carregar os estados');
    }

    final List<dynamic> dados = jsonDecode(response.body);

    return dados
        .map((item) => Estado.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
