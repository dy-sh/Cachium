import 'package:lucide_icons/lucide_icons.dart';

import '../../features/accounts/data/models/account.dart';
import '../../features/assets/data/models/asset.dart';
import '../../features/transactions/data/models/transaction.dart';

class DemoData {
  // ─── Account IDs ───────────────────────────────────────────────
  static const _checking = 'demo-acc-checking-001';
  static const _credit = 'demo-acc-credit-002';
  static const _cash = 'demo-acc-cash-003';
  static const _savings = 'demo-acc-savings-004';

  // ─── Asset IDs ─────────────────────────────────────────────────
  static const _assetCar = 'demo-asset-car-001';
  static const _assetLaptop = 'demo-asset-laptop-002';
  static const _assetHeadphones = 'demo-asset-headphones-003';
  static const _assetBike = 'demo-asset-bike-004';
  static const _assetCamera = 'demo-asset-camera-005';

  // ─── Category IDs (from DefaultCategories) ─────────────────────
  // Income
  static const _catSalary = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';
  static const _catFreelance = 'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e';
  // Expense - Food subcategories
  static const _catGroceries = 'f7a8b9c0-d1e2-4f3a-4b5c-6d7e8f9a0b1c';
  static const _catRestaurants = 'f8a9b0c1-d2e3-4f4a-5b6c-7d8e9f0a1b2c';
  static const _catDelivery = 'f9a0b1c2-d3e4-4f5a-6b7c-8d9e0f1a2b3c';
  // Expense - Transport
  static const _catTransport = 'a7b8c9d0-e1f2-4a3b-4c5d-6e7f8a9b0c1d';
  static const _catFuel = 'a8b9c0d1-e2f3-4a4b-5c6d-7e8f9a0b1c2d';
  static const _catPublicTransit = 'a9b0c1d2-e3f4-4a5b-6c7d-8e9f0a1b2c3d';
  // Expense - Shopping subcategories
  static const _catClothes = 'b9c0d1e2-f3a4-4b5c-6d7e-8f9a0b1c2d3e';
  static const _catElectronics = 'b0c1d2e3-f4a5-4b6c-7d8e-9f0a1b2c3d4e';
  // Expense - standalone
  static const _catEntertainment = 'd0e1f2a3-b4c5-4d6e-7f8a-9b0c1d2e3f4a';
  static const _catUtilities = 'c0d1e2f3-a4b5-4c6d-7e8f-9a0b1c2d3e4f';
  static const _catRent = 'c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f';
  static const _catInsurance = 'c2d3e4f5-a6b7-4c8d-9e0f-1a2b3c4d5e6f';
  static const _catHealth = 'd1e2f3a4-b5c6-4d7e-8f9a-0b1c2d3e4f5a';
  static const _catEducation = 'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a';

  // ─── Accounts ──────────────────────────────────────────────────
  static final List<Account> accounts = [
    Account(
      id: _checking,
      name: 'Checking',
      type: AccountType.bank,
      balance: 4850.00,
      initialBalance: 4850.00,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    Account(
      id: _credit,
      name: 'Credit Card',
      type: AccountType.creditCard,
      balance: -1280.00,
      initialBalance: -1280.00,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    Account(
      id: _cash,
      name: 'Cash',
      type: AccountType.cash,
      balance: 185.00,
      initialBalance: 185.00,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    Account(
      id: _savings,
      name: 'Savings',
      type: AccountType.savings,
      balance: 9200.00,
      initialBalance: 9200.00,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
  ];

  // ─── Assets ────────────────────────────────────────────────────
  static final List<Asset> assets = [
    Asset(
      id: _assetCar,
      name: 'Car',
      icon: LucideIcons.car,
      colorIndex: 17, // blue
      note: 'Daily commuter',
      sortOrder: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
    ),
    Asset(
      id: _assetLaptop,
      name: 'Laptop',
      icon: LucideIcons.laptop,
      colorIndex: 13, // cyan
      note: 'Work & freelance',
      sortOrder: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    Asset(
      id: _assetHeadphones,
      name: 'Headphones',
      icon: LucideIcons.headphones,
      colorIndex: 19, // violet
      sortOrder: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    Asset(
      id: _assetBike,
      name: 'Bicycle',
      icon: LucideIcons.bike,
      colorIndex: 9, // green
      status: AssetStatus.sold,
      note: 'Sold on marketplace',
      sortOrder: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
    ),
    Asset(
      id: _assetCamera,
      name: 'Camera',
      icon: LucideIcons.camera,
      colorIndex: 3, // orange
      note: 'Photography hobby',
      sortOrder: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 70)),
    ),
  ];

  // ─── Transactions ──────────────────────────────────────────────
  static List<Transaction> get transactions {
    final now = DateTime.now();
    int n = 0;
    String txId() => 'demo-tx-${(++n).toString().padLeft(3, '0')}';

    // Date in a specific month (0=current, 1=last, 2=two months ago)
    DateTime md(int monthsAgo, int day) =>
        DateTime(now.year, now.month - monthsAgo, day);

    // Recent date relative to today
    DateTime ago(int days) =>
        DateTime(now.year, now.month, now.day - days);

    // Transaction helper
    Transaction tx(
      double amount,
      TransactionType type,
      String categoryId,
      String accountId,
      DateTime date, {
      String? note,
      String? merchant,
      String? assetId,
    }) {
      return Transaction(
        id: txId(),
        amount: amount,
        type: type,
        categoryId: categoryId,
        accountId: accountId,
        date: date,
        note: note,
        merchant: merchant,
        assetId: assetId,
        createdAt: date,
      );
    }

    const inc = TransactionType.income;
    const exp = TransactionType.expense;

    final all = <Transaction>[
      // ═════════════════════════════════════════════════════════════
      // 2 MONTHS AGO
      // ═════════════════════════════════════════════════════════════
      tx(4200, inc, _catSalary, _checking, md(2, 1),
          note: 'Monthly salary', merchant: 'Employer'),
      tx(1450, exp, _catRent, _checking, md(2, 1),
          note: 'Monthly rent', merchant: 'Landlord'),
      tx(92, exp, _catGroceries, _credit, md(2, 3),
          note: 'Weekly groceries', merchant: 'Grocery store'),
      tx(15.99, exp, _catEntertainment, _credit, md(2, 5),
          note: 'Streaming subscription', merchant: 'Streaming service'),
      tx(7.50, exp, _catRestaurants, _cash, md(2, 6),
          note: 'Coffee & pastry', merchant: 'Coffee shop'),
      tx(48, exp, _catRestaurants, _credit, md(2, 8),
          note: 'Dinner with friends', merchant: 'Restaurant'),
      tx(42, exp, _catFuel, _credit, md(2, 10),
          note: 'Gas fill-up', merchant: 'Gas station',
          assetId: _assetCar),
      tx(10.99, exp, _catEntertainment, _credit, md(2, 10),
          note: 'Music subscription', merchant: 'Music service'),
      tx(108, exp, _catUtilities, _checking, md(2, 12),
          note: 'Electric bill', merchant: 'Electric company'),
      tx(115, exp, _catGroceries, _credit, md(2, 13),
          note: 'Groceries', merchant: 'Supermarket'),
      tx(35, exp, _catHealth, _credit, md(2, 15),
          note: 'Gym membership', merchant: 'Gym'),
      tx(14, exp, _catTransport, _cash, md(2, 16),
          note: 'Ride to downtown', merchant: 'Rideshare'),
      tx(22, exp, _catDelivery, _credit, md(2, 18),
          note: 'Food delivery', merchant: 'Delivery app'),
      tx(65, exp, _catUtilities, _checking, md(2, 20),
          note: 'Internet bill', merchant: 'Internet provider'),
      tx(88, exp, _catGroceries, _credit, md(2, 21),
          note: 'Weekly groceries', merchant: 'Grocery store'),
      tx(55, exp, _catRestaurants, _cash, md(2, 23),
          note: 'Birthday dinner', merchant: 'Restaurant'),
      tx(350, inc, _catFreelance, _checking, md(2, 24),
          note: 'Website mockup', merchant: 'Freelance client',
          assetId: _assetLaptop),
      tx(38, exp, _catFuel, _credit, md(2, 25),
          note: 'Gas fill-up', merchant: 'Gas station',
          assetId: _assetCar),
      tx(76, exp, _catClothes, _credit, md(2, 26),
          note: 'Winter jacket', merchant: 'Clothing store'),
      tx(95, exp, _catGroceries, _credit, md(2, 28),
          note: 'Groceries', merchant: 'Supermarket'),
      tx(180, exp, _catInsurance, _checking, md(2, 28),
          note: 'Car insurance', merchant: 'Insurance company',
          assetId: _assetCar),

      // ═════════════════════════════════════════════════════════════
      // 1 MONTH AGO
      // ═════════════════════════════════════════════════════════════
      tx(4200, inc, _catSalary, _checking, md(1, 1),
          note: 'Monthly salary', merchant: 'Employer'),
      tx(1450, exp, _catRent, _checking, md(1, 1),
          note: 'Monthly rent', merchant: 'Landlord'),
      tx(850, inc, _catFreelance, _checking, md(1, 2),
          note: 'Logo design project', merchant: 'Freelance client',
          assetId: _assetLaptop),
      tx(105, exp, _catGroceries, _credit, md(1, 3),
          note: 'Groceries', merchant: 'Supermarket'),
      tx(15.99, exp, _catEntertainment, _credit, md(1, 5),
          note: 'Streaming subscription', merchant: 'Streaming service'),
      tx(38, exp, _catRestaurants, _credit, md(1, 6),
          note: 'Lunch with coworker', merchant: 'Bistro'),
      tx(6.80, exp, _catRestaurants, _cash, md(1, 7),
          note: 'Morning coffee', merchant: 'Coffee shop'),
      tx(2.75, exp, _catPublicTransit, _cash, md(1, 8),
          note: 'Subway ride', merchant: 'Transit'),
      tx(45, exp, _catFuel, _credit, md(1, 9),
          note: 'Gas fill-up', merchant: 'Gas station',
          assetId: _assetCar),
      tx(10.99, exp, _catEntertainment, _credit, md(1, 10),
          note: 'Music subscription', merchant: 'Music service'),
      tx(24, exp, _catHealth, _cash, md(1, 11),
          note: 'Cold medicine', merchant: 'Pharmacy'),
      tx(118, exp, _catUtilities, _checking, md(1, 12),
          note: 'Electric bill', merchant: 'Electric company'),
      tx(98, exp, _catGroceries, _credit, md(1, 14),
          note: 'Weekly groceries', merchant: 'Grocery store'),
      tx(35, exp, _catHealth, _credit, md(1, 15),
          note: 'Gym membership', merchant: 'Gym'),
      tx(18, exp, _catDelivery, _credit, md(1, 16),
          note: 'Pizza delivery', merchant: 'Delivery app'),
      tx(79, exp, _catElectronics, _credit, md(1, 17),
          note: 'Wireless headphones', merchant: 'Electronics store',
          assetId: _assetHeadphones),
      tx(65, exp, _catUtilities, _checking, md(1, 20),
          note: 'Internet bill', merchant: 'Internet provider'),
      tx(82, exp, _catGroceries, _credit, md(1, 21),
          note: 'Groceries', merchant: 'Grocery store'),
      tx(62, exp, _catRestaurants, _credit, md(1, 22),
          note: 'Anniversary dinner', merchant: 'Restaurant'),
      tx(28, exp, _catEntertainment, _cash, md(1, 23),
          note: 'Movie night', merchant: 'Cinema'),
      tx(120, exp, _catElectronics, _credit, md(1, 24),
          note: 'Camera lens filter', merchant: 'Photo store',
          assetId: _assetCamera),
      tx(48, exp, _catFuel, _credit, md(1, 25),
          note: 'Gas fill-up', merchant: 'Gas station',
          assetId: _assetCar),
      tx(110, exp, _catGroceries, _credit, md(1, 27),
          note: 'Weekly groceries', merchant: 'Supermarket'),
      tx(145, exp, _catInsurance, _checking, md(1, 28),
          note: 'Car insurance', merchant: 'Insurance company',
          assetId: _assetCar),

      // ═════════════════════════════════════════════════════════════
      // CURRENT MONTH (early fixed dates)
      // ═════════════════════════════════════════════════════════════
      tx(4200, inc, _catSalary, _checking, md(0, 1),
          note: 'Monthly salary', merchant: 'Employer'),
      tx(1450, exp, _catRent, _checking, md(0, 1),
          note: 'Monthly rent', merchant: 'Landlord'),
      tx(97, exp, _catGroceries, _credit, md(0, 3),
          note: 'Groceries', merchant: 'Grocery store'),
      tx(15.99, exp, _catEntertainment, _credit, md(0, 5),
          note: 'Streaming subscription', merchant: 'Streaming service'),
      tx(8.50, exp, _catRestaurants, _cash, md(0, 7),
          note: 'Coffee and sandwich', merchant: 'Cafe'),
      tx(65, exp, _catUtilities, _checking, md(0, 8),
          note: 'Internet bill', merchant: 'Internet provider'),
      tx(45, exp, _catFuel, _credit, md(0, 9),
          note: 'Gas fill-up', merchant: 'Gas station',
          assetId: _assetCar),

      // ═════════════════════════════════════════════════════════════
      // RECENT STREAK (consecutive days relative to today)
      // ═════════════════════════════════════════════════════════════
      tx(10.99, exp, _catEntertainment, _credit, ago(9),
          note: 'Music subscription', merchant: 'Music service'),
      tx(84, exp, _catGroceries, _credit, ago(8),
          note: 'Weekly groceries', merchant: 'Supermarket'),
      tx(112, exp, _catUtilities, _checking, ago(7),
          note: 'Electric bill', merchant: 'Electric company'),
      tx(42, exp, _catRestaurants, _credit, ago(6),
          note: 'Dinner out', merchant: 'Restaurant'),
      tx(5.50, exp, _catRestaurants, _cash, ago(5),
          note: 'Afternoon coffee', merchant: 'Coffee shop'),
      tx(18, exp, _catTransport, _cash, ago(4),
          note: 'Ride to appointment', merchant: 'Rideshare'),
      tx(35, exp, _catHealth, _credit, ago(3),
          note: 'Gym membership', merchant: 'Gym'),
      tx(49, exp, _catEducation, _credit, ago(2),
          note: 'Online course', merchant: 'Learning platform',
          assetId: _assetLaptop),
      tx(25, exp, _catDelivery, _credit, ago(1),
          note: 'Sushi delivery', merchant: 'Delivery app'),
      tx(90, exp, _catGroceries, _credit, ago(0),
          note: 'Grocery run', merchant: 'Grocery store'),
    ];

    // Filter out future dates (for current month when day hasn't arrived yet)
    return all.where((tx) => !tx.date.isAfter(now)).toList();
  }
}
