import 'package:flutter_test/flutter_test.dart';
import 'package:grid_master/services/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final start = DateTime(2026, 1, 1, 12);
  final nextDay = start.add(ReviewService.minTimeSinceFirstRound);

  Future<void> playRounds(int count, {required DateTime at}) async {
    for (int i = 0; i < count; i++) {
      await ReviewService.recordRoundFinished(now: at);
    }
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReviewService.resetSession();
  });

  test('not due before enough rounds were played', () async {
    await playRounds(ReviewService.minRoundsPlayed - 1, at: start);
    expect(await ReviewService.isDue(now: nextDay), isFalse);
  });

  test('not due on the day of the first round', () async {
    await playRounds(ReviewService.minRoundsPlayed, at: start);
    expect(
      await ReviewService.isDue(now: start.add(const Duration(hours: 23))),
      isFalse,
    );
  });

  test('due after enough rounds and time', () async {
    await playRounds(ReviewService.minRoundsPlayed, at: start);
    expect(await ReviewService.isDue(now: nextDay), isTrue);
  });

  test('not due on a cold start without a round this session', () async {
    await playRounds(ReviewService.minRoundsPlayed, at: start);
    ReviewService.resetSession();
    expect(await ReviewService.isDue(now: nextDay), isFalse);
  });

  test('never due again once requested', () async {
    SharedPreferences.setMockInitialValues({'reviewRequested': true});
    await playRounds(ReviewService.minRoundsPlayed, at: start);
    expect(await ReviewService.isDue(now: nextDay), isFalse);
  });
}
