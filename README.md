# Aplicativo de Geocodificação e Estados Brasileiros

Este projeto é um aplicativo Flutter criado para estudar três ideias principais:

1. Fazer uma chamada para uma API de geocodificação.
2. Transformar dados JSON em objetos do Dart.
3. Mostrar informações geográficas em um mapa.

O aplicativo possui duas funções relacionadas a mapas:

- O usuário digita um endereço ou local e o aplicativo procura esse lugar.
- O mapa mostra um marcador para o resultado da busca e marcadores para os estados brasileiros.

## O que é geocodificação?

Geocodificação é o processo de transformar um texto, como o nome de uma cidade ou de uma instituição, em uma localização geográfica.

Por exemplo:

```text
Fundação Educacional do Município de Assis
```

Pode ser transformado em:

```text
Latitude: -22.66
Longitude: -50.41
```

Com latitude e longitude, conseguimos posicionar o local no mapa.

## O que o aplicativo faz?

O fluxo principal funciona assim:

1. O aplicativo abre a tela inicial.
2. O usuário digita um endereço no campo de pesquisa.
3. O aplicativo espera três segundos depois da última alteração no texto.
4. O serviço `NominatimService` consulta a API do Nominatim.
5. A resposta JSON é transformada em um objeto `GeocodeResult`.
6. A tela mostra os dados encontrados.
7. O usuário toca em `Visualizar Mapa`.
8. A tela do mapa mostra o marcador vermelho do local pesquisado.
9. A tela também busca os estados brasileiros.
10. Cada estado é mostrado com um marcador azul.
11. Ao tocar em um estado, o aplicativo mostra seu nome, sigla, região e código.

## Organização das pastas

```text
lib/
├── main.dart
├── models/
│   ├── estado.dart
│   └── geocode_result.dart
└── services/
		├── estados_service.dart
		└── nominatim_service.dart
```

### `lib/main.dart`

É o arquivo principal da aplicação. Ele contém:

- `main()`, que inicia o Flutter;
- `MainApp`, que configura o aplicativo;
- `HomePage`, que possui o campo de pesquisa;
- `MapPage`, que mostra o mapa;
- os marcadores e os botões de zoom.

O `main.dart` usa as classes de `models` e `services`, mas não precisa saber todos os detalhes de como os dados foram buscados.

### `lib/models/estado.dart`

Este arquivo possui a classe `Estado`.

Um modelo é uma classe que representa uma informação do sistema. Neste caso, um objeto `Estado` representa um estado brasileiro e guarda:

| Campo | Tipo | Significado |
|---|---|---|
| `codigoUf` | `int` | Código numérico da UF |
| `uf` | `String` | Sigla, como `SP` ou `RJ` |
| `nome` | `String` | Nome completo do estado |
| `latitude` | `double` | Latitude do ponto central aproximado |
| `longitude` | `double` | Longitude do ponto central aproximado |
| `regiao` | `String` | Região brasileira |

O modelo não faz chamada para a internet. Ele apenas organiza os dados.

O método abaixo recebe um mapa com dados JSON e cria um objeto `Estado`:

```dart
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
```

### `lib/services/estados_service.dart`

Este arquivo possui a classe `EstadosService`.

Um serviço é uma classe auxiliar que realiza uma tarefa específica. Neste caso, a tarefa é:

1. Acessar a URL dos estados.
2. Fazer uma requisição HTTP.
3. Ler o JSON recebido.
4. Criar uma lista de objetos `Estado`.

A URL usada é:

```text
https://raw.githubusercontent.com/kelvins/municipios-brasileiros/refs/heads/main/json/estados.json
```

O serviço faz a requisição com o pacote `http`:

```dart
final response = await http.get(Uri.parse(urlEstados));
```

Depois, verifica se a chamada funcionou:

```dart
if (response.statusCode != 200) {
	throw Exception('Nao foi possivel carregar os estados');
}
```

O código `200` significa que a requisição foi realizada com sucesso.

Depois da resposta, o texto JSON é convertido para uma lista e cada item vira um objeto `Estado`:

```dart
final List<dynamic> dados = jsonDecode(response.body);

return dados
		.map((item) => Estado.fromJson(item as Map<String, dynamic>))
		.toList();
```

## Formato do JSON dos estados

A API retorna uma lista. Cada item possui este formato:

```json
{
	"codigo_uf": 35,
	"uf": "SP",
	"nome": "São Paulo",
	"latitude": -22.19,
	"longitude": -48.79,
	"regiao": "Sudeste"
}
```

O `Estado.fromJson` relaciona cada nome do JSON com um atributo da classe:

| Campo do JSON | Atributo Dart |
|---|---|
| `codigo_uf` | `codigoUf` |
| `uf` | `uf` |
| `nome` | `nome` |
| `latitude` | `latitude` |
| `longitude` | `longitude` |
| `regiao` | `regiao` |

Essa conversão é importante porque trabalhar com objetos nomeados é mais organizado do que acessar os textos do JSON espalhados pela interface.

## Marcadores no mapa

Na `MapPage`, o serviço é criado:

```dart
final EstadosService estadosService = EstadosService();
```

Quando a tela é aberta, o método `carregarEstados()` busca os estados:

```dart
final resultado = await estadosService.buscarEstados();
```

Depois que a lista chega, ela é guardada na variável `estados`. A interface usa essa lista para criar um marcador para cada item.

### Marcador dos estados

Os marcadores estaduais usam o ícone azul:

```dart
Icon(
	Icons.location_on,
	size: 26.0,
	color: Colors.blue,
)
```

Cada marcador recebe a posição do próprio estado:

```dart
point: LatLng(estado.latitude, estado.longitude)
```

Quando o usuário toca no marcador, um diálogo mostra os dados do estado.

### Marcador da pesquisa original

O marcador do endereço pesquisado continua separado dos marcadores estaduais. Ele usa o ícone vermelho:

```dart
Icon(
	Icons.location_pin,
	size: 32.0,
	color: Colors.red,
)
```

Assim, é possível diferenciar visualmente:

- marcador vermelho: local encontrado pela busca do usuário;
- marcador azul: estado brasileiro.

## Pacotes utilizados

As dependências estão no arquivo `pubspec.yaml`:

| Pacote | Uso |
|---|---|
| `http` | Fazer chamadas HTTP para as APIs |
| `flutter_map` | Mostrar o mapa e os marcadores |
| `latlong2` | Representar latitude e longitude |
| `flutter_test` | Criar testes para widgets Flutter |
| `flutter_lints` | Ajudar a encontrar problemas de estilo no código |

## API de geocodificação

O serviço original usa o Nominatim, que faz parte do ecossistema OpenStreetMap.

A consulta possui estes parâmetros:

```text
q               texto digitado pelo usuário
format          formato da resposta, neste caso JSON
namedetails     informa se detalhes adicionais do nome serão retornados
addressdetails  solicita os detalhes do endereço
limit           quantidade máxima de resultados, neste caso 1
```

A resposta do Nominatim é convertida pela classe `GeocodeResult`, localizada em `lib/models/geocode_result.dart`.

## Como executar o projeto

É necessário ter o Flutter instalado e configurado no PATH do sistema.

No terminal, dentro da pasta do projeto, execute:

```powershell
flutter pub get
flutter analyze
flutter run
```

Para executar no navegador, pode ser usado:

```powershell
flutter run -d chrome
```

Ou, conforme a anotação original do projeto:

```powershell
flutter run -d web-server
```

## Como apresentar a atividade

Uma explicação simples para apresentar ao professor pode ser:

> Primeiro foi criado o modelo `Estado`, responsável por representar os dados de cada estado brasileiro. Depois foi criado o `EstadosService`, responsável por acessar a URL, receber o JSON e transformar cada item em um objeto `Estado`. Por fim, a `MapPage` usa essa lista de objetos para criar marcadores azuis no mapa. O marcador vermelho continua representando o resultado da busca feita pelo usuário através do Nominatim.

Também foi mantida uma separação de responsabilidades:

- o modelo representa os dados;
- o serviço busca os dados;
- a tela apresenta os dados.

Essa separação facilita a leitura e permite alterar a fonte dos dados sem precisar reescrever toda a interface.

## Commits da atividade

As alterações foram divididas em commits para mostrar a evolução do trabalho:

```text
0e80010 feat: criar modelo de estado brasileiro
```

Criou a classe `Estado` e o método `Estado.fromJson`.

```text
2529e4c feat: adicionar servico de estados brasileiros
```

Criou a classe `EstadosService`, responsável pela chamada HTTP e pela conversão da lista JSON.

```text
7b3d8c3 feat: exibir marcadores dos estados no mapa
```

Adicionou os marcadores azuis dos estados e preservou o marcador vermelho da pesquisa.

Depois, um commit de documentação foi revertido, conforme solicitado, então ele não faz mais parte do comportamento atual.

## Observações

- A URL dos estados precisa estar disponível na internet para os marcadores serem carregados.
- Se a chamada falhar, a tela mostra uma mensagem de erro.
- As coordenadas dos estados são pontos aproximados usados para posicionar os marcadores.
- O projeto ainda possui o teste padrão inicial do Flutter, que não foi atualizado para o fluxo de geocodificação.
