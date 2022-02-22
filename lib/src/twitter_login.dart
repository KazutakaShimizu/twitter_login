import 'dart:async';
import 'package:twitter_login/schemes/access_token_v2.dart';
import 'package:twitter_login/schemes/authorization_code_v2.dart';

class TwitterLogin {
  /// Oauth Client Id
  final String clientId;

  /// Callback URL
  final String redirectURI;

  /// constructor
  TwitterLogin({
    required this.clientId,
    required this.redirectURI,
  }) {
    if (this.clientId.isEmpty) {
      throw Exception('clientId is empty');
    }
    if (this.redirectURI.isEmpty) {
      throw Exception('redirectURI is empty');
    }
  }

  Future<AccessTokenV2> loginV2({bool forceLogin = false}) async {
    final authorizationCode = await AuthorizationCodeV2.getAuthorizationCode(
        clientId: clientId, redirectURI: redirectURI);

    return await AccessTokenV2.getAccessToken(
      clientId: clientId,
      authorizationCode: authorizationCode.code,
      codeVerifier: authorizationCode.codeVerifier,
      redirectURI: redirectURI,
    );
  }
}
