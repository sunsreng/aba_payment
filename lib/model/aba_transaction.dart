import 'dart:convert';

import 'package:aba_payment/enumeration.dart';
import 'package:aba_payment/extension.dart';
import 'package:aba_payment/model/aba_mechant.dart';
import 'package:aba_payment/service/aba_client_helper.dart';
import 'package:dio/dio.dart';

import 'aba_server_response.dart';

class ABATransaction {
  ABAMerchant merchant;
  String tranID;
  double amount;
  List<Map<String, dynamic>> items;
  String hash;
  String firstname;
  String lastname;
  String phone;
  String email;
  String returnUrl;
  String continueSuccessUrl;
  String returnParams;
  String phoneCountryCode;
  String preAuth;
  AcceptPaymentOption paymentOption;
  double shipping;

  ABATransaction({
    this.merchant,
    this.tranID,
    this.amount,
    this.items,
    this.hash,
    this.firstname,
    this.lastname,
    this.phone,
    this.email,
    this.returnUrl,
    this.continueSuccessUrl,
    this.returnParams,
    this.phoneCountryCode,
    this.preAuth,
    this.paymentOption,
    this.shipping,
  });

  factory ABATransaction.instance(ABAMerchant merchant) {
    return ABATransaction(
      merchant: merchant,
      tranID: "${(DateTime.now()).microsecondsSinceEpoch}",
      amount: 0.00,
      items: [],
      firstname: "",
      lastname: "",
      phone: "",
      email: "",
      paymentOption: AcceptPaymentOption.abapay_deeplink,
      shipping: 0.00,
    );
  }

  /// ### [ABATransaction.fromMap]
  factory ABATransaction.fromMap(Map<String, dynamic> map) {
    return ABATransaction(
      merchant: ABAMerchant.fromMap(map),
      tranID: map["tran_id"],
      amount: double.tryParse("${map["amount"]}"),
      items: List.from(map['items'] ?? []).map((e) => Map.from(e)).toList(),
      hash: map["hash"],
      firstname: map["firstname"],
      lastname: map["lastname"],
      phone: map["phone"],
      email: map["email"],
      returnUrl: map["return_url"],
      continueSuccessUrl: map["continue_success_url"],
      returnParams: map["return_params"],
      phoneCountryCode: map["phone_country_code"],
      preAuth: "PreAuth",
      paymentOption: map["payment_option"].toString().toAcceptPaymentOption,
      shipping: map["shipping"] ?? "",
    );
  }

  /// ### [toMap]
  /// [return] map object
  Map<String, dynamic> toMap() {
    String _items = base64Encode(utf8.encode("$items"));
    var map = {
      "tran_id": tranID,
      "amount": "$amount",
      "items": _items,
      "hash": ABAClientHelper(merchant).getHash(
          tranID: tranID, amount: amount, items: _items, shipping: "$shipping"),
      "firstname": firstname,
      "lastname": lastname,
      "phone": phone,
      "email": email,
      "return_url": returnUrl,
      "continue_success_url": continueSuccessUrl ?? "",
      "return_params": returnParams ?? "",
      // "return_params": {"tran_id": tranID, "status": 0},
      "phone_country_code": phoneCountryCode ?? "855",
      "PreAuth": preAuth,
      "payment_option": paymentOption.toText,
      "shipping": "$shipping",
    };
    return map;
  }

  /// ## `create transaction`
  ///
  Future<ABAServerResponse> create() async {
    var res = ABAServerResponse(status: 11);
    Map<String, dynamic> map = this.toMap();
    FormData form = FormData.fromMap(map);
    try {
      var helper = ABAClientHelper(merchant);
      Response<String> response = await helper.getDio().post("/", data: form);
      try {
        var map = json.decode(response.data) as Map<String, dynamic>;
        res = ABAServerResponse.fromMap(map);
        return res;
      } catch (e) {
        res.status = 0;
        res.description = "success";
        res.rawcontent = response.data;
        return res;
      }
    } catch (error, stacktrace) {
      print("Exception occured: $error stackTrace: $stacktrace");
      res.description = ABAClientHelper.handleResponseError(error);
    }
    return ABAServerResponse();
  }

  /// ## check transaction
  ///
  Future<ABAServerResponse> check() async {
    var res = ABAServerResponse(status: 11);
    FormData form = FormData.fromMap({
      "tran_id": tranID,
      "hash": ABAClientHelper(merchant).getHash(tranID: tranID),
    });
    var helper = ABAClientHelper(merchant);
    try {
      Response<String> response =
          await helper.getDio().post("/check/transaction/", data: form);
      var map = json.decode(response.data) as Map<String, dynamic>;
      res = ABAServerResponse.fromMap(map);
      return res;
    } catch (error, stacktrace) {
      print("Exception occured: $error stackTrace: $stacktrace");
      res.description = ABAClientHelper.handleResponseError(error);
    }
    return ABAServerResponse();
  }
}
