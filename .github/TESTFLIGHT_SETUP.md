# TestFlight Automated Deployment Setup

This repository is configured to automatically build and deploy to TestFlight when you push to the `main` branch.

## ✅ What's Already Configured

- ✅ GitHub Actions workflow (`.github/workflows/testflight.yml`)
- ✅ Fastlane configuration (`ios/fastlane/`)
- ✅ App encryption exemption (no compliance questions)
- ✅ Automatic build number increment

## 🔑 Required GitHub Secrets

You need to add these secrets to your GitHub repository for automated deployments to work:

### Go to: `https://github.com/YOUR_USERNAME/Reppy/settings/secrets/actions`

Add the following secrets:

### 1. APP_STORE_CONNECT_API_KEY_ID
- Go to [App Store Connect → Users and Access → Keys](https://appstoreconnect.apple.com/access/api)
- Click **"+"** to create a new key
- Name: "GitHub Actions"
- Access: **App Manager**
- Copy the **Key ID** (e.g., `ZZRC8MJA8H`)
- Paste into GitHub secret

### 2. APP_STORE_CONNECT_API_ISSUER_ID
- Same page as above
- Copy the **Issuer ID** (UUID format, e.g., `698c5ba8-ce34-43c1-93ff-f061ae9a8c8f`)
- Paste into GitHub secret

### 3. APP_STORE_CONNECT_API_KEY
- After creating the key, download the `.p8` file
- Open it in a text editor
- Copy the **ENTIRE contents** including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines
- Paste into GitHub secret

**Important:** Store the `.p8` file securely - you can only download it once!

## 🚀 How It Works

1. **Push to main:**
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```

2. **GitHub Actions automatically:**
   - ✅ Increments build number
   - ✅ Builds the app
   - ✅ Signs with your certificates
   - ✅ Exports IPA
   - ✅ Uploads to TestFlight

3. **Check progress:**
   - Go to `https://github.com/YOUR_USERNAME/Reppy/actions`
   - Click on the latest workflow run
   - Watch the real-time logs

4. **After upload:**
   - Wait 5-10 minutes for Apple to process
   - Go to [App Store Connect → Reppy → TestFlight](https://appstoreconnect.apple.com)
   - Add build to Internal Testing group
   - App appears in TestFlight within minutes

## 🛠 Manual Commands (Optional)

If you want to run locally instead:

```bash
# Deploy to TestFlight
cd ios
fastlane beta

# Build only (no upload)
fastlane build_only

# Upload existing IPA
fastlane upload_only ipa:/path/to/app.ipa
```

## 📋 Checklist

- [ ] Add `APP_STORE_CONNECT_API_KEY_ID` to GitHub secrets
- [ ] Add `APP_STORE_CONNECT_API_ISSUER_ID` to GitHub secrets
- [ ] Add `APP_STORE_CONNECT_API_KEY` to GitHub secrets
- [ ] Push to main and verify workflow runs
- [ ] Check App Store Connect for build

## 🎯 Current Build Number

Current: **1**

The build number auto-increments with each deployment.

## ❓ Troubleshooting

**Workflow fails with "Invalid credentials":**
- Verify GitHub secrets are set correctly
- Regenerate App Store Connect API key

**Build succeeds but not in TestFlight:**
- Wait 10-15 minutes for processing
- Check for email from Apple about issues
- Verify Team ID is correct: `9M9375N2XL`

**Certificate issues:**
- Ensure you have a valid Apple Distribution certificate
- Check that provisioning profiles are up to date

---

**Built with ❤️ using:**
- 🎯 Fastlane - Build automation
- 🔄 GitHub Actions - CI/CD
- 🍎 Xcode 16 - iOS development
