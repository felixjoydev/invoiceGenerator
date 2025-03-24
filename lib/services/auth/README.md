# Authentication Setup Instructions

This document provides instructions for setting up Google and Apple authentication in the Invoice Generator app.

## Supabase Configuration

1. Go to your Supabase project dashboard
2. Navigate to Authentication > Providers
3. Enable Google and Apple providers

### Google Provider Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or use an existing one
3. Navigate to APIs & Services > Credentials
4. Configure OAuth consent screen
5. Create OAuth client ID for Web application
   - Add your Supabase auth callback URL: `https://<YOUR_PROJECT_ID>.supabase.co/auth/v1/callback`
6. Create OAuth client ID for Android
   - Set package name to: `io.supabase.invoicegenerator`
   - Generate SHA-1 certificate fingerprint using keytool command:
     ```
     keytool -exportcert -alias upload -keystore my-release-key.keystore -list -v
     ```
7. Create OAuth client ID for iOS
   - Bundle ID: `io.supabase.invoicegenerator`
8. In Supabase dashboard, add the Web Client ID to Google provider settings
9. Enable "Skip nonce checks" option for Google provider in Supabase

### Apple Provider Setup

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to Certificates, IDs & Profiles
3. Register a new App ID or use an existing one
   - Enable Sign In with Apple capability
4. Create a Services ID
   - Configure Sign In with Apple
   - Add your Supabase auth callback URL: `https://<YOUR_PROJECT_ID>.supabase.co/auth/v1/callback`
5. Create a Web Authentication configuration
6. In Supabase dashboard, add your App ID to Apple provider settings

## Android Configuration

1. Update `android/app/build.gradle` file with your package name

   ```gradle
   defaultConfig {
       applicationId "io.supabase.invoicegenerator"
       // ...
   }
   ```

2. Add Deep Link configuration in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <activity
       android:name=".MainActivity"
       ...>

       <!-- ... -->

       <intent-filter>
           <action android:name="android.intent.action.VIEW" />
           <category android:name="android.intent.category.DEFAULT" />
           <category android:name="android.intent.category.BROWSABLE" />
           <data android:scheme="io.supabase.invoicegenerator" android:host="login-callback" />
       </intent-filter>
   </activity>
   ```

## iOS Configuration

1. Update `ios/Runner/Info.plist` with the following configurations:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <!-- For deep linking with Supabase auth -->
         <string>io.supabase.invoicegenerator</string>
         <!-- For Google Sign-In (replace with your reversed client ID) -->
         <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
       </array>
     </dict>
   </array>

   <!-- For Apple Sign-In -->
   <key>com.apple.developer.applesignin</key>
   <array>
     <string>Default</string>
   </array>
   ```

2. In Xcode, enable Sign In with Apple capability:
   - Open Xcode
   - Select your project
   - Go to "Signing & Capabilities"
   - Click "+" to add a capability
   - Search for and add "Sign In with Apple"

## Web Configuration

1. Add redirects in your web server config to handle auth callbacks
2. For Firebase Hosting, update `firebase.json`:
   ```json
   {
     "hosting": {
       "rewrites": [
         {
           "source": "**",
           "destination": "/index.html"
         }
       ]
     }
   }
   ```

## Deep Link Handling

The app is configured to use Deep Links for authentication callbacks with the URL scheme:

```
io.supabase.invoicegenerator://login-callback/
```

This URL scheme is used in:

- `AuthService.signInWithGoogle()`
- `AuthService.signInWithApple()`
