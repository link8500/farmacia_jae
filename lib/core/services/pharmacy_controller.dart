import 'package:flutter/foundation.dart';
import '../../models/inventory/models/product.dart';
import '../../models/sales/models/cart_line.dart';

/// Estado operativo compartido de la aplicación.
///
/// Este controlador reemplaza el estado mezclado dentro de la pantalla
/// principal. Las vistas solo muestran información y llaman métodos claros;
/// así el mismo estado puede conectarse después a una API o a una base local.
class PharmacyController extends ChangeNotifier {
  /// Crea el estado inicial con datos de demostración.
  PharmacyController() {
    products.addAll(_seedProducts());
  }

  /// Productos visibles y registrados en el inventario.
  final List<Product> products = [];

  /// Líneas de la venta que se está preparando.
  final List<CartLine> cart = [];

  /// Texto actual de búsqueda en inventario.
  String inventorySearch = '';

  /// Filtro actual de inventario.
  String inventoryFilter = 'Todos';

  /// Total de unidades existentes.
  int get stockTotal =>
      products.fold<int>(0, (total, product) => total + product.stock);

  /// Cantidad de productos bajo el mínimo configurado.
  int get lowStockCount => products.where((product) => product.isLow).length;

  /// Cantidad de productos próximos a vencer.
  int get expiringCount =>
      products.where((product) => product.isExpiring).length;

  /// Productos filtrados para la pantalla de inventario.
  List<Product> get visibleProducts {
    final query = inventorySearch.trim().toLowerCase();
    return products.where((product) {
      final matchesText =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      final matchesState = inventoryFilter == 'Bajo mínimo'
          ? product.isLow
          : inventoryFilter == 'Por vencer'
          ? product.isExpiring
          : true;
      return matchesText && matchesState;
    }).toList();
  }

  /// Actualiza la búsqueda del inventario.
  void setInventorySearch(String value) {
    inventorySearch = value;
    notifyListeners();
  }

  /// Cambia el filtro del inventario.
  void setInventoryFilter(String value) {
    inventoryFilter = value;
    notifyListeners();
  }

  /// Agrega un producto nuevo con valores iniciales seguros.
  void addProduct(String name) {
    products.add(
      Product(
        name: name,
        category: 'Sin categoría',
        stock: 0,
        minimum: 5,
        price: 0,
        expiry: DateTime.now().add(const Duration(days: 365)),
      ),
    );
    notifyListeners();
  }

  /// Agrega una unidad de producto al carrito de venta.
  ///
  /// Retorna false si el producto no tiene existencias, permitiendo que la
  /// vista muestre un mensaje sin acoplar el controlador a Flutter UI.
  bool addToCart(Product product) {
    if (product.stock < 1) return false;
    final found = cart.where((line) => line.product == product);
    if (found.isEmpty) {
      cart.add(CartLine(product));
    } else {
      found.first.quantity++;
    }
    notifyListeners();
    return true;
  }

  /// Quita una unidad de la línea seleccionada.
  void removeFromCart(CartLine line) {
    if (line.quantity == 1) {
      cart.remove(line);
    } else {
      line.quantity--;
    }
    notifyListeners();
  }

  /// Vacía la venta actual sin afectar existencias.
  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  /// Registra la venta y descuenta las unidades del inventario.
  bool finishSale() {
    if (cart.isEmpty) return false;
    for (final line in cart) {
      line.product.stock = (line.product.stock - line.quantity).clamp(
        0,
        999999,
      );
    }
    cart.clear();
    notifyListeners();
    return true;
  }

  /// Datos temporales usados mientras se integra la base de datos real.
  List<Product> _seedProducts() {
    final now = DateTime.now();
    return [
      Product(
        name: 'Paracetamol 500 mg',
        category: 'Analgésicos',
        stock: 42,
        minimum: 20,
        price: 3.50,
        expiry: now.add(const Duration(days: 420)),
      ),
      Product(
        name: 'Amoxicilina 500 mg',
        category: 'Antibióticos',
        stock: 8,
        minimum: 15,
        price: 8.75,
        expiry: now.add(const Duration(days: 48)),
      ),
      Product(
        name: 'Loratadina 10 mg',
        category: 'Antialérgicos',
        stock: 26,
        minimum: 12,
        price: 4.20,
        expiry: now.add(const Duration(days: 210)),
      ),
      Product(
        name: 'Ibuprofeno 400 mg',
        category: 'Analgésicos',
        stock: 5,
        minimum: 10,
        price: 4.90,
        expiry: now.add(const Duration(days: 24)),
      ),
      Product(
        name: 'Omeprazol 20 mg',
        category: 'Gastrointestinal',
        stock: 31,
        minimum: 12,
        price: 6.80,
        expiry: now.add(const Duration(days: 365)),
      ),
      Product(
        name: 'Alcohol medicinal 120 ml',
        category: 'Cuidado personal',
        stock: 68,
        minimum: 20,
        price: 2.25,
        expiry: now.add(const Duration(days: 680)),
      ),
      Product(
        name: 'Vitamina C 1 g',
        category: 'Vitaminas',
        stock: 12,
        minimum: 12,
        price: 5.50,
        expiry: now.add(const Duration(days: 75)),
      ),
      Product(
        name: 'Losartán 50 mg',
        category: 'Cardiovascular',
        stock: 19,
        minimum: 8,
        price: 7.25,
        expiry: now.add(const Duration(days: 290)),
      ),
    ];
  }
}
