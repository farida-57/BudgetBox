import 'dart:convert';
import 'dart:typed_data';

import 'package:budgetbox/core/error/failure.dart';
import 'package:budgetbox/features/balances/data/datasources/balance_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adaptateur HTTP de test : renvoie une réponse préparée, sans réseau.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.statusCode, this.body);

  final int statusCode;
  final Object body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

BalanceApiDataSource buildDataSource(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'))
    ..httpClientAdapter = adapter;
  return BalanceApiDataSource(dio);
}

void main() {
  group('BalanceApiDataSource.getBalances', () {
    test('appelle GET /groups/:groupId/balances et lit la réponse', () async {
      final adapter = FakeHttpAdapter(200, {
        'groupId': 'g1',
        'currency': 'XOF',
        'balances': [
          {
            'userId': 'u1',
            'displayName': 'Awa',
            'balance': 6666,
            'isMember': true,
          },
          {
            'userId': 'u2',
            'displayName': 'Binta',
            'balance': -6666,
            'isMember': true,
          },
        ],
      });

      final result = await buildDataSource(adapter).getBalances('g1');

      expect(adapter.lastRequest?.method, 'GET');
      expect(adapter.lastRequest?.path, '/groups/g1/balances');
      expect(result.balances.map((b) => b.balance).toList(), [6666, -6666]);
    });

    test(
      'convertit un refus 403 en ServerFailure via le mapping central',
      () async {
        final adapter = FakeHttpAdapter(403, {
          'error': {
            'code': 'FORBIDDEN',
            'message': 'Vous n\'êtes pas membre de ce groupe',
            'details': <Object>[],
          },
        });

        await expectLater(
          buildDataSource(adapter).getBalances('g1'),
          throwsA(
            isA<ServerFailure>()
                .having((f) => f.statusCode, 'statusCode', 403)
                .having((f) => f.code, 'code', 'FORBIDDEN')
                .having(
                  (f) => f.message,
                  'message',
                  'Vous n\'êtes pas membre de ce groupe',
                ),
          ),
        );
      },
    );

    test('refuse une réponse dont le montant n\'est pas entier', () async {
      final adapter = FakeHttpAdapter(200, {
        'groupId': 'g1',
        'currency': 'XOF',
        'balances': [
          {'userId': 'u1', 'displayName': 'Awa', 'balance': 10.5},
        ],
      });

      await expectLater(
        buildDataSource(adapter).getBalances('g1'),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });

  group('BalanceApiDataSource.getSettlementSuggestions', () {
    test(
      'appelle GET /groups/:groupId/settlement-suggestions et lit les transferts',
      () async {
        final adapter = FakeHttpAdapter(200, {
          'groupId': 'g1',
          'currency': 'XOF',
          'suggestions': [
            {
              'fromUserId': 'u2',
              'fromDisplayName': 'Binta',
              'toUserId': 'u1',
              'toDisplayName': 'Awa',
              'amount': 3333,
            },
          ],
        });

        final result = await buildDataSource(
          adapter,
        ).getSettlementSuggestions('g1');

        expect(adapter.lastRequest?.method, 'GET');
        expect(adapter.lastRequest?.path, '/groups/g1/settlement-suggestions');
        expect(result.single.amount, 3333);
      },
    );
  });
}
