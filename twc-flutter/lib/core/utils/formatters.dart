import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _cdf = NumberFormat('#,##0', 'fr_FR');

  /// Formate un montant en CDF avec séparateurs de milliers : 1 250 000 CDF
  static String cdf(dynamic amount) {
    final value = double.tryParse('$amount') ?? 0;
    return '${_cdf.format(value)} CDF';
  }
}
