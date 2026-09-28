# Community story deep links

The canonical public story URL is:

```text
https://genlink.app/story/{storyId}
```

The app accepts only HTTPS links for `genlink.app` with exactly one safe story
ID path segment. Flutter requests that story from the authenticated backend
before opening the viewer, so deleted, expired, or unauthorized stories are
shown as unavailable.

## Android App Links

`AndroidManifest.xml` registers the `/story/` HTTPS path for the Android
application ID `kh.edu.acleda.genlink.genlink_frontend`. Publish this file at
`https://genlink.app/.well-known/assetlinks.json` after substituting the
SHA-256 certificate fingerprint used to sign the release app:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "kh.edu.acleda.genlink.genlink_frontend",
      "sha256_cert_fingerprints": ["RELEASE_CERTIFICATE_SHA256_FINGERPRINT"]
    }
  }
]
```

For Play App Signing, use the app-signing certificate fingerprint shown in
Play Console. Add additional fingerprints only for signing certificates that
are actively used to distribute this application.

## iOS Universal Links

The Runner entitlement registers `applinks:genlink.app`. Publish this file at
`https://genlink.app/.well-known/apple-app-site-association` after replacing
`APPLE_TEAM_ID` with the Apple Developer Team ID:

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["APPLE_TEAM_ID.kh.edu.acleda.genlink.genlinkFrontend"],
        "components": [
          { "/": "/story/*", "comment": "GenLink story links" }
        ]
      }
    ]
  }
}
```

Serve both association files over HTTPS with a successful response and the
correct JSON content type. The Android signing fingerprint and Apple Team ID
must come from the release owners; they are intentionally not guessed or
committed as placeholders in the native project settings.
