# Platform Bazli DatePicker Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** AppDatePicker widget'ini platform-adaptive hale getir — iOS'ta CupertinoDatePicker bottom sheet, Android'de mevcut Material picker, locale-aware tarih formatlama.

**Architecture:** Tek dosya degisikligi (`app_date_picker.dart`). `Platform.isIOS` ile dallanma. iOS dalinda `showModalBottomSheet` icinde `CupertinoDatePicker` gosterilir. Tarih formatlama `intl` paketinin `DateFormat.yMd(locale)` metodu ile locale-aware yapilir. Localization dosyasina "ok" zaten mevcut, ek string gerekmiyor.

**Tech Stack:** Flutter (dart:io, cupertino, material), intl paketi (mevcut)

---

### Task 1: Locale-aware tarih formatlama

**Files:**
- Modify: `lib/core/widgets/app_date_picker.dart:1-4` (import ekle)
- Modify: `lib/core/widgets/app_date_picker.dart:36-39` (tarih format)

**Step 1: Import ekle**

`app_date_picker.dart` dosyasinin basina su import'lari ekle:

```dart
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
```

**Step 2: Hardcoded tarih formatini locale-aware yap**

Mevcut kod (satir 36-39):
```dart
selectedDate != null
    ? '${selectedDate!.day.toString().padLeft(2, '0')}/'
      '${selectedDate!.month.toString().padLeft(2, '0')}/'
      '${selectedDate!.year}'
    : l10n.get('select_date'),
```

Yeni kod:
```dart
selectedDate != null
    ? DateFormat.yMd(Localizations.localeOf(context).toString()).format(selectedDate!)
    : l10n.get('select_date'),
```

**Step 3: Flutter analyze calistir**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/core/widgets/app_date_picker.dart`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/core/widgets/app_date_picker.dart
git commit -m "feat: locale-aware date formatting in AppDatePicker"
```

---

### Task 2: iOS CupertinoDatePicker bottom sheet

**Files:**
- Modify: `lib/core/widgets/app_date_picker.dart:53-81` (_showPicker metodu)

**Step 1: _showPicker metodunu platform-adaptive yap**

Mevcut `_showPicker` metodunu tamamen su kodla degistir:

```dart
Future<void> _showPicker(BuildContext context) async {
  final now = DateTime.now();
  final maxDate = DateTime(now.year - 18, now.month, now.day);
  final minDate = DateTime(now.year - 100);

  if (Platform.isIOS) {
    _showCupertinoPicker(context, minDate, maxDate);
  } else {
    _showMaterialPicker(context, minDate, maxDate);
  }
}

void _showCupertinoPicker(
  BuildContext context,
  DateTime minDate,
  DateTime maxDate,
) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  DateTime tempDate = selectedDate ?? maxDate;

  showModalBottomSheet(
    context: context,
    backgroundColor: theme.colorScheme.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.get('birthday'),
                      style: theme.textTheme.titleMedium,
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(context);
                        onDateSelected(tempDate);
                      },
                      child: Text(
                        l10n.get('ok'),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selectedDate ?? maxDate,
                    minimumDate: minDate,
                    maximumDate: maxDate,
                    onDateTimeChanged: (date) {
                      tempDate = date;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showMaterialPicker(
  BuildContext context,
  DateTime minDate,
  DateTime maxDate,
) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: selectedDate ?? maxDate,
    firstDate: minDate,
    lastDate: maxDate,
    initialDatePickerMode: DatePickerMode.year,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            headerBackgroundColor: AppColors.primaryDark,
            headerForegroundColor: Colors.white,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    onDateSelected(picked);
  }
}
```

**Step 2: Flutter analyze calistir**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze lib/core/widgets/app_date_picker.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/widgets/app_date_picker.dart
git commit -m "feat: platform-adaptive date picker — Cupertino on iOS, Material on Android"
```

---

### Task 3: Son dogrulama

**Step 1: Tam flutter analyze**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze`
Expected: No issues (veya sadece mevcut uyarilar)

**Step 2: register_step_birthday.dart'in degisiklik gerektirmedigini dogrula**

`RegisterStepBirthday` widget'i `AppDatePicker`'i ayni API ile kullaniyor (`selectedDate`, `onDateSelected`, `errorText`). API degismedi, bu dosyada degisiklik gerekmez.

**Step 3: Final commit (gerekirse)**

Eger analiz sorunlari varsa duzelt ve commit et.
