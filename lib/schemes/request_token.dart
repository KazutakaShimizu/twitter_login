import 'package:twitter_login/src/utils.dart';

/// The Request token for Twitter API.
class RequestToken {
  /// Oauth token
  final String _token;

  /// Oauth token secret
  final String _tokenSecret;

  /// Oauth callback confirmed
  final String _callbackConfirmed;

  /// authorize url
  final String _authorizeURI;

  /// Oauth token
  String get token => _token;

  /// Oauth token secret
  String get tokenSecret => _tokenSecret;

  /// Oauth callback confirmed
  String get callbackConfirmed => _callbackConfirmed;

  /// authorize url
  String get authorizeURI => _authorizeURI;

  /// constructor
  RequestToken(
    Map<String, dynamic> params,
    String authorizeURI,
  )   : this._token = params['oauth_token'],
        this._tokenSecret = params['oauth_token_secret'],
        this._callbackConfirmed = params['oauth_callback_confirmed'],
        this._authorizeURI = authorizeURI;

  /// Request user authorization token
  static Future<RequestToken> getRequestToken(
    String apiKey,
    String apiSecretKey,
    String redirectURI,
    bool forceLogin,
  ) async {
    final authParams = requestHeader(
      apiKey: apiKey,
      redirectURI: redirectURI,
    );
    final params = await httpPost(
      REQUEST_TOKEN_URL,
      authParams,
      apiKey,
      apiSecretKey,
    );

    // var authorizeURI = '$AUTHORIZE_URI?oauth_token=${params!['oauth_token']}';
    var authorizeURI =
        'https://twitter.com/i/oauth2/authorize?response_type=code&client_id=QTdJUlBhTjFSb05pMnU0U2d0aUc6MTpjaQ&redirect_uri=$redirectURI&scope=users.read+tweet.read+follows.read&state=1878602977447.802&code_challenge=challenge&code_challenge_method=plain';

    if (forceLogin) {
      authorizeURI += '&force_login=true';
    }
    final requestToken = RequestToken(params!, authorizeURI);
    if (requestToken.callbackConfirmed.toLowerCase() != 'true') {
      throw StateError('oauth_callback_confirmed mast be true');
    }

    return requestToken;
  }
}
