# GitHub & Codemagic Setup Guide for Tunely Flutter

## Step 1: Initialize Git Repository

First, let's initialize a git repository in your Flutter project:

```bash
cd C:\Users\Gabriel\Desktop\Tunely\tunely_flutter
git init
```

## Step 2: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `tunely_flutter`
3. Description: "Premium Music Streaming App with Liquid Glass UI"
4. Make it **Private** (recommended for personal projects)
5. **Don't** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

## Step 3: Connect Local Repository to GitHub

```bash
# Add the remote repository (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/tunely_flutter.git

# Or if you prefer SSH:
git remote add origin git@github.com:YOUR_USERNAME/tunely_flutter.git
```

## Step 4: Stage and Commit Files

```bash
# Add all files to staging
git add .

# Check what will be committed
git status

# Commit the files
git commit -m "Initial commit: Flutter Tunely with Liquid Glass UI"
```

## Step 5: Push to GitHub

```bash
# Push to main branch
git push -u origin main
```

If you get an error about the branch name, use:
```bash
git branch -M main
git push -u origin main
```

## Step 6: Verify GitHub Upload

1. Go to your GitHub repository page
2. You should see all your project files uploaded
3. Verify the structure looks correct

## Step 7: Setup Codemagic

### Create Codemagic Account

1. Go to https://codemagic.io
2. Click "Sign up for free"
3. Sign up using your GitHub account
4. Authorize Codemagic to access your GitHub repositories

### Add Your Project to Codemagic

1. After signing in, click "Add your first app"
2. Select "GitHub" as the repository provider
3. Find and select `tunely_flutter` from your repositories
4. Click "Select repository"

### Configure Codemagic Build

1. **Project Settings**:
   - Project name: `Tunely Flutter`
   - Build type: `Flutter application`
   
2. **Flutter Configuration**:
   - Flutter version: `3.16.0` (or latest stable)
   - Build configuration: Use the `codemagic.yaml` file we created
   
3. **iOS Configuration**:
   - Code signing: Off (for now, using --no-codesign)
   - Provisioning profiles: Not needed for development builds
   - Export method: Development

4. **Environment Variables** (optional):
   - No secrets needed for basic builds (--no-codesign)

### Start Your First Build

1. Click "Start new build"
2. Select branch: `main`
3. Click "Start build"
4. Watch the build progress in real-time

## Step 8: Download and Test the IPA

1. Once the build completes successfully
2. Go to the "Artifacts" section
3. Download the `tunely-ios.ipa` file
4. Install on your iPhone using:
   - **AltStore** (recommended, free)
   - **Sideloadly** (free)
   - **Apple Configurator** (Mac only)

## Alternative: Using GitHub Actions (Already Configured)

Since we already have GitHub Actions set up, you can also:

1. Go to your GitHub repository
2. Click "Actions" tab
3. Select "Build iOS IPA" workflow
4. Click "Run workflow"
5. Select build type and click "Run workflow"
6. Download the IPA from the Artifacts section

## Troubleshooting

### Git Push Issues

**Error: "remote origin already exists"**
```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/tunely_flutter.git
```

**Error: "Authentication failed"**
- Make sure you're using the correct GitHub credentials
- Consider using a Personal Access Token: https://github.com/settings/tokens

**Error: "main branch doesn't exist"**
```bash
git branch -M main
git push -u origin main
```

### Codemagic Build Issues

**Flutter not found**
- The codemagic.yaml automatically installs Flutter
- Check the FLUTTER_VERSION variable matches a valid version

**Pod install fails**
- Ensure Xcode is properly configured in Codemagic
- Check that the Podfile is correct

**Build fails with --no-codesign**
- This is expected for development builds
- For production, you'll need Apple Developer credentials

### Common GitHub Setup Issues

**Repository not visible in Codemagic**
- Make sure the repository is public or you've granted Codemagic access
- Check GitHub OAuth permissions

**Files not uploading**
- Check .gitignore isn't excluding important files
- Run `git status` to see what's staged

## Next Steps After Successful Build

### For Production Builds (App Store)

1. **Apple Developer Account** ($99/year)
2. **Code Signing**:
   - Generate certificates in Apple Developer Portal
   - Create provisioning profiles
   - Add to Codemagic environment variables

### Codemagic Environment Variables for Production

Add these in Codemagic project settings:

```
CM_CERTIFICATE: <base64 encoded certificate>
CM_CERTIFICATE_PASSWORD: <certificate password>
CM_PROVISIONING_PROFILE: <base64 encoded profile>
APP_STORE_CONNECT_API_KEY: <App Store Connect API key>
```

### Optimize the Workflow

You can customize `codemagic.yaml` for:
- Automated testing
- Multiple build configurations
- App Store submission
- Slack/Discord notifications
- Custom build scripts

## Comparison: GitHub Actions vs Codemagic

| Feature | GitHub Actions | Codemagic |
|---------|---------------|-----------|
| Cost | Free for public repos | Free tier available |
| Setup | Already configured | Requires setup |
| iOS Signing | Manual configuration | Better iOS support |
| UI | GitHub interface | Dedicated UI |
| Ease of Use | Good for developers | Better for CI/CD focus |
| Flutter Support | Good | Excellent |

## Quick Commands Reference

```bash
# Navigate to project
cd C:\Users\Gabriel\Desktop\Tunely\tunely_flutter

# Git operations
git init
git add .
git commit -m "Your message"
git push -u origin main

# Flutter operations
flutter pub get
flutter build ios --debug --no-codesign
flutter build ios --release --no-codesign

# iOS operations
cd ios
pod install
```

## Recommended Workflow

1. **Development**: Test locally with `flutter run`
2. **Testing**: Use GitHub Actions for quick builds
3. **Production**: Use Codemagic for App Store builds
4. **Monitoring**: Both platforms provide build logs and notifications

## Support Resources

- **GitHub**: https://docs.github.com
- **Codemagic**: https://docs.codemagic.io
- **Flutter**: https://flutter.dev/docs
- **Liquid Glass**: https://pub.dev/packages/liquid_glass_renderer

Your Flutter Tunely app is now ready for automated building and testing! 🚀
