import 'package:flutter/material.dart';
import 'package:taxi_driver/model/LDBaseResponse.dart';
import 'package:taxi_driver/model/PaymentCardModel.dart';
import 'package:taxi_driver/model/WalletDetailModel.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';

class WalletService {
  /// Save a new payment card
  Future<bool> saveCard({
    required String cardHolderName,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required int userId,
  }) async {
    try {
      Map<String, dynamic> request = {
        'card_holder_name': cardHolderName,
        'card_number': cardNumber,
        'expiry_date': expiryDate,
        'cvv': cvv,
        'user_id': userId,
      };

      LDBaseResponse response = await savePaymentCard(request: request);
      if (response.message != null) {
        toast(response.message);
        return true;
      }
      return false;
    } catch (e) {
      toast('Error occurred: ${e.toString()}');
      debugPrint('Error in savePaymentCard: ${e.toString()}');
      return false;
    }
  }

  /// Get all payment cards for the current user
  Future<List<PaymentCardModel>> getAllPaymentCards() async {
    try {
      return await getPaymentCards();
    } catch (e) {
      debugPrint('Error in getAllPaymentCards: ${e.toString()}');
      return [];
    }
  }

  /// Delete payment card
  Future<bool> deleteCard(int cardId) async {
    try {
      LDBaseResponse response = await deletePaymentCard(cardId: cardId);
      if (response.message != null) {
        toast(response.message);
        return true;
      }
      return false;
    } catch (e) {
      toast('Error occurred: ${e.toString()}');
      debugPrint('Error in deleteCard: ${e.toString()}');
      return false;
    }
  }

  /// Add money to wallet
  Future<bool> addMoney({
    required int cardId,
    required double amount,
    String? description,
  }) async {
    try {
      Map<String, dynamic> request = {
        'card_id': cardId,
        'amount': amount,
        'description': description ?? 'Added via card',
      };

      LDBaseResponse response = await addMoneyToWallet(request: request);
      if (response.message != null) {
        toast(response.message);
        return true;
      }
      return false;
    } catch (e) {
      toast('Error occurred: ${e.toString()}');
      debugPrint('Error in addMoneyToWallet: ${e.toString()}');
      return false;
    }
  }

  /// Get wallet details
  Future<WalletDetailModel?> getWalletDetails() async {
    try {
      return await walletDetailApi();
    } catch (e) {
      debugPrint('Error in getWalletDetails: ${e.toString()}');
      return null;
    }
  }
}
