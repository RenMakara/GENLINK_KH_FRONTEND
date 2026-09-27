import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/config/app_config.dart';
import 'package:genlink_frontend/core/utils/media_url_resolver.dart';

void main() {
  group('MediaUrlResolver', () {
    test('handles null, empty, and whitespace strings safely', () {
      expect(MediaUrlResolver.resolve(null), equals(''));
      expect(MediaUrlResolver.resolve(''), equals(''));
      expect(MediaUrlResolver.resolve('   '), equals(''));
    });

    test('preserves absolute CloudFront CDN URLs', () {
      const cloudfrontUrl =
          'https://d123456abcdef8.cloudfront.net/images/banner.webp';
      expect(MediaUrlResolver.resolve(cloudfrontUrl), equals(cloudfrontUrl));
    });

    test('preserves standard absolute HTTP and HTTPS URLs', () {
      const httpsUrl = 'https://images.unsplash.com/photo-12345';
      const httpUrl = 'http://example.com/sample.png';
      expect(MediaUrlResolver.resolve(httpsUrl), equals(httpsUrl));
      expect(MediaUrlResolver.resolve(httpUrl), equals(httpUrl));
    });

    test('normalizes legacy DigitalOcean CDN URL to direct spaces endpoint', () {
      const legacyUrl =
          'https://genlink-space.sgp1.cdn.digitaloceanspaces.com/posts/img.jpg';
      const expectedUrl =
          'https://genlink-space.sgp1.digitaloceanspaces.com/posts/img.jpg';
      expect(MediaUrlResolver.resolve(legacyUrl), equals(expectedUrl));
    });

    test('prefixes relative paths with AppConfig.apiBaseUrl', () {
      expect(
        MediaUrlResolver.resolve('/api/v1/files/avatar.png'),
        equals('${AppConfig.apiBaseUrl}/api/v1/files/avatar.png'),
      );
      expect(
        MediaUrlResolver.resolve('uploads/images/photo.jpg'),
        equals('${AppConfig.apiBaseUrl}/uploads/images/photo.jpg'),
      );
    });

    test('preserves Flutter asset paths', () {
      const assetPath = 'assets/images/default_avatar.png';
      expect(MediaUrlResolver.resolve(assetPath), equals(assetPath));
    });

    test('preserves local filesystem paths', () {
      const fileUri = 'file:///var/mobile/Containers/Data/photo.jpg';
      const androidPath = '/data/user/0/com.genlink.app/cache/camera.jpg';
      const windowsPath = r'C:\Users\User\Pictures\img.png';

      expect(MediaUrlResolver.resolve(fileUri), equals(fileUri));
      expect(MediaUrlResolver.resolve(androidPath), equals(androidPath));
      expect(MediaUrlResolver.resolve(windowsPath), equals(windowsPath));
    });

    test('correctly identifies asset paths with isAsset', () {
      expect(MediaUrlResolver.isAsset('assets/icons/logo.png'), isTrue);
      expect(MediaUrlResolver.isAsset('https://example.com/logo.png'), isFalse);
      expect(MediaUrlResolver.isAsset(null), isFalse);
    });

    test('correctly identifies local files with isLocalFile', () {
      expect(MediaUrlResolver.isLocalFile('file:///tmp/pic.jpg'), isTrue);
      expect(MediaUrlResolver.isLocalFile('/storage/emulated/0/DCIM/pic.jpg'), isTrue);
      expect(MediaUrlResolver.isLocalFile(r'C:\Users\pic.jpg'), isTrue);
      expect(MediaUrlResolver.isLocalFile('https://example.com/pic.jpg'), isFalse);
      expect(MediaUrlResolver.isLocalFile(null), isFalse);
    });

    test('correctly identifies network URLs with isNetworkUrl and isRemoteUrl', () {
      expect(MediaUrlResolver.isNetworkUrl('https://example.com/img.jpg'), isTrue);
      expect(MediaUrlResolver.isRemoteUrl('http://example.com/img.jpg'), isTrue);
      expect(MediaUrlResolver.isRemoteUrl('/uploads/img.jpg'), isTrue);
      expect(MediaUrlResolver.isRemoteUrl('assets/img.jpg'), isFalse);
      expect(MediaUrlResolver.isRemoteUrl(null), isFalse);
    });
  });
}
