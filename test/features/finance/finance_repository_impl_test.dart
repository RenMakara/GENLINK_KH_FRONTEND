import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:genlink_frontend/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRemoteDatasource extends Mock
    implements FinanceRemoteDatasource {}

void main() {
  test('repository exposes typed datasource results unchanged', () async {
    final remote = _MockFinanceRemoteDatasource();
    const dashboard = FinanceDashboardEntity(
      currency: FinanceCurrency.usd,
      month: FinanceMonthOverview(
        month: 8,
        year: 2026,
        currency: FinanceCurrency.usd,
        spent: 12.5,
      ),
      topCategories: [],
      saving: FinanceSavingProgress(
        currency: FinanceCurrency.usd,
        totalTarget: 100,
        totalSaved: 25,
        progressPercent: 25,
        activeGoals: 1,
      ),
      recentExpenses: [],
    );
    when(
      () => remote.getFinanceDashboard(FinanceCurrency.usd),
    ).thenAnswer((_) async => dashboard);

    final repository = FinanceRepositoryImpl(remote);
    final result = await repository.getFinanceDashboard();

    expect(result, same(dashboard));
    verify(() => remote.getFinanceDashboard(FinanceCurrency.usd)).called(1);
  });
}
