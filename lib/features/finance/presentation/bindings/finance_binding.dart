import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/finance_remote_datasource.dart';
import '../../data/repositories/finance_repository_impl.dart';
import '../../domain/repositories/finance_repository.dart';
import '../controllers/finance_controller.dart';
import '../controllers/ewallet_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/cash_flow_controller.dart';
import '../controllers/income_controller.dart';
import '../controllers/budget_controller.dart';
import '../controllers/saving_goal_controller.dart';
import '../controllers/finance_learning_controller.dart';

/// Binding for Finance dependencies.
///
/// The repository is permanent like the existing Profile repository. The
/// controller remains lazy so the dashboard request starts when the Finance
/// tab is first built rather than during application bootstrap.
class FinanceBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FinanceRepository>()) {
      Get.put<FinanceRepository>(
        FinanceRepositoryImpl(FinanceRemoteDatasource(Get.find<ApiClient>())),
        permanent: true,
      );
    }

    Get.lazyPut<FinanceController>(
      () => FinanceController(repository: Get.find<FinanceRepository>()),
      fenix: true,
    );
    Get.lazyPut<EWalletController>(
      () => EWalletController(
        Get.find<FinanceRepository>(),
        Get.find<FinanceController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<ExpenseController>(
      () => ExpenseController(
        repository: Get.find<FinanceRepository>(),
        financeController: Get.find<FinanceController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<CashFlowController>(
      () => CashFlowController(
        repository: Get.find<FinanceRepository>(),
        financeController: Get.find<FinanceController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<IncomeController>(
      () => IncomeController(
        repository: Get.find<FinanceRepository>(),
        financeController: Get.find<FinanceController>(),
        // An uninitialized lazy CashFlowController will load current data in
        // onInit when its screen is first opened.  Do not instantiate it here
        // just to refresh it after an Income mutation, which would otherwise
        // cause an unnecessary duplicate request.
        refreshCashFlow: () => Get.isPrepared<CashFlowController>()
            ? Future<void>.value()
            : Get.find<CashFlowController>().refresh(),
      ),
      fenix: true,
    );
    Get.lazyPut<BudgetController>(
      () => BudgetController(
        repository: Get.find<FinanceRepository>(),
        financeController: Get.find<FinanceController>(),
      ),
      fenix: true,
    );
    Get.lazyPut<SavingGoalController>(
      () => SavingGoalController(
        repository: Get.find<FinanceRepository>(),
        financeController: Get.find<FinanceController>(),
        // A wallet-funded contribution is confirmed by the backend first;
        // refresh the wallet snapshot only after that confirmation.
        refreshWalletState: () => Get.isRegistered<EWalletController>()
            ? Get.find<EWalletController>().loadInitial()
            : Future<void>.value(),
      ),
      fenix: true,
    );
    Get.lazyPut<FinanceLearningController>(
      () =>
          FinanceLearningController(repository: Get.find<FinanceRepository>()),
      fenix: true,
    );
  }
}
