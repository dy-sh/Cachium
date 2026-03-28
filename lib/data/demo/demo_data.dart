import 'package:lucide_icons/lucide_icons.dart';

import '../../core/utils/currency_conversion.dart';
import '../../features/accounts/data/models/account.dart';
import '../../features/assets/data/models/asset.dart';
import '../../features/assets/data/models/asset_category.dart';
import '../../features/bills/data/models/bill.dart';
import '../../features/budgets/data/models/budget.dart';
import '../../features/savings_goals/data/models/savings_goal.dart';
import '../../features/tags/data/models/tag.dart';
import '../../features/transactions/data/models/recurring_rule.dart';
import '../../features/transactions/data/models/transaction.dart';
import '../../features/transactions/data/models/transaction_template.dart';

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

  // ─── Asset Category IDs ──────────────────────────────────────────
  static const _assetCatVehicle = 'demo-acat-vehicle-001';
  static const _assetCatElectronics = 'demo-acat-electronics-002';
  static const _assetCatCollectible = 'demo-acat-collectible-003';
  static const _assetCatOther = 'demo-acat-other-004';

  // ─── Tag IDs ─────────────────────────────────────────────────────
  static const _tagEssential = 'demo-tag-essential-001';
  static const _tagDiscretionary = 'demo-tag-discretionary-002';
  static const _tagRecurring = 'demo-tag-recurring-003';

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
      currencyCode: 'USD',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    Account(
      id: _credit,
      name: 'Credit Card',
      type: AccountType.creditCard,
      balance: -1280.00,
      initialBalance: -1280.00,
      currencyCode: 'EUR',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    Account(
      id: _cash,
      name: 'Cash',
      type: AccountType.cash,
      balance: 185.00,
      initialBalance: 185.00,
      currencyCode: 'GBP',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    Account(
      id: _savings,
      name: 'Savings',
      type: AccountType.savings,
      balance: 9200.00,
      initialBalance: 9200.00,
      currencyCode: 'USD',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
  ];

  // ─── Asset Categories ────────────────────────────────────────────
  static final List<AssetCategory> assetCategories = [
    AssetCategory(
      id: _assetCatVehicle,
      name: 'Vehicle',
      icon: LucideIcons.car,
      colorIndex: 0,
      sortOrder: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    AssetCategory(
      id: _assetCatElectronics,
      name: 'Electronics',
      icon: LucideIcons.laptop,
      colorIndex: 8,
      sortOrder: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    AssetCategory(
      id: _assetCatCollectible,
      name: 'Collectible',
      icon: LucideIcons.trophy,
      colorIndex: 16,
      sortOrder: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    AssetCategory(
      id: _assetCatOther,
      name: 'Other',
      icon: LucideIcons.box,
      colorIndex: 20,
      sortOrder: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
  ];

  // ─── Assets ────────────────────────────────────────────────────
  static final List<Asset> assets = [
    Asset(
      id: _assetCar,
      name: 'Car',
      icon: LucideIcons.car,
      colorIndex: 17,
      note: 'Daily commuter',
      assetCategoryId: _assetCatVehicle,
      purchasePrice: 18500.00,
      purchaseCurrencyCode: 'USD',
      purchaseDate: DateTime.now().subtract(const Duration(days: 100)),
      sortOrder: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
    ),
    Asset(
      id: _assetLaptop,
      name: 'Laptop',
      icon: LucideIcons.laptop,
      colorIndex: 13,
      note: 'Work & freelance',
      assetCategoryId: _assetCatElectronics,
      purchasePrice: 1299.00,
      purchaseCurrencyCode: 'USD',
      purchaseDate: DateTime.now().subtract(const Duration(days: 90)),
      sortOrder: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    Asset(
      id: _assetHeadphones,
      name: 'Headphones',
      icon: LucideIcons.headphones,
      colorIndex: 19,
      assetCategoryId: _assetCatElectronics,
      purchasePrice: 85.00,
      purchaseCurrencyCode: 'EUR',
      purchaseDate: DateTime.now().subtract(const Duration(days: 45)),
      sortOrder: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    Asset(
      id: _assetBike,
      name: 'Bicycle',
      icon: LucideIcons.bike,
      colorIndex: 9,
      status: AssetStatus.sold,
      note: 'Sold on marketplace',
      assetCategoryId: _assetCatOther,
      purchasePrice: 450.00,
      purchaseCurrencyCode: 'USD',
      purchaseDate: DateTime.now().subtract(const Duration(days: 80)),
      salePrice: 320.00,
      saleCurrencyCode: 'USD',
      soldDate: DateTime.now().subtract(const Duration(days: 15)),
      sortOrder: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
    ),
    Asset(
      id: _assetCamera,
      name: 'Camera',
      icon: LucideIcons.camera,
      colorIndex: 3,
      note: 'Photography hobby',
      assetCategoryId: _assetCatCollectible,
      purchasePrice: 650.00,
      purchaseCurrencyCode: 'USD',
      purchaseDate: DateTime.now().subtract(const Duration(days: 70)),
      sortOrder: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 70)),
    ),
  ];

  // ─── Tags ──────────────────────────────────────────────────────
  static const List<Tag> tags = [
    Tag(
      id: _tagEssential,
      name: 'Essential',
      colorIndex: 9,
      icon: LucideIcons.shieldCheck,
      sortOrder: 0,
    ),
    Tag(
      id: _tagDiscretionary,
      name: 'Discretionary',
      colorIndex: 19,
      icon: LucideIcons.sparkles,
      sortOrder: 1,
    ),
    Tag(
      id: _tagRecurring,
      name: 'Recurring',
      colorIndex: 13,
      icon: LucideIcons.repeat,
      sortOrder: 2,
    ),
  ];

  // ─── Bills ─────────────────────────────────────────────────────
  static final List<Bill> bills = [
    Bill(
      id: 'demo-bill-rent-001',
      name: 'Monthly Rent',
      amount: 1450.00,
      currencyCode: 'USD',
      categoryId: _catRent,
      accountId: _checking,
      dueDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 1),
      frequency: RecurrenceFrequency.monthly,
      reminderDaysBefore: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    Bill(
      id: 'demo-bill-internet-002',
      name: 'Internet',
      amount: 65.00,
      currencyCode: 'USD',
      categoryId: _catUtilities,
      accountId: _checking,
      dueDate: DateTime(DateTime.now().year, DateTime.now().month, 20),
      frequency: RecurrenceFrequency.monthly,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    Bill(
      id: 'demo-bill-streaming-003',
      name: 'Streaming Service',
      amount: 15.99,
      currencyCode: 'EUR',
      categoryId: _catEntertainment,
      accountId: _credit,
      dueDate: DateTime(DateTime.now().year, DateTime.now().month, 5),
      frequency: RecurrenceFrequency.monthly,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Bill(
      id: 'demo-bill-gym-004',
      name: 'Gym Membership',
      amount: 35.00,
      currencyCode: 'EUR',
      categoryId: _catHealth,
      accountId: _credit,
      dueDate: DateTime(DateTime.now().year, DateTime.now().month, 15),
      frequency: RecurrenceFrequency.monthly,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Bill(
      id: 'demo-bill-insurance-005',
      name: 'Car Insurance',
      amount: 145.00,
      currencyCode: 'USD',
      categoryId: _catInsurance,
      accountId: _checking,
      assetId: _assetCar,
      dueDate: DateTime(DateTime.now().year, DateTime.now().month, 28),
      frequency: RecurrenceFrequency.monthly,
      reminderDaysBefore: 7,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
  ];

  // ─── Budgets ───────────────────────────────────────────────────
  static List<Budget> get budgets {
    final now = DateTime.now();
    return [
      Budget(
        id: 'demo-budget-groceries-001',
        categoryId: _catGroceries,
        amount: 400.00,
        year: now.year,
        month: now.month,
        rolloverEnabled: true,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      Budget(
        id: 'demo-budget-restaurants-002',
        categoryId: _catRestaurants,
        amount: 200.00,
        year: now.year,
        month: now.month,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      Budget(
        id: 'demo-budget-entertainment-003',
        categoryId: _catEntertainment,
        amount: 100.00,
        year: now.year,
        month: now.month,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      Budget(
        id: 'demo-budget-transport-004',
        categoryId: _catTransport,
        amount: 150.00,
        year: now.year,
        month: now.month,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
    ];
  }

  // ─── Savings Goals ─────────────────────────────────────────────
  static final List<SavingsGoal> savingsGoals = [
    SavingsGoal(
      id: 'demo-goal-emergency-001',
      name: 'Emergency Fund',
      targetAmount: 15000.00,
      currentAmount: 9200.00,
      colorIndex: 9,
      icon: LucideIcons.shieldCheck,
      linkedAccountId: _savings,
      targetDate: DateTime(DateTime.now().year + 1, 6, 1),
      note: '6 months of expenses',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    SavingsGoal(
      id: 'demo-goal-vacation-002',
      name: 'Summer Vacation',
      targetAmount: 3000.00,
      currentAmount: 1250.00,
      colorIndex: 13,
      icon: LucideIcons.plane,
      targetDate: DateTime(DateTime.now().year, 8, 1),
      note: 'Beach trip',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
  ];

  // ─── Transaction Templates ─────────────────────────────────────
  static final List<TransactionTemplate> transactionTemplates = [
    TransactionTemplate(
      id: 'demo-template-groceries-001',
      name: 'Weekly Groceries',
      amount: 95.00,
      type: TransactionType.expense,
      categoryId: _catGroceries,
      accountId: _credit,
      merchant: 'Supermarket',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    TransactionTemplate(
      id: 'demo-template-coffee-002',
      name: 'Morning Coffee',
      amount: 6.50,
      type: TransactionType.expense,
      categoryId: _catRestaurants,
      accountId: _cash,
      merchant: 'Coffee shop',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    TransactionTemplate(
      id: 'demo-template-fuel-003',
      name: 'Gas Fill-up',
      amount: 45.00,
      type: TransactionType.expense,
      categoryId: _catFuel,
      accountId: _credit,
      merchant: 'Gas station',
      note: 'Car fuel',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  // Tag assignments: transaction ID -> list of tag IDs
  static final Map<String, List<String>> transactionTagAssignments = {};

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

    // Currency codes by account
    const accountCurrencies = {
      _checking: 'USD',
      _credit: 'EUR',
      _cash: 'GBP',
      _savings: 'USD',
    };
    // Approximate conversion rates to USD (main currency)
    const conversionRates = {
      'USD': 1.0,
      'EUR': 1.08,
      'GBP': 1.27,
    };

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
      List<String>? tagIds,
    }) {
      final currency = accountCurrencies[accountId] ?? 'USD';
      final rate = conversionRates[currency] ?? 1.0;
      // Main currency is USD for demo data
      final mainCurrencyAmount = currency == 'USD'
          ? amount
          : roundCurrency(amount * rate);
      final id = txId();
      if (tagIds != null && tagIds.isNotEmpty) {
        transactionTagAssignments[id] = tagIds;
      }
      return Transaction(
        id: id,
        amount: amount,
        type: type,
        categoryId: categoryId,
        accountId: accountId,
        date: date,
        note: note,
        merchant: merchant,
        assetId: assetId,
        currencyCode: currency,
        conversionRate: rate,
        mainCurrencyCode: 'USD',
        mainCurrencyAmount: mainCurrencyAmount,
        createdAt: date,
      );
    }

    const inc = TransactionType.income;
    const exp = TransactionType.expense;

    // Clear previous tag assignments
    transactionTagAssignments.clear();

    final all = <Transaction>[
      // ═════════════════════════════════════════════════════════════
      // 2 MONTHS AGO
      // ═════════════════════════════════════════════════════════════
      tx(4200, inc, _catSalary, _checking, md(2, 1),
          note: 'Monthly salary', merchant: 'Employer',
          tagIds: [_tagRecurring]),
      tx(1450, exp, _catRent, _checking, md(2, 1),
          note: 'Monthly rent', merchant: 'Landlord',
          tagIds: [_tagEssential, _tagRecurring]),
      tx(92, exp, _catGroceries, _credit, md(2, 3),
          note: 'Weekly groceries', merchant: 'Grocery store',
          tagIds: [_tagEssential]),
      tx(15.99, exp, _catEntertainment, _credit, md(2, 5),
          note: 'Streaming subscription', merchant: 'Streaming service',
          tagIds: [_tagRecurring, _tagDiscretionary]),
      tx(7.50, exp, _catRestaurants, _cash, md(2, 6),
          note: 'Coffee & pastry', merchant: 'Coffee shop',
          tagIds: [_tagDiscretionary]),
      tx(48, exp, _catRestaurants, _credit, md(2, 8),
          note: 'Dinner with friends', merchant: 'Restaurant',
          tagIds: [_tagDiscretionary]),
      tx(42, exp, _catFuel, _credit, md(2, 10),
          note: 'Gas fill-up', merchant: 'Gas station',
          assetId: _assetCar, tagIds: [_tagEssential]),
      tx(10.99, exp, _catEntertainment, _credit, md(2, 10),
          note: 'Music subscription', merchant: 'Music service',
          tagIds: [_tagRecurring, _tagDiscretionary]),
      tx(108, exp, _catUtilities, _checking, md(2, 12),
          note: 'Electric bill', merchant: 'Electric company',
          tagIds: [_tagEssential, _tagRecurring]),
      tx(115, exp, _catGroceries, _credit, md(2, 13),
          note: 'Groceries', merchant: 'Supermarket',
          tagIds: [_tagEssential]),
      tx(35, exp, _catHealth, _credit, md(2, 15),
          note: 'Gym membership', merchant: 'Gym',
          tagIds: [_tagRecurring]),
      tx(14, exp, _catTransport, _cash, md(2, 16),
          note: 'Ride to downtown', merchant: 'Rideshare'),
      tx(22, exp, _catDelivery, _credit, md(2, 18),
          note: 'Food delivery', merchant: 'Delivery app',
          tagIds: [_tagDiscretionary]),
      tx(65, exp, _catUtilities, _checking, md(2, 20),
          note: 'Internet bill', merchant: 'Internet provider',
          tagIds: [_tagEssential, _tagRecurring]),
      tx(88, exp, _catGroceries, _credit, md(2, 21),
          note: 'Weekly groceries', merchant: 'Grocery store',
          tagIds: [_tagEssential]),
      tx(55, exp, _catRestaurants, _cash, md(2, 23),
          note: 'Birthday dinner', merchant: 'Restaurant',
          tagIds: [_tagDiscretionary]),
      tx(350, inc, _catFreelance, _checking, md(2, 24),
          note: 'Website mockup', merchant: 'Freelance client',
          assetId: _assetLaptop),
      tx(38, exp, _catFuel, _credit, md(2, 25),
          note: 'Gas fill-up', merchant: 'Gas station',
          assetId: _assetCar, tagIds: [_tagEssential]),
      tx(76, exp, _catClothes, _credit, md(2, 26),
          note: 'Winter jacket', merchant: 'Clothing store',
          tagIds: [_tagDiscretionary]),
      tx(95, exp, _catGroceries, _credit, md(2, 28),
          note: 'Groceries', merchant: 'Supermarket',
          tagIds: [_tagEssential]),
      tx(180, exp, _catInsurance, _checking, md(2, 28),
          note: 'Car insurance', merchant: 'Insurance company',
          assetId: _assetCar, tagIds: [_tagEssential, _tagRecurring]),

      // ═════════════════════════════════════════════════════════════
      // 1 MONTH AGO
      // ═════════════════════════════════════════════════════════════
      tx(4200, inc, _catSalary, _checking, md(1, 1),
          note: 'Monthly salary', merchant: 'Employer',
          tagIds: [_tagRecurring]),
      tx(1450, exp, _catRent, _checking, md(1, 1),
          note: 'Monthly rent', merchant: 'Landlord',
          tagIds: [_tagEssential, _tagRecurring]),
      tx(850, inc, _catFreelance, _checking, md(1, 2),
          note: 'Logo design project', merchant: 'Freelance client',
          assetId: _assetLaptop),
      tx(105, exp, _catGroceries, _credit, md(1, 3),
          note: 'Groceries', merchant: 'Supermarket',
          tagIds: [_tagEssential]),
      tx(15.99, exp, _catEntertainment, _credit, md(1, 5),
          note: 'Streaming subscription', merchant: 'Streaming service',
          tagIds: [_tagRecurring, _tagDiscretionary]),
      tx(38, exp, _catRestaurants, _credit, md(1, 6),
          note: 'Lunch with coworker', merchant: 'Bistro',
          tagIds: [_tagDiscretionary]),
      tx(6.80, exp, _catRestaurants, _cash, md(1, 7),
          note: 'Morning coffee', merchant: 'Coffee shop',
          tagIds: [_tagDiscretionary]),
      tx(2.75, exp, _catPublicTransit, _cash, md(1, 8),
          note: 'Subway ride', merchant: 'Transit'),
      tx(45, exp, _catFuel, _credit, md(1, 9),
          note: 'Gas fill-up', merchant: 'Gas station',
          assetId: _assetCar, tagIds: [_tagEssential]),
      tx(10.99, exp, _catEntertainment, _credit, md(1, 10),
          note: 'Music subscription', merchant: 'Music service',
          tagIds: [_tagRecurring, _tagDiscretionary]),
      tx(24, exp, _catHealth, _cash, md(1, 11),
          note: 'Cold medicine', merchant: 'Pharmacy'),
      tx(118, exp, _catUtilities, _checking, md(1, 12),
          note: 'Electric bill', merchant: 'Electric company',
          tagIds: [_tagEssential, _tagRecurring]),
      tx(98, exp, _catGroceries, _credit, md(1, 14),
          note: 'Weekly groceries', merchant: 'Grocery store',
          tagIds: [_tagEssential]),
      tx(35, exp, _catHealth, _credit, md(1, 15),
          note: 'Gym membership', merchant: 'Gym',
          tagIds: [_tagRecurring]),
      tx(18, exp, _catDelivery, _credit, md(1, 16),
          note: 'Pizza delivery', merchant: 'Delivery app',
          tagIds: [_tagDiscretionary]),
      tx(79, exp, _catElectronics, _credit, md(1, 17),
          note: 'Wireless headphones', merchant: 'Electronics store',
          assetId: _assetHeadphones),
      tx(65, exp, _catUtilities, _checking, md(1, 20),
          note: 'Internet bill', merchant: 'Internet provider',
          tagIds: [_tagEssential, _tagRecurring]),
      tx(82, exp, _catGroceries, _credit, md(1, 21),
          note: 'Groceries', merchant: 'Grocery store',
          tagIds: [_tagEssential]),
      tx(62, exp, _catRestaurants, _credit, md(1, 22),
          note: 'Anniversary dinner', merchant: 'Restaurant',
          tagIds: [_tagDiscretionary]),
      tx(28, exp, _catEntertainment, _cash, md(1, 23),
          note: 'Movie night', merchant: 'Cinema',
          tagIds: [_tagDiscretionary]),
      tx(120, exp, _catElectronics, _credit, md(1, 24),
          note: 'Camera lens filter', merchant: 'Photo store',
          assetId: _assetCamera),
      tx(48, exp, _catFuel, _credit, md(1, 25),
          note: 'Gas fill-up', merchant: 'Gas station',
          assetId: _assetCar, tagIds: [_tagEssential]),
      tx(110, exp, _catGroceries, _credit, md(1, 27),
          note: 'Weekly groceries', merchant: 'Supermarket',
          tagIds: [_tagEssential]),
      tx(145, exp, _catInsurance, _checking, md(1, 28),
          note: 'Car insurance', merchant: 'Insurance company',
          assetId: _assetCar, tagIds: [_tagEssential, _tagRecurring]),

      // ═════════════════════════════════════════════════════════════
      // CURRENT MONTH (early fixed dates)
      // ═════════════════════════════════════════════════════════════
      tx(4200, inc, _catSalary, _checking, md(0, 1),
          note: 'Monthly salary', merchant: 'Employer',
          tagIds: [_tagRecurring]),
      tx(1450, exp, _catRent, _checking, md(0, 1),
          note: 'Monthly rent', merchant: 'Landlord',
          tagIds: [_tagEssential, _tagRecurring]),
      tx(97, exp, _catGroceries, _credit, md(0, 3),
          note: 'Groceries', merchant: 'Grocery store',
          tagIds: [_tagEssential]),
      tx(15.99, exp, _catEntertainment, _credit, md(0, 5),
          note: 'Streaming subscription', merchant: 'Streaming service',
          tagIds: [_tagRecurring, _tagDiscretionary]),
      tx(8.50, exp, _catRestaurants, _cash, md(0, 7),
          note: 'Coffee and sandwich', merchant: 'Cafe',
          tagIds: [_tagDiscretionary]),
      tx(65, exp, _catUtilities, _checking, md(0, 8),
          note: 'Internet bill', merchant: 'Internet provider',
          tagIds: [_tagEssential, _tagRecurring]),
      tx(45, exp, _catFuel, _credit, md(0, 9),
          note: 'Gas fill-up', merchant: 'Gas station',
          assetId: _assetCar, tagIds: [_tagEssential]),

      // ═════════════════════════════════════════════════════════════
      // RECENT STREAK (consecutive days relative to today)
      // ═════════════════════════════════════════════════════════════
      tx(10.99, exp, _catEntertainment, _credit, ago(9),
          note: 'Music subscription', merchant: 'Music service',
          tagIds: [_tagRecurring, _tagDiscretionary]),
      tx(84, exp, _catGroceries, _credit, ago(8),
          note: 'Weekly groceries', merchant: 'Supermarket',
          tagIds: [_tagEssential]),
      tx(112, exp, _catUtilities, _checking, ago(7),
          note: 'Electric bill', merchant: 'Electric company',
          tagIds: [_tagEssential, _tagRecurring]),
      tx(42, exp, _catRestaurants, _credit, ago(6),
          note: 'Dinner out', merchant: 'Restaurant',
          tagIds: [_tagDiscretionary]),
      tx(5.50, exp, _catRestaurants, _cash, ago(5),
          note: 'Afternoon coffee', merchant: 'Coffee shop',
          tagIds: [_tagDiscretionary]),
      tx(18, exp, _catTransport, _cash, ago(4),
          note: 'Ride to appointment', merchant: 'Rideshare'),
      tx(35, exp, _catHealth, _credit, ago(3),
          note: 'Gym membership', merchant: 'Gym',
          tagIds: [_tagRecurring]),
      tx(49, exp, _catEducation, _credit, ago(2),
          note: 'Online course', merchant: 'Learning platform',
          assetId: _assetLaptop),
      tx(25, exp, _catDelivery, _credit, ago(1),
          note: 'Sushi delivery', merchant: 'Delivery app',
          tagIds: [_tagDiscretionary]),
      tx(90, exp, _catGroceries, _credit, ago(0),
          note: 'Grocery run', merchant: 'Grocery store',
          tagIds: [_tagEssential]),
    ];

    // Filter out future dates (for current month when day hasn't arrived yet)
    return all.where((tx) => !tx.date.isAfter(now)).toList();
  }
}
