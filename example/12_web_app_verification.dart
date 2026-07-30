// ignore_for_file: file_names
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 12 — VERIFYING TELEGRAM MINI APP (WEB APP) DATA
// ============================================================================
//
// If you have a Telegram Mini App (a web page opened inside Telegram via a
// menu button or inline "Web App" button), it sends your backend an
// `initData` string containing the user's info, signed with your bot's
// token. You MUST verify this signature server-side before trusting any of
// it — otherwise anyone could forge a request claiming to be any user.
//
// This example is a minimal HTTP endpoint your Mini App's frontend would
// call right after launch, like:
//
//   fetch('/verify', { method: 'POST', body: Telegram.WebApp.initData })
//
// HOW TO RUN:
//   dart run example/12_web_app_verification.dart   (with a `.env` file)
// ============================================================================

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:ptgb/ptgb.dart';

Future<void> main() async {
  final bot = Bot();

  final server = await HttpServer.bind('0.0.0.0', 8080);
  log('Listening for Mini App verification requests on :8080/verify');

  await for (final request in server) {
    if (request.method != 'POST' || request.uri.path != '/verify') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      continue;
    }

    final initData = await utf8.decoder.bind(request).join();

    // This does the actual HMAC-SHA256 verification against your bot token.
    final parsed = bot.verifyWebAppInitData(initData);

    if (!parsed.isValid) {
      // Never trust unverified data — reject it outright.
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.write(jsonEncode({'error': 'invalid signature'}));
      await request.response.close();
      continue;
    }

    // Safe to use now — `parsed.user` is the verified Telegram user object.
    final user = parsed.user;
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'ok': true,
        'userId': user?['id'],
        'firstName': user?['first_name'],
        'authenticatedAt': parsed.authDate?.toIso8601String(),
      }),);
    await request.response.close();
  }
}
