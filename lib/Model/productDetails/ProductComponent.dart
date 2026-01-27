import 'ProductOption.dart';

class ComponentStockView {
  final ProductComponent component;
  final int before;
  final int used;
  final int after;

  ComponentStockView({
    required this.component,
    required this.before,
    required this.used,
    required this.after,
  });
}
