import 'package:budgetbox/features/balances/data/models/group_balances_model.dart';
import 'package:budgetbox/features/balances/data/models/settlement_suggestion_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _balancesJson(Object balance) => {
  'groupId': 'g1',
  'currency': 'XOF',
  'balances': [
    {
      'userId': 'u1',
      'displayName': 'Awa',
      'balance': balance,
      'isMember': true,
    },
  ],
};

void main() {
  group('GroupBalancesModel.fromJson', () {
    test('lit les soldes entiers et le statut de membre', () {
      final model = GroupBalancesModel.fromJson({
        'groupId': 'g1',
        'currency': 'XOF',
        'balances': [
          {
            'userId': 'u1',
            'displayName': 'Awa',
            'balance': 2500,
            'isMember': true,
          },
          {
            'userId': 'u2',
            'displayName': 'Diane',
            'balance': -2500,
            'isMember': false,
          },
        ],
      });

      expect(model.groupId, 'g1');
      expect(model.currency, 'XOF');
      expect(model.balances.map((b) => b.balance).toList(), [2500, -2500]);
      expect(model.balanceOf('u1')?.isCreditor, isTrue);
      expect(model.balanceOf('u2')?.isDebtor, isTrue);
      expect(model.balanceOf('u2')?.isMember, isFalse);
      expect(model.balanceOf('inconnu'), isNull);
      expect(model.isAllSettled, isFalse);
    });

    test('refuse un solde décimal au lieu de l\'arrondir', () {
      expect(
        () => GroupBalancesModel.fromJson(_balancesJson(3333.5)),
        throwsFormatException,
      );
      expect(
        () => GroupBalancesModel.fromJson(_balancesJson(3333.0)),
        throwsFormatException,
      );
    });

    test('refuse un solde envoyé sous forme de texte', () {
      expect(
        () => GroupBalancesModel.fromJson(_balancesJson('3333')),
        throwsFormatException,
      );
    });

    test('refuse une réponse sans liste de soldes', () {
      expect(
        () => GroupBalancesModel.fromJson({'groupId': 'g1'}),
        throwsFormatException,
      );
    });
  });

  group('SettlementSuggestionModel.listFromResponse', () {
    test('lit les transferts proposés', () {
      final suggestions = SettlementSuggestionModel.listFromResponse({
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

      expect(suggestions, hasLength(1));
      expect(suggestions.single.fromDisplayName, 'Binta');
      expect(suggestions.single.toDisplayName, 'Awa');
      expect(suggestions.single.amount, 3333);
    });

    test('accepte une liste vide', () {
      expect(
        SettlementSuggestionModel.listFromResponse({'suggestions': <Object>[]}),
        isEmpty,
      );
    });

    test('refuse un montant décimal', () {
      expect(
        () => SettlementSuggestionModel.listFromResponse({
          'suggestions': [
            {
              'fromUserId': 'u2',
              'fromDisplayName': 'Binta',
              'toUserId': 'u1',
              'toDisplayName': 'Awa',
              'amount': 3333.5,
            },
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
