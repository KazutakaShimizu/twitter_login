import 'package:twitter_login/src/utils.dart';

/// The access token for Twitter API.
class AccessTokenV2 {
  final String? tokenType;
  final int? expiresIn;
  final String? accessToken;
  final String? scope;

  AccessTokenV2(Map<String, dynamic> params)
      : this.tokenType = params.get<String>('token_type'),
        this.expiresIn = params.get<int>('expires_in'),
        this.accessToken = params.get<String>('access_token'),
        this.scope = params.get<String>('scope');

  Map<String, dynamic> toJson() {
    return {
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      'accessToken': accessToken,
      'scope': scope,
    };
  }

  static Future<AccessTokenV2> getAccessToken({
    required String authorizationCode,
    required String redirectURI,
  }) async {
    final body = {
      "grant_type": "authorization_code",
      "client_id": "QTdJUlBhTjFSb05pMnU0U2d0aUc6MTpjaQ",
      "code": authorizationCode,
      "redirect_uri": redirectURI,
      "code_verifier": "challenge",
    };
    final params = await httpPostV2(
      "https://api.twitter.com/2/oauth2/token",
      body,
    );
    print("############");
    print(params);
    print(params);
    if (params == null) {
      throw Exception('Unexpected Response');
    }
    return AccessTokenV2(params);
  }
}
