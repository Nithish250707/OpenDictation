# Releasing Open Dictation

Maintainer guide for cutting a release with auto-update support.

## One-time setup

1. **Sparkle EdDSA keys** — updates are signature-verified. Generate a key pair once:
   ```sh
   # after any build has resolved packages:
   ./build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys
   ```
   The private key is stored in your login Keychain ("Private key for signing Sparkle updates") — **never export it into the repo**. Put the printed public key into `OpenDictation/Info.plist` under `SUPublicEDKey`.
2. **(Optional but recommended) Developer ID** — join the Apple Developer Program, create a *Developer ID Application* certificate, and store notarization credentials:
   ```sh
   xcrun notarytool store-credentials opendictation-notary \
     --apple-id you@example.com --team-id TEAMID
   ```

## Per release

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the Xcode project (Sparkle compares `CFBundleVersion`, so it must increase every release).
2. Update `CHANGELOG.md` (move Unreleased under the new version).
3. Build the DMG:
   ```sh
   # unsigned (testing):
   Scripts/release.sh 0.2.0

   # signed + notarized (distribution):
   CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
   NOTARY_PROFILE=opendictation-notary \
   Scripts/release.sh 0.2.0
   ```
4. The script prints the `sparkle:edSignature` + `length` attributes. Add an `<item>` to `appcast.xml`:
   ```xml
   <item>
     <title>0.2.0</title>
     <pubDate>...RFC 822 date...</pubDate>
     <sparkle:version>2</sparkle:version>
     <sparkle:shortVersionString>0.2.0</sparkle:shortVersionString>
     <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
     <enclosure
       url="https://github.com/Nithish250707/OpenDictation/releases/download/v0.2.0/OpenDictation-0.2.0.dmg"
       sparkle:edSignature="..." length="..." type="application/octet-stream"/>
   </item>
   ```
5. Tag, release, and publish the feed:
   ```sh
   git tag -a v0.2.0 -m "Open Dictation 0.2.0" && git push origin v0.2.0
   gh release create v0.2.0 dist/OpenDictation-0.2.0.dmg --title "Open Dictation 0.2.0" --notes-file <notes>
   git add appcast.xml && git commit -m "chore: publish 0.2.0 to the update feed" && git push
   ```
   Ship order matters: upload the release asset **before** pushing the appcast, so the feed never points at a missing file.

## Notes

- The update feed is `appcast.xml` on `main`, served via raw.githubusercontent.com (`SUFeedURL` in Info.plist).
- Hardened runtime is enabled; the mic entitlement lives in `OpenDictation/OpenDictation.entitlements`. Ad-hoc builds silently drop hardened runtime, which is why unsigned local builds still record.
- Without `SUPublicEDKey` set to a real key, Sparkle will refuse unsigned feeds for security — the placeholder must be replaced before the first auto-update release.
