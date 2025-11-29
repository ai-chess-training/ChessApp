# Mixpanel Token Configuration Guide

This document explains how to securely configure Mixpanel tokens for the Chess App using environment variables.

## 🔒 Security Approach

The app uses a **secure token storage strategy** with the following priority order:

1. **Environment Variables** (Recommended for CI/CD)
2. **Bundle Info.plist** (Fallback for local development)
3. **Graceful Degradation** (Analytics disabled if no token found)

## 🚀 Setup Instructions

### Method 1: Environment Variables (CI/CD Builds)

For production and automated builds, set these environment variables:

```bash
# Debug builds
export MIXPANEL_DEBUG_TOKEN="your_debug_project_token_here"

# Production builds
export MIXPANEL_PROD_TOKEN="your_production_project_token_here"
```

#### GitHub Actions Setup:
1. Go to your repository → Settings → Secrets and variables → Actions
2. Add secrets:
   - `MIXPANEL_DEBUG_TOKEN`: Your debug project token
   - `MIXPANEL_PROD_TOKEN`: Your production project token

#### Xcode Cloud Setup:
1. Go to App Store Connect → Your App → Xcode Cloud
2. Add Environment Variables:
   - `MIXPANEL_DEBUG_TOKEN`: Your debug project token
   - `MIXPANEL_PROD_TOKEN`: Your production project token

### Method 2: Bundle Info.plist (Local Development)

For local development, add tokens to your Info.plist:

1. Open `ChessApp/Info.plist`
2. Add these keys:

```xml
<key>MIXPANEL_DEBUG_TOKEN</key>
<string>your_debug_token_here</string>
<key>MIXPANEL_PROD_TOKEN</key>
<string>your_production_token_here</string>
```

**⚠️ Important:** Add `Info.plist` to `.gitignore` if using this method to avoid committing tokens.

## 🎯 Getting Mixpanel Tokens

1. Login to [Mixpanel](https://mixpanel.com)
2. Go to Project Settings
3. Copy your **Project Token** (NOT API Secret)
4. Create separate projects for Debug and Production if desired

## 🧪 Testing the Configuration

The app will log which token source is being used:

```
✅ "Using Mixpanel debug token from environment"
✅ "Using Mixpanel production token from bundle"
❌ "No Mixpanel token found - analytics disabled"
```

## 🔧 Troubleshooting

### Analytics Not Working?
1. Check app logs for token source messages
2. Verify environment variables are set correctly
3. Ensure token is valid in Mixpanel dashboard
4. Check network connectivity

### Token Not Found?
- **CI/CD**: Verify secrets are set in your build system
- **Local**: Check Info.plist has correct keys and values
- **Both**: Ensure no typos in token keys

## 🛡️ Security Best Practices

✅ **DO:**
- Use environment variables for CI/CD builds
- Use different tokens for debug/production
- Rotate tokens regularly (every 6-12 months)
- Monitor token usage in Mixpanel dashboard

❌ **DON'T:**
- Hardcode tokens in source code
- Commit tokens to version control
- Share tokens in team chats or documentation
- Use production tokens in debug builds

## 🔄 Token Rotation

When rotating tokens:

1. Generate new token in Mixpanel
2. Update environment variables/Info.plist
3. Deploy new app version
4. Deactivate old token in Mixpanel after rollout

---

**Need help?** Check the AnalyticsManager.swift implementation for technical details.