# Localization Setup Guide

This guide explains how to configure your Xcode project to use the English and Korean localizations that have been implemented.

## Files Created

### 1. LocalizedString.swift
Location: `SharingOnlyProject/Utilities/LocalizedString.swift`
- Type-safe localization helper with organized categories
- Provides easy access to localized strings throughout the app
- Includes helper functions for formatted strings (e.g., counts, dynamic text)

### 2. Localization Files
- **Korean**: `SharingOnlyProject/Resources/ko.lproj/Localizable.strings`
- **English**: `SharingOnlyProject/Resources/en.lproj/Localizable.strings`

## Xcode Project Configuration Steps

### Step 1: Add Localization Files to Xcode

1. Open your project in Xcode
2. In the Project Navigator, right-click on the `SharingOnlyProject` folder
3. Select **Add Files to "SharingOnlyProject"...**
4. Navigate to and select the `Resources` folder
5. Make sure **"Copy items if needed"** is UNCHECKED (files are already in the right location)
6. Make sure **"Create groups"** is selected
7. Click **Add**

### Step 2: Add LocalizedString.swift to Xcode

1. Right-click on the `Utilities` folder in Project Navigator
2. Select **Add Files to "SharingOnlyProject"...**
3. Navigate to and select `LocalizedString.swift`
4. Make sure it's added to your app target
5. Click **Add**

### Step 3: Configure Project Localizations

1. Select your **project** (SharingOnlyProject) in the Project Navigator
2. Select the **project** (not the target) in the main editor
3. Go to the **Info** tab
4. In the **Localizations** section, you should see:
   - English (Development Language) - if not, click **+** and add it
   - Click **+** to add Korean (ko)
5. When prompted, select the `Localizable.strings` file to localize
6. Click **Finish**

### Step 4: Verify File References

1. In Project Navigator, expand the `Resources` folder
2. You should see:
   - `ko.lproj` folder containing `Localizable.strings`
   - `en.lproj` folder containing `Localizable.strings`
3. Click on each `Localizable.strings` file
4. In the File Inspector (right panel), verify:
   - Under **Localization**, both **Korean** and **English** should be checked
   - Under **Target Membership**, your app target should be checked

### Step 5: Build and Test

1. Build your project (⌘B)
2. If there are any compile errors, make sure:
   - `LocalizedString.swift` is included in your target
   - All localization files are properly referenced
3. Test the localization:
   - Run the app on a simulator or device
   - The app should display in Korean by default
   - Change device language to English (Settings → General → Language & Region)
   - Relaunch the app - it should now display in English

## Testing Different Languages

### In Simulator
1. Open **Settings** app
2. Go to **General** → **Language & Region**
3. Tap **iPhone Language**
4. Select **English** or **한국어**
5. Tap **Done** and confirm
6. Relaunch your app

### In Xcode Scheme
1. Select your scheme (Product → Scheme → Edit Scheme)
2. Go to **Run** → **Options** tab
3. Under **App Language**, select:
   - **Korean** or
   - **English**
4. Run the app

## Localized Components

The following components now support both English and Korean:

### Views Updated
- ✅ `SharingView.swift` - Main sharing interface
- ✅ `RecipientSetupView.swift` - Recipient management
- ✅ `DirectionalDragView.swift` - Photo distribution interface
- ✅ `TemporaryAlbumPreview.swift` - Album preview and sharing

### Models Updated
- ✅ `ShareModels.swift` - Direction names and enums

### Localized String Categories
- **General**: Common buttons and actions (Back, Next, Cancel, etc.)
- **Sharing Steps**: All 4 sharing steps with titles and subtitles
- **Directions**: All 8 directional names (Top, Bottom, Left, Right, etc.)
- **Photo View**: Photo-related messages and states
- **Recipients**: Recipient setup and management strings
- **Photo Distribution**: Distribution interface strings
- **Album**: Album preview and sharing strings
- **Buttons**: All button labels
- **Status**: Status messages and indicators
- **Alerts**: All alert dialogs
- **Accessibility**: Accessibility labels and hints
- **Empty States**: Empty state messages

## Usage Examples

### Simple String
```swift
Text(LocalizedString.General.next)
// Korean: "다음"
// English: "Next"
```

### Direction Names
```swift
Text(recipient.direction.displayName)
// Korean: "위", "아래", "왼쪽", etc.
// English: "Top", "Bottom", "Left", etc.
```

### Formatted Strings (with counts)
```swift
Text(LocalizedString.recipientCount(3))
// Korean: "3명"
// English: "3 people"

Text(LocalizedString.photoCount(15))
// Korean: "15장의 사진"
// English: "15 photos"
```

### Alert Messages with Formatting
```swift
Text(String(format: NSLocalizedString("recipient_remove_message", comment: ""), recipient.name))
// Korean: "친구을(를) 제거하시겠습니까?\n해당 임시 앨범의 사진도 함께 삭제됩니다."
// English: "Remove 친구?\nPhotos in their temporary album will also be deleted."
```

## Adding New Localizations

### 1. Add to LocalizedString.swift
```swift
enum MyCategory {
    static let myNewString = "my_new_string_key".localized
}
```

### 2. Add to Localizable.strings (both Korean and English)

**Korean (ko.lproj/Localizable.strings)**:
```
"my_new_string_key" = "한국어 텍스트";
```

**English (en.lproj/Localizable.strings)**:
```
"my_new_string_key" = "English Text";
```

### 3. Use in your code
```swift
Text(LocalizedString.MyCategory.myNewString)
```

## Troubleshooting

### Strings not updating after changes
- Clean build folder: **Product → Clean Build Folder** (⇧⌘K)
- Delete derived data: **Xcode → Preferences → Locations → Derived Data** → Delete
- Rebuild the project

### App not showing correct language
- Verify device/simulator language settings
- Check that `Localizable.strings` files are in the correct `.lproj` folders
- Verify files are included in the app target (File Inspector → Target Membership)

### Compile errors related to LocalizedString
- Ensure `LocalizedString.swift` is added to your project
- Verify it's included in your app target
- Check that all enum cases are properly defined

## Summary

Your app now fully supports both **English** and **Korean** localizations:
- 🌍 **2 languages**: English (en) and Korean (ko)
- 📱 **100+ localized strings** across all major UI components
- 🎯 **Type-safe**: Using enums for compile-time safety
- 🔧 **Maintainable**: Centralized localization management
- ♿ **Accessible**: Including accessibility labels and hints

The app will automatically display in the user's device language (if English or Korean), with Korean as the default fallback.