// import 'package:flutter_test/flutter_test.dart';
// import 'package:http/http.dart' as http;
//
// void main() {
//   test('Inspect live GenLink Search API', () async {
//     const urls = [
//       'https://api.genlink.enat.online/api/v1/search?q=enat&type=ALL',
//       'https://api.genlink.enat.online/api/v1/search?q=te&type=ALL',
//       'https://api.genlink.enat.online/api/v1/search?q=Chansela&type=PEOPLE',
//       'https://api.genlink.enat.online/api/v1/search?q=%E1%9E%9F%E1%9E%BB%E1%9E%81%E1%9E%93%E1%9F%82&type=ALL',
//       'https://api.genlink.enat.online/api/v1/search?q=randomnonexistentuserxyz123&type=ALL',
//     ];
//
//     for (final url in urls) {
//       // ignore: avoid_print
//       print('\n==================================================');
//       // ignore: avoid_print
//       print('TESTING URL: $url');
//       try {
//         final response = await http.get(Uri.parse(url)).timeout(
//           const Duration(seconds: 15),
//         );
//         // ignore: avoid_print
//         print('HTTP Status: ${response.statusCode}');
//         // ignore: avoid_print
//         print('Headers: ${response.headers}');
//         // ignore: avoid_print
//         print('Body: ${response.body}');
//       } catch (e) {
//         // ignore: avoid_print
//         print('Error calling $url: $e');
//       }
//     }
//   });
// }
