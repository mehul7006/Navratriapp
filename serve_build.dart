import 'dart:io';

void main() async {
  final buildDir = Directory('build${Platform.pathSeparator}web');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 9001);
  print('Serving at http://localhost:9001');
  await for (final request in server) {
    final res = request.response;
    var reqPath = request.uri.path;
    if (reqPath == '/') reqPath = '/index.html';
    final file = File('${buildDir.path}${reqPath.replaceAll('/', Platform.pathSeparator)}');
    if (await file.exists()) {
      final ext = file.path.split('.').last;
      final types = {
        'html': 'text/html', 'js': 'application/javascript', 'css': 'text/css',
        'png': 'image/png', 'jpg': 'image/jpeg', 'svg': 'image/svg+xml',
        'ico': 'image/x-icon', 'json': 'application/json',
        'woff': 'font/woff', 'woff2': 'font/woff2', 'ttf': 'font/ttf',
      };
      res.headers.contentType = ContentType.parse(types[ext] ?? 'application/octet-stream');
      await file.openRead().pipe(res);
    } else {
      final fallback = File('${buildDir.path}${Platform.pathSeparator}index.html');
      if (await fallback.exists()) {
        res.headers.contentType = ContentType.html;
        await fallback.openRead().pipe(res);
      } else {
        res.statusCode = 404;
        await res.close();
      }
    }
  }
}
