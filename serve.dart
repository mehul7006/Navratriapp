import 'dart:io';
import 'dart:convert';

void main() async {
  final dir = Directory('build/web');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 9001);
  print('Serving build/web at http://localhost:9001');
  await for (final request in server) {
    var path = request.uri.path;
    if (path == '/') path = '/index.html';
    final file = File('${dir.path}${path.replaceAll('/', Platform.pathSeparator)}');
    if (await file.exists()) {
      final ext = file.path.split('.').last;
      final types = <String, String>{
        'html': 'text/html',
        'js': 'application/javascript',
        'css': 'text/css',
        'png': 'image/png',
        'jpg': 'image/jpeg',
        'svg': 'image/svg+xml',
        'ico': 'image/x-icon',
        'json': 'application/json',
        'woff': 'font/woff',
        'woff2': 'font/woff2',
        'ttf': 'font/ttf',
      };
      response.headers.contentType = ContentType.parse(types[ext] ?? 'application/octet-stream');
      await file.openRead().pipe(response);
    } else {
      final indexFile = File('${dir.path}${Platform.pathSeparator}index.html');
      response.headers.contentType = ContentType.html;
      await indexFile.openRead().pipe(response);
    }
  }
}
