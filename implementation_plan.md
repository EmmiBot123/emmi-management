# Implementation Plan - Rebranding to Qubiq OS & Operations Overhaul

This plan covers the transition of the "Emmi Management" platform to the new **Qubiq OS** brand, alongside a major feature overhaul for the Installation Team.

## User Review Required

> [!IMPORTANT]
> - The project will be renamed from `emmi_management` to `qubiq_os`. This involves updating all code imports.
> - A "Download APK" feature will be added to the Web dashboard, pointing to `/qubiq_os.apk` (which you should place in the `web/` folder).

## Proposed Changes

### 1. Project Rebranding (Qubiq OS)
#### [MODIFY] [pubspec.yaml](file:///c:/Users/abrah/Downloads/emmi-management%202/emmi-management/pubspec.yaml)
- Change `name: emmi_management` to `name: qubiq_os`.

#### [MODIFY] ALL DART FILES
- Replace `import 'package:emmi_management/` with `import 'package:qubiq_os/`.

#### [MODIFY] [RolesPage.dart](file:///c:/Users/abrah/Downloads/emmi-management%202/emmi-management/lib/Screens/RolesPage.dart)
- Update branding text from "EMMI Management Console" to "**QUBIQ OS**".
- Add the **"Download Android App"** card in the navigation drawer.

### 2. Operations / Installation Overhaul
#### [MODIFY] [OperationsPage.dart](file:///c:/Users/abrah/Downloads/emmi-management%202/emmi-management/lib/Screens/OperationsPage.dart)
- Apply the **Obsidian Glass** theme (Dark Mode, Glassmorphism).
- Set "Installation" as the primary tab.

#### [MODIFY] [installation_page.dart](file:///c:/Users/abrah/Downloads/emmi-management%202/emmi-management/lib/Screens/Installation/installation_page.dart)
- Implement the **Bento Grid** layout for installation actions.
- **NEW**: Add **Digital Sign-off** capability.
- **NEW**: Add **Guided Installation** visual wizard.

### 3. Innovative Features
- **Hosted APK**: Add logic to download the APK from the web root.
- **Mission Control**: Update the Installation list to show live status badges.

## Verification Plan

### Automated Tests
- `flutter pub get` to verify the name change in `pubspec.yaml`.

### Manual Verification
- Verify that the app builds and runs with the new `qubiq_os` package name.
- Check the new branding in the Navigation Drawer.
- Verify the "Download APK" button triggers a download for `/qubiq_os.apk`.
- Test the new Bento Grid and Digital Sign-off UI in the Installation details.
