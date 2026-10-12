# Releasing

Pushing a version tag runs [`release.yml`](../.github/workflows/release.yml), which does the following:
- Archives a Release build signed with Developer ID.
- Notarises and staples the app, then a DMG.
- Publishes a GitHub Release with the DMG, a Sparkle zip and `appcast.xml`.

```sh
git tag v0.1.0
git push origin v0.1.0
```

The app checks `https://github.com/bevanjkay/focus-up/releases/latest/download/appcast.xml`, so the newest non-prerelease release is always the update feed.

## Secrets

| Secret | What it is |
| --- | --- |
| `SPARKLE_PRIVATE_KEY` | The EdDSA key that signs updates. Its public half is `SUPublicEDKey` in `Config/Info.plist`. The original is in the login keychain under the `focus-up` account (`generate_keys --account focus-up`). |
| `DEVELOPER_ID_P12` | The Developer ID Application certificate and private key, as base64 of a `.p12`. |
| `DEVELOPER_ID_P12_PASSWORD` | The password chosen when exporting the `.p12`. |
| `NOTARY_KEY` | The contents of an App Store Connect API key (`AuthKey_XXXXXXXXXX.p8`). |
| `NOTARY_KEY_ID` | That key's ID. |
| `NOTARY_ISSUER_ID` | The team's issuer ID, shown above the keys list. |

### Developer ID certificate

1. In Keychain Access, open **My Certificates**, select **Developer ID Application: Bevan Kay (7H96V6CNLG)**, and choose **File → Export Items…** as a `.p12` with a strong password.
2. Store it, then delete the file:

   ```sh
   base64 -i DeveloperID.p12 | gh secret set DEVELOPER_ID_P12 --repo bevanjkay/focus-up
   gh secret set DEVELOPER_ID_P12_PASSWORD --repo bevanjkay/focus-up
   rm -P DeveloperID.p12
   ```

### Notarisation API key

1. In [App Store Connect](https://appstoreconnect.apple.com/access/integrations/api), go to **Users and Access → Integrations → App Store Connect API → Team Keys** and generate a key with the **Developer** role. The `.p8` can only be downloaded once.
2. Store it:

   ```sh
   gh secret set NOTARY_KEY --repo bevanjkay/focus-up < AuthKey_XXXXXXXXXX.p8
   gh secret set NOTARY_KEY_ID --repo bevanjkay/focus-up --body XXXXXXXXXX
   gh secret set NOTARY_ISSUER_ID --repo bevanjkay/focus-up --body 00000000-0000-0000-0000-000000000000
   ```

## Versions

The tag sets `CFBundleShortVersionString` (`v0.2.0` becomes `0.2.0`). The workflow run number sets `CFBundleVersion`, which Sparkle compares, so it always increases.
