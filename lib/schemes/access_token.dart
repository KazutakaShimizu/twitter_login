import 'package:twitter_login/src/utils.dart';

/// The access token for Twitter API.
class AccessToken {
  final String? authToken;
  final String? authTokenSecret;
  final String? userId;
  final String? screenName;

  AccessToken(Map<String, dynamic> params)
      : this.authToken = params.get<String>('oauth_token'),
        this.authTokenSecret = params.get<String>('oauth_token_secret'),
        this.userId = params.get<String>('user_id'),
        this.screenName = params.get<String>('screen_name');

  static Future<AccessToken> getAccessToken(
    String apiKey,
    String apiSecretKey,
    Map<String, String> queries,
  ) async {
    final authParams = requestHeader(
      apiKey: apiKey,
      oauthToken: queries['oauth_token'],
      oauthVerifier: queries['oauth_verifier'],
    );
    final params = await httpPost(
      ACCESS_TOKEN_URI,
      authParams,
      apiKey,
      apiSecretKey,
    );
    if (params == null) {
      throw Exception();
    }
    return AccessToken(params);
  }

  static Future<AccessToken> getAccessTokenV2(
    String redirectURI,
    Map<String, String> queries,
  ) async {
    final body = {
      "grant_type": "authorization_code",
      "client_id": "QTdJUlBhTjFSb05pMnU0U2d0aUc6MTpjaQ",
      "redirect_uri": redirectURI,
      "code_verifier": "challenge",
    };
    print(body);
    final params = await httpPostV2(
      "https://api.twitter.com/2/oauth2/token",
      body,
    );
    if (params == null) {
      throw Exception();
    }
    return AccessToken(params);
  }
}
