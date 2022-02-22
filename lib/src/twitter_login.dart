import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:twitter_login/entity/auth_result.dart';
import 'package:twitter_login/entity/user.dart';
import 'package:twitter_login/schemes/access_token.dart';
import 'package:twitter_login/schemes/access_token_v2.dart';
import 'package:twitter_login/schemes/request_token.dart';
import 'package:twitter_login/src/auth_browser.dart';
import 'package:twitter_login/src/exception.dart';

/// The status after a Twitter login flow has completed.
enum TwitterLoginStatus {
  /// The login was successful and the user is now logged in.
  loggedIn,

  /// The user cancelled the login flow.
  cancelledByUser,

  /// The Twitter login completed with an error
  error,
}

///
class TwitterLogin {
  /// Consumer API key
  final String apiKey;

  /// Consumer API secret key
  final String apiSecretKey;

  /// Callback URL
  final String redirectURI;

  static const _channel = const MethodChannel('twitter_login');
  static final _eventChannel = EventChannel('twitter_login/event');
  static final Stream<dynamic> _eventStream =
      _eventChannel.receiveBroadcastStream();

  /// constructor
  TwitterLogin({
    required this.apiKey,
    required this.apiSecretKey,
    required this.redirectURI,
  });

  /// Logs the user
  /// Forces the user to enter their credentials to ensure the correct users account is authorized.
  Future<AuthResult> login({bool forceLogin = false}) async {
    String? resultURI;
    RequestToken requestToken;
    try {
      requestToken = await RequestToken.getRequestToken(
        apiKey,
        apiSecretKey,
        redirectURI,
        forceLogin,
      );
    } on Exception {
      throw PlatformException(
        code: "400",
        message: "Failed to generate request token.",
        details: "Please check your APIKey or APISecret.",
      );
    }

    final uri = Uri.parse(redirectURI);
    final completer = Completer<String?>();
    late StreamSubscription subscribe;

    if (Platform.isAndroid) {
      await _channel.invokeMethod('setScheme', uri.scheme);
      subscribe = _eventStream.listen((data) async {
        if (data['type'] == 'url') {
          if (!completer.isCompleted) {
            completer.complete(data['url']?.toString());
          } else {
            throw CanceledByUserException();
          }
        }
      });
    }

    final authBrowser = AuthBrowser(
      onClose: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    try {
      if (Platform.isIOS) {
        /// Login to Twitter account with SFAuthenticationSession or ASWebAuthenticationSession.
        resultURI =
            await authBrowser.doAuth(requestToken.authorizeURI, uri.scheme);
      } else if (Platform.isAndroid) {
        // Login to Twitter account with chrome_custom_tabs.
        final success =
            await authBrowser.open(requestToken.authorizeURI, uri.scheme);
        if (!success) {
          throw PlatformException(
            code: '200',
            message:
                'Could not open browser, probably caused by unavailable custom tabs.',
          );
        }
        resultURI = await completer.future;
        subscribe.cancel();
      } else {
        throw PlatformException(
          code: '100',
          message: 'Not supported by this os.',
        );
      }

      // The user closed the browser.
      if (resultURI?.isEmpty ?? true) {
        throw CanceledByUserException();
      }

      final queries = Uri.splitQueryString(Uri.parse(resultURI!).query);
      if (queries['error'] != null) {
        throw Exception('Error Response: ${queries['error']}');
      }

      // The user cancelled the login flow.
      if (queries['denied'] != null) {
        throw CanceledByUserException();
      }

      final token = await AccessToken.getAccessToken(
        apiKey,
        apiSecretKey,
        queries,
      );

      if ((token.authToken?.isEmpty ?? true) ||
          (token.authTokenSecret?.isEmpty ?? true)) {
        return AuthResult(
          authToken: token.authToken,
          authTokenSecret: token.authTokenSecret,
          status: TwitterLoginStatus.error,
          errorMessage: 'Failed',
          user: null,
        );
      }

      return AuthResult(
        authToken: token.authToken,
        authTokenSecret: token.authTokenSecret,
        status: TwitterLoginStatus.loggedIn,
        errorMessage: null,
        user: await User.getUserData(
          apiKey,
          apiSecretKey,
          token.authToken!,
          token.authTokenSecret!,
        ),
      );
    } on CanceledByUserException {
      return AuthResult(
        authToken: null,
        authTokenSecret: null,
        status: TwitterLoginStatus.cancelledByUser,
        errorMessage: 'The user cancelled the login flow.',
        user: null,
      );
    } catch (error) {
      return AuthResult(
        authToken: null,
        authTokenSecret: null,
        status: TwitterLoginStatus.error,
        errorMessage: error.toString(),
        user: null,
      );
    }
  }

  Future<AccessTokenV2> loginV2({bool forceLogin = false}) async {
    String? resultURI;
    // RequestToken requestToken;
    // try {
    //   requestToken = await RequestToken.getRequestToken(
    //     apiKey,
    //     apiSecretKey,
    //     redirectURI,
    //     forceLogin,
    //   );
    // } on Exception {
    //   throw PlatformException(
    //     code: "400",
    //     message: "Failed to generate request token.",
    //     details: "Please check your APIKey or APISecret.",
    //   );
    // }
    final uri = Uri.parse(redirectURI);
    final completer = Completer<String?>();
    late StreamSubscription subscribe;

    if (Platform.isAndroid) {
      await _channel.invokeMethod('setScheme', uri.scheme);
      subscribe = _eventStream.listen((data) async {
        if (data['type'] == 'url') {
          if (!completer.isCompleted) {
            completer.complete(data['url']?.toString());
          } else {
            throw CanceledByUserException();
          }
        }
      });
    }

    final authBrowser = AuthBrowser(
      onClose: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    var authorizeURI =
        'https://twitter.com/i/oauth2/authorize?response_type=code&client_id=QTdJUlBhTjFSb05pMnU0U2d0aUc6MTpjaQ&redirect_uri=$redirectURI&scope=users.read+tweet.read+follows.read&state=1878602977447.802&code_challenge=challenge&code_challenge_method=plain';

    if (Platform.isIOS) {
      /// Login to Twitter account with SFAuthenticationSession or ASWebAuthenticationSession.
      resultURI = await authBrowser.doAuth(authorizeURI, uri.scheme);
    } else if (Platform.isAndroid) {
      // Login to Twitter account with chrome_custom_tabs.
      final success = await authBrowser.open(authorizeURI, uri.scheme);
      if (!success) {
        throw PlatformException(
          code: '200',
          message:
              'Could not open browser, probably caused by unavailable custom tabs.',
        );
      }
      resultURI = await completer.future;
      subscribe.cancel();
    } else {
      throw PlatformException(
        code: '100',
        message: 'Not supported by this os.',
      );
    }
    print('resultURI: ' + resultURI.toString());

    // The user closed the browser.
    if (resultURI?.isEmpty ?? true) {
      throw CanceledByUserException();
    }

    final queries = Uri.splitQueryString(Uri.parse(resultURI!).query);
    if (queries['error'] != null) {
      throw Exception('Error Response: ${queries['error']}');
    }

    // The user cancelled the login flow.
    if (queries['denied'] != null) {
      throw CanceledByUserException();
    }

    final authorizationCode = queries['code'];
    if (authorizationCode == null) {
      throw Exception('Error: No authorization code found');
    }

    return await AccessTokenV2.getAccessToken(
      authorizationCode: authorizationCode,
      redirectURI: redirectURI,
    );
  }
}
