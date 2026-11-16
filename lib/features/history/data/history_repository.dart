import '../../../core/network/api_client.dart';
import 'models/transaction.dart';

class HistoryRepository {
  const HistoryRepository(this.client);

  final ApiClient client;

  Future<HistoryPageData> load(String token, int page) async {
    final response = await client.post('pagos/historial', {
      'pagina': page,
      'tamanio': 10,
    }, token: token);

    final data = response['datos'];
    if (response['codigo'] != 0 || data is! Map<String, dynamic>) {
      throw _invalidHistory;
    }
    final content = data['content'];
    final metadata = data['page'];
    if (content is! List || metadata is! Map<String, dynamic>) {
      throw _invalidHistory;
    }
    final number = metadata['number'];
    final totalPages = metadata['totalPages'];
    if (number is! int ||
        number != page ||
        totalPages is! int ||
        totalPages < 0) {
      throw _invalidHistory;
    }

    try {
      return HistoryPageData(
        transactions: List.unmodifiable(
          content.map((entry) {
            if (entry is! Map<String, dynamic>) throw const FormatException();
            return PurchaseTransaction.fromJson(entry);
          }),
        ),
        number: number,
        totalPages: totalPages,
      );
    } on FormatException {
      throw _invalidHistory;
    }
  }

  static const _invalidHistory = ApiException(
    'No pudimos leer el historial de pagos.',
  );
}

class HistoryPageData {
  const HistoryPageData({
    required this.transactions,
    required this.number,
    required this.totalPages,
  });

  final List<PurchaseTransaction> transactions;
  final int number;
  final int totalPages;
}
