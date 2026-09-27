import '../config/app_config.dart';

/// Centralized utility for resolving, normalizing, and classifying media URLs
/// across the GenLink application.
abstract final class MediaUrlResolver {
  /// Normalizes a media [rawUrl] into a well-formed URL or local path.
  ///
  /// - Returns `''` if [rawUrl] is null or blank.
  /// - Preserves asset paths (e.g., `assets/...`).
  /// - Preserves local filesystem paths.
  /// - Replaces legacy `.cdn.digitaloceanspaces.com` domains with `.digitaloceanspaces.com`.
  /// - Leaves valid absolute `http://` or `https://` URLs (including CloudFront CDN) untouched.
  /// - Resolves relative backend paths by prefixing [AppConfig.apiBaseUrl].
  static String resolve(String? rawUrl) {
    if (rawUrl == null) return '';
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    // Asset paths
    if (isAsset(trimmed)) {
      return trimmed;
    }

    // Legacy CDN domain correction
    String resolved = trimmed;
    if (resolved.contains('.cdn.digitaloceanspaces.com')) {
      resolved = resolved.replaceFirst(
        '.cdn.digitaloceanspaces.com',
        '.digitaloceanspaces.com',
      );
    }

    // Absolute HTTP / HTTPS URLs (e.g. CloudFront, S3, external CDNs)
    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return resolved;
    }

    // Local filesystem path check (Unix absolute `/`, Windows drive `C:\`, or `file://`)
    if (isLocalFile(resolved)) {
      return resolved;
    }

    // Relative backend path fallback (e.g., `/uploads/abc.jpg` -> `https://api.../uploads/abc.jpg`)
    final clean = resolved.startsWith('/') ? resolved : '/$resolved';
    return '${AppConfig.apiBaseUrl}$clean';
  }

  /// Returns `true` if [url] points to a bundled Flutter asset.
  static bool isAsset(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    return trimmed.startsWith('assets/');
  }

  /// Returns `true` if [url] points to a local device filesystem path.
  static bool isLocalFile(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('file://')) return true;
    if (trimmed.startsWith('/data/') ||
        trimmed.startsWith('/storage/') ||
        trimmed.startsWith('/private/') ||
        trimmed.startsWith('/var/mobile/')) {
      return true;
    }
    // Windows path e.g. C:\...
    if (trimmed.length >= 3 &&
        trimmed[1] == ':' &&
        (trimmed[2] == '\\' || trimmed[2] == '/')) {
      return true;
    }
    return false;
  }

  /// Returns `true` if [url] resolves to a remote network HTTP/HTTPS endpoint.
  static bool isNetworkUrl(String? url) {
    final resolved = resolve(url);
    return resolved.startsWith('http://') || resolved.startsWith('https://');
  }

  /// Alias for [isNetworkUrl].
  static bool isRemoteUrl(String? url) => isNetworkUrl(url);
}
