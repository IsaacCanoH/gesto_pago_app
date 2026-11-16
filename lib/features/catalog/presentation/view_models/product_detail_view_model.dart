import '../../../purchases/data/models/purchase_draft.dart';
import '../../data/models/product.dart';

class ProductDetailViewModel {
  const ProductDetailViewModel(this.product);

  final Product product;
  static final _amountPattern = RegExp(r'^(\d{1,13})(?:[.,](\d{1,2}))?$');

  String? legendFor(ProductOffer? selected) {
    if (selected != null) return selected.legend;
    final shared = product.offers.firstOrNull?.legend;
    if (shared == null) return null;
    return product.offers.every((offer) => offer.legend == shared)
        ? shared
        : null;
  }

  String? validateOffer(ProductOffer? offer) {
    return offer?.price == null ? 'Selecciona un importe.' : null;
  }

  String? validateReference(String? value) {
    final reference = value?.trim() ?? '';
    if (product.fixed) {
      return reference.length < 10 || reference.length > 20
          ? 'Ingresa un teléfono o identificador de 10 a 20 caracteres.'
          : null;
    }
    if (reference.isEmpty) return 'Ingresa la referencia del servicio.';
    return reference.length > 100
        ? 'La referencia admite hasta 100 caracteres.'
        : null;
  }

  String? validateAmount(String? value) {
    return _parseCents(value) == null
        ? 'Ingresa un importe mayor a cero con hasta dos decimales.'
        : null;
  }

  PurchaseDraft? draft({
    required ProductOffer? denomination,
    required String reference,
    required String amount,
  }) {
    final offer = product.fixed ? denomination : product.offers.single;
    final cents = _parseCents(
      product.fixed ? offer?.price?.toStringAsFixed(2) : amount,
    );
    if (offer == null || cents == null) return null;

    return PurchaseDraft(
      serviceId: product.serviceId,
      productId: offer.id,
      type: product.type,
      serviceName: product.service,
      productName: offer.name,
      reference: reference.trim(),
      amountInCents: cents,
    );
  }

  static int? _parseCents(String? value) {
    final match = _amountPattern.firstMatch(value?.trim() ?? '');
    if (match == null) return null;
    final units = int.parse(match[1]!);
    final fraction = (match[2] ?? '').padRight(2, '0');
    final cents = units * 100 + int.parse(fraction);
    return cents > 0 ? cents : null;
  }
}
