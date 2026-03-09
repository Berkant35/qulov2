# Language System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Kullanıcıların dil tercihlerini seçmesini, soruların dil etiketi taşımasını ve discover/quiz akışlarının dil-aware çalışmasını sağlamak.

**Architecture:** DB'ye `user_languages` tablosu + `questions.locale` kolonu eklenir. Backend matching service dil filtresi uygular (2+ ortak dil sorusu gerekli). Quiz service sadece ortak dildeki soruları gösterir. Flutter'da wizard'a dil chip'i, settings'e dil tercihleri, onboarding'e dil slide'ı eklenir.

**Tech Stack:** Supabase PostgreSQL, Node.js/Express/TypeScript (Zod), Flutter/Riverpod/GoRouter, Retrofit (Dio)

---

## Phase 1: DB Migration

### Task 1: Migration 011 — Language System

**Files:**
- Create: `supabase/migrations/011_language_system.sql`

**Context:** Migration 010 (question system overhaul) zaten çalıştırıldı. Bu migration user_languages tablosu oluşturur, questions'a locale kolonu ekler ve users.locale constraint'ini genişletir.

**Step 1: Migration SQL dosyasını oluştur**

```sql
-- Migration 011: Language System
-- Adds user_languages table for multi-language preferences
-- Adds locale column to questions table
-- Expands users.locale constraint to support more languages

-- 1. Supported locales list (used in constraints)
-- tr, en, de, fr, es, ar, ru, pt, it, ja, ko, zh, nl, pl, sv

-- 2. User languages table (many-to-many)
CREATE TABLE IF NOT EXISTS user_languages (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  language_code TEXT NOT NULL CHECK (language_code IN ('tr','en','de','fr','es','ar','ru','pt','it','ja','ko','zh','nl','pl','sv')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, language_code)
);

-- Index for fast lookup by user
CREATE INDEX idx_user_languages_user ON user_languages(user_id);

-- 3. Add locale column to questions table
ALTER TABLE questions ADD COLUMN IF NOT EXISTS locale TEXT NOT NULL DEFAULT 'tr'
  CHECK (locale IN ('tr','en','de','fr','es','ar','ru','pt','it','ja','ko','zh','nl','pl','sv'));

-- Index for filtering questions by locale
CREATE INDEX idx_questions_locale ON questions(user_id, locale);

-- 4. Expand users.locale constraint to support all languages
-- Drop old constraint and add new one
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_locale_check;
ALTER TABLE users ADD CONSTRAINT users_locale_check
  CHECK (locale IN ('tr','en','de','fr','es','ar','ru','pt','it','ja','ko','zh','nl','pl','sv'));

-- 5. Backfill: Insert current user locale into user_languages for all existing users
INSERT INTO user_languages (user_id, language_code)
SELECT id, locale FROM users
ON CONFLICT (user_id, language_code) DO NOTHING;
```

**Step 2: Commit**

```bash
git add supabase/migrations/011_language_system.sql
git commit -m "feat: add migration 011 — language system (user_languages table, questions.locale)"
```

**Note:** Migration'ı Supabase SQL Editor'da çalıştırmak kullanıcının sorumluluğundadır.

---

## Phase 2: Backend Constants & Validators

### Task 2: SUPPORTED_LOCALES Sabiti

**Files:**
- Create: `server/src/constants/locales.ts`

**Step 1: Locale sabitlerini oluştur**

```typescript
export const SUPPORTED_LOCALES = [
  'tr', 'en', 'de', 'fr', 'es', 'ar', 'ru',
  'pt', 'it', 'ja', 'ko', 'zh', 'nl', 'pl', 'sv',
] as const;

export type SupportedLocale = typeof SUPPORTED_LOCALES[number];

// Display names for each locale (used in API responses)
export const LOCALE_NAMES: Record<SupportedLocale, string> = {
  tr: 'Türkçe',
  en: 'English',
  de: 'Deutsch',
  fr: 'Français',
  es: 'Español',
  ar: 'العربية',
  ru: 'Русский',
  pt: 'Português',
  it: 'Italiano',
  ja: '日本語',
  ko: '한국어',
  zh: '中文',
  nl: 'Nederlands',
  pl: 'Polski',
  sv: 'Svenska',
};
```

**Step 2: Commit**

```bash
git add server/src/constants/locales.ts
git commit -m "feat: add SUPPORTED_LOCALES constant with 15 languages"
```

### Task 3: Validator Güncellemeleri

**Files:**
- Modify: `server/src/validators/question.validator.ts`
- Modify: `server/src/validators/user.validator.ts`
- Create: `server/src/validators/user-language.validator.ts`

**Step 1: Question validator'a locale ekle**

`server/src/validators/question.validator.ts` dosyasında:

Import ekle:
```typescript
import { SUPPORTED_LOCALES } from '../constants/locales.js';
```

`createQuestionSchema`'ya locale alanı ekle (category'nin yanına):
```typescript
locale: z.enum(SUPPORTED_LOCALES as unknown as [string, ...string[]]).optional(),
```

`updateQuestionSchema`'ya da aynı alanı ekle:
```typescript
locale: z.enum(SUPPORTED_LOCALES as unknown as [string, ...string[]]).optional(),
```

**Step 2: User language validator oluştur**

`server/src/validators/user-language.validator.ts`:

```typescript
import { z } from 'zod';
import { SUPPORTED_LOCALES } from '../constants/locales.js';

export const setUserLanguagesSchema = z.object({
  body: z.object({
    languages: z.array(
      z.enum(SUPPORTED_LOCALES as unknown as [string, ...string[]])
    ).min(1, 'At least one language is required'),
  }),
});
```

**Step 3: User validator'daki locale constraint'ini genişlet**

`server/src/validators/user.validator.ts` dosyasında:

Import ekle:
```typescript
import { SUPPORTED_LOCALES } from '../constants/locales.js';
```

Mevcut `locale: z.enum(['tr', 'en'])` satırını değiştir:
```typescript
locale: z.enum(SUPPORTED_LOCALES as unknown as [string, ...string[]]).optional(),
```

**Step 4: Commit**

```bash
git add server/src/validators/question.validator.ts server/src/validators/user.validator.ts server/src/validators/user-language.validator.ts
git commit -m "feat: add locale field to question validator, create user-language validator"
```

---

## Phase 3: Backend — User Languages Service & Routes

### Task 4: User Language Service

**Files:**
- Create: `server/src/services/user-language.service.ts`

**Context:** Kullanıcının dil tercihlerini yöneten servis. `user_languages` tablosunu kullanır. Register'da otomatik dil ekleme de bu servis üzerinden yapılacak.

**Step 1: Servisi oluştur**

```typescript
import { supabase } from '../config/supabase.js';
import type { SupportedLocale } from '../constants/locales.js';

class UserLanguageService {
  async getUserLanguages(userId: string): Promise<string[]> {
    const { data, error } = await supabase
      .from('user_languages')
      .select('language_code')
      .eq('user_id', userId)
      .order('created_at', { ascending: true });

    if (error) throw error;
    return (data || []).map((row: { language_code: string }) => row.language_code);
  }

  async setUserLanguages(userId: string, languages: SupportedLocale[]): Promise<string[]> {
    // Delete all existing languages
    const { error: deleteError } = await supabase
      .from('user_languages')
      .delete()
      .eq('user_id', userId);

    if (deleteError) throw deleteError;

    // Insert new languages
    const rows = languages.map(lang => ({
      user_id: userId,
      language_code: lang,
    }));

    const { error: insertError } = await supabase
      .from('user_languages')
      .insert(rows);

    if (insertError) throw insertError;

    return languages;
  }

  async addLanguage(userId: string, language: SupportedLocale): Promise<void> {
    await supabase
      .from('user_languages')
      .upsert({ user_id: userId, language_code: language }, { onConflict: 'user_id,language_code' });
  }
}

export const userLanguageService = new UserLanguageService();
```

**Step 2: Commit**

```bash
git add server/src/services/user-language.service.ts
git commit -m "feat: add UserLanguageService for managing user language preferences"
```

### Task 5: User Language Routes & Controller

**Files:**
- Modify: `server/src/routes/user.routes.ts`

**Context:** User routes'a `GET /me/languages` ve `PUT /me/languages` endpoint'leri eklenir. Controller fonksiyonları inline olarak route dosyasında tanımlanır (mevcut pattern'e uygun).

**Step 1: Route'ları ekle**

`server/src/routes/user.routes.ts` dosyasında import'lar:
```typescript
import { userLanguageService } from '../services/user-language.service.js';
import { setUserLanguagesSchema } from '../validators/user-language.validator.js';
```

Mevcut route'ların sonuna (DELETE `/me` route'undan önce) ekle:

```typescript
// GET /me/languages — Get user's language preferences
router.get('/me/languages', async (req, res, next) => {
  try {
    const languages = await userLanguageService.getUserLanguages(req.user!.id);
    res.json({ languages });
  } catch (err) {
    next(err);
  }
});

// PUT /me/languages — Set user's language preferences (full replace)
router.put('/me/languages', validate(setUserLanguagesSchema), async (req, res, next) => {
  try {
    const { languages } = req.body;
    const result = await userLanguageService.setUserLanguages(req.user!.id, languages);
    res.json({ languages: result });
  } catch (err) {
    next(err);
  }
});
```

**Step 2: Commit**

```bash
git add server/src/routes/user.routes.ts
git commit -m "feat: add GET/PUT /me/languages routes for language preferences"
```

### Task 6: Register'da Otomatik Dil Ekleme

**Files:**
- Modify: `server/src/services/auth.service.ts`

**Context:** Kullanıcı kayıt olduğunda, locale değeri otomatik olarak `user_languages` tablosuna da eklenir.

**Step 1: Auth service'e user_languages insert ekle**

`server/src/services/auth.service.ts` dosyasında import ekle:
```typescript
import { userLanguageService } from './user-language.service.js';
```

Register fonksiyonunda, kullanıcı insert'inden sonra (userId elde edildikten sonra), Supabase auth signUp'tan önce:
```typescript
// Auto-add user's locale to user_languages
await userLanguageService.addLanguage(userId, locale || 'tr');
```

**Step 2: Commit**

```bash
git add server/src/services/auth.service.ts
git commit -m "feat: auto-add user locale to user_languages on registration"
```

---

## Phase 4: Backend — Question Service Locale

### Task 7: Question Service'e Locale Desteği

**Files:**
- Modify: `server/src/services/question.service.ts`

**Context:** createQuestion ve updateQuestion fonksiyonlarına locale alanı eklenir.

**Step 1: createQuestion'a locale ekle**

`createQuestion()` fonksiyonunda insert objesine ekle:
```typescript
locale: data.locale || 'tr',
```

**Step 2: updateQuestion'a locale ekle**

`updateQuestion()` fonksiyonundaki update fields kısmına ekle (category ve time_limit'in yanına):
```typescript
...(data.locale && { locale: data.locale }),
```

**Step 3: getQuestionAnalytics'te locale döndür**

Analytics response'daki question item'larına locale alanını ekle. Select sorgusunda `locale` kolonunu da çek.

**Step 4: Commit**

```bash
git add server/src/services/question.service.ts
git commit -m "feat: add locale support to question create/update/analytics"
```

---

## Phase 5: Backend — Matching Service Dil Filtresi

### Task 8: Discover'da Dil Filtresi

**Files:**
- Modify: `server/src/services/matching.service.ts`

**Context:** Bu en kritik task. Discover algoritmasına dil filtresi eklenir. Kural: Karşı tarafın en az 2 sorusu kullanıcının bildiği dillerde olmalı. Ayrıca question_info'ya languages eklenir.

**Step 1: Matching service'e import ekle**

```typescript
import { userLanguageService } from './user-language.service.js';
```

**Step 2: discover() fonksiyonuna dil filtresi ekle**

discover() fonksiyonunun başında, kullanıcının dil tercihlerini çek:
```typescript
const userLanguages = await userLanguageService.getUserLanguages(userId);
```

Candidate'ler fetch edildikten sonra, question gate filtresinden sonra (mevcut `questions.length < 2` filtresinin olduğu yer), dil filtresi ekle:

```typescript
// Language filter: candidate must have 2+ questions in user's languages
if (userLanguages.length > 0) {
  const candidateQuestions = await supabase
    .from('questions')
    .select('user_id, locale')
    .in('user_id', candidateIds);

  const candidateQuestionsByUser = new Map<string, string[]>();
  for (const q of candidateQuestions.data || []) {
    const locales = candidateQuestionsByUser.get(q.user_id) || [];
    locales.push(q.locale || 'tr');
    candidateQuestionsByUser.set(q.user_id, locales);
  }

  candidates = candidates.filter(c => {
    const qLocales = candidateQuestionsByUser.get(c.id) || [];
    const matchingCount = qLocales.filter(l => userLanguages.includes(l)).length;
    return matchingCount >= 2;
  });
}
```

**Step 3: question_info enrichment'a languages ekle**

Mevcut question_info enrichment bölümünde (kategori ve zorluk hesaplaması yapılan yer), her candidate için soruların dillerini de topla:

```typescript
// Collect unique languages for each candidate's questions
const languages = [...new Set(userQuestions.map((q: any) => q.locale || 'tr'))];
```

question_info objesine ekle:
```typescript
languages,
```

**Step 4: Commit**

```bash
git add server/src/services/matching.service.ts
git commit -m "feat: add language filter to discover — require 2+ questions in common languages"
```

---

## Phase 6: Backend — Quiz Service Dil Filtresi

### Task 9: Quiz'de Dil Bazlı Soru Filtreleme

**Files:**
- Modify: `server/src/services/quiz.service.ts`

**Context:** Quiz başladığında ve soru getirilirken, sadece çözenin bildiği dillerdeki sorular gösterilir. Session timeout da buna göre hesaplanır.

**Step 1: Quiz service'e import ekle**

```typescript
import { userLanguageService } from './user-language.service.js';
```

**Step 2: startSession() fonksiyonunu güncelle**

Soruları fetch ettikten sonra, session oluşturmadan önce dil filtresi uygula:

```typescript
// Filter questions by solver's languages
const solverLanguages = await userLanguageService.getUserLanguages(userId);
let filteredQuestions = questions;
if (solverLanguages.length > 0) {
  filteredQuestions = questions.filter((q: any) =>
    solverLanguages.includes(q.locale || 'tr')
  );
}

if (filteredQuestions.length < 2) {
  throw new AppError('NOT_ENOUGH_QUESTIONS', 400);
}
```

Session timeout hesabını `filteredQuestions` üzerinden yap (mevcut `questions` yerine).

Session oluştururken `total_questions` alanını `filteredQuestions.length` olarak set et (eğer bu alan varsa, yoksa mevcut davranışı koru).

**Step 3: getCurrentQuestion() fonksiyonunu güncelle**

Soruları fetch ettikten sonra aynı dil filtresi uygula:

```typescript
const solverLanguages = await userLanguageService.getUserLanguages(session.solver_id);
let filteredQuestions = questions;
if (solverLanguages.length > 0) {
  filteredQuestions = questions.filter((q: any) =>
    solverLanguages.includes(q.locale || 'tr')
  );
}
```

`current_q` index'ini `filteredQuestions` üzerinden hesapla.

**Step 4: answerQuestion()'daki tamamlama kontrolünü güncelle**

Son soru kontrolünde `filteredQuestions.length` kullan.

**Step 5: Commit**

```bash
git add server/src/services/quiz.service.ts
git commit -m "feat: filter quiz questions by solver's language preferences"
```

---

## Phase 7: Flutter — Constants & Models

### Task 10: Flutter Sabitleri ve Model Güncellemeleri

**Files:**
- Modify: `lib/core/constants/app_constants.dart`
- Modify: `lib/data/models/question_model.dart`
- Modify: `lib/data/models/discover_model.dart`

**Step 1: AppConstants'a desteklenen diller ekle**

`lib/core/constants/app_constants.dart` dosyasına ekle:

```dart
static const supportedQuestionLocales = [
  'tr', 'en', 'de', 'fr', 'es', 'ar', 'ru',
  'pt', 'it', 'ja', 'ko', 'zh', 'nl', 'pl', 'sv',
];

/// Locale code → flag emoji mapping
static const localeFlagEmojis = <String, String>{
  'tr': '🇹🇷', 'en': '🇬🇧', 'de': '🇩🇪', 'fr': '🇫🇷', 'es': '🇪🇸',
  'ar': '🇸🇦', 'ru': '🇷🇺', 'pt': '🇧🇷', 'it': '🇮🇹', 'ja': '🇯🇵',
  'ko': '🇰🇷', 'zh': '🇨🇳', 'nl': '🇳🇱', 'pl': '🇵🇱', 'sv': '🇸🇪',
};
```

**Step 2: QuestionModel'a locale ekle**

`lib/data/models/question_model.dart` dosyasında:

Field ekle (category'nin yanına):
```dart
final String? locale;
```

Constructor'a ekle:
```dart
this.locale,
```

`fromJson`/`toJson` otomatik (json_serializable). `build_runner` çalıştırılmalı.

**Step 3: QuestionInfoModel'a languages ekle**

`lib/data/models/discover_model.dart` dosyasında `QuestionInfoModel`'a:

Field ekle:
```dart
final List<String> languages;
```

Constructor'da default:
```dart
this.languages = const [],
```

**Step 4: build_runner çalıştır**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && dart run build_runner build --delete-conflicting-outputs
```

**Step 5: Commit**

```bash
git add lib/core/constants/app_constants.dart lib/data/models/question_model.dart lib/data/models/question_model.g.dart lib/data/models/discover_model.dart lib/data/models/discover_model.g.dart
git commit -m "feat: add locale to QuestionModel, languages to QuestionInfoModel, supported locales constant"
```

---

## Phase 8: Flutter — User Languages Provider & Service

### Task 11: User Languages API & Provider

**Files:**
- Modify: `lib/core/network/services/user_service.dart`
- Modify: `lib/data/repositories/user_repository.dart`
- Create: `lib/providers/user_languages_provider.dart`

**Step 1: User service'e endpoint ekle**

`lib/core/network/services/user_service.dart` dosyasına ekle:

```dart
@GET('/users/me/languages')
Future<Map<String, dynamic>> getUserLanguages();

@PUT('/users/me/languages')
Future<Map<String, dynamic>> setUserLanguages(@Body() Map<String, dynamic> body);
```

build_runner çalıştır:
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 2: User repository'e method ekle**

`lib/data/repositories/user_repository.dart` dosyasına ekle:

```dart
Future<Result<List<String>>> getUserLanguages() async {
  try {
    final response = await _service.getUserLanguages();
    final languages = List<String>.from(response['languages'] ?? []);
    return Result.success(languages);
  } on DioException catch (e) {
    return Result.failure(e.toAppFailure());
  }
}

Future<Result<List<String>>> setUserLanguages(List<String> languages) async {
  try {
    final response = await _service.setUserLanguages({'languages': languages});
    final result = List<String>.from(response['languages'] ?? []);
    return Result.success(result);
  } on DioException catch (e) {
    return Result.failure(e.toAppFailure());
  }
}
```

**Step 3: Provider oluştur**

`lib/providers/user_languages_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/repositories/user_repository.dart';
import '../providers/api_provider.dart';

part 'user_languages_provider.g.dart';

@riverpod
class UserLanguages extends _$UserLanguages {
  @override
  Future<List<String>> build() async {
    return [];
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.getUserLanguages();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (error) => AsyncError(error, StackTrace.current),
    );
  }

  Future<void> save(List<String> languages) async {
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.setUserLanguages(languages);
    result.when(
      success: (data) => state = AsyncData(data),
      failure: (error) => state = AsyncError(error, StackTrace.current),
    );
  }
}
```

**Not:** Eğer proje `riverpod_annotation` kullanmıyorsa (mevcut pattern `Notifier` + `NotifierProvider`), o zaman:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/user_repository.dart';
import '../providers/api_provider.dart';

class UserLanguagesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return [];
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.getUserLanguages();
    result.when(
      success: (data) => state = AsyncData(data),
      failure: (error) => state = AsyncError(error, StackTrace.current),
    );
  }

  Future<void> save(List<String> languages) async {
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.setUserLanguages(languages);
    result.when(
      success: (data) => state = AsyncData(data),
      failure: (error) => state = AsyncError(error, StackTrace.current),
    );
  }
}

final userLanguagesProvider =
    AsyncNotifierProvider<UserLanguagesNotifier, List<String>>(
  UserLanguagesNotifier.new,
);
```

**Step 4: build_runner çalıştır (Retrofit)**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 5: Commit**

```bash
git add lib/core/network/services/user_service.dart lib/core/network/services/user_service.g.dart lib/data/repositories/user_repository.dart lib/providers/user_languages_provider.dart
git commit -m "feat: add user languages API service, repository, and provider"
```

---

## Phase 9: Flutter — Language Picker Widget

### Task 12: Language Picker Bottom Sheet

**Files:**
- Create: `lib/core/widgets/language_picker_sheet.dart`

**Context:** Multi-select chip grid bottom sheet. Hem settings'te hem onboarding'de hem wizard'da kullanılacak.

**Step 1: Widget oluştur**

```dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../l10n/app_localizations.dart';

class LanguagePickerSheet extends StatefulWidget {
  final List<String> selectedLanguages;
  final bool multiSelect; // true = user prefs, false = single select for question locale

  const LanguagePickerSheet({
    super.key,
    required this.selectedLanguages,
    this.multiSelect = true,
  });

  @override
  State<LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<LanguagePickerSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.multiSelect
                ? context.tr('language_picker_title')
                : context.tr('language_picker_select_one'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.supportedQuestionLocales.map((locale) {
              final isSelected = _selected.contains(locale);
              final flag = AppConstants.localeFlagEmojis[locale] ?? '';
              return FilterChip(
                label: Text('$flag ${context.tr('locale_$locale')}'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (widget.multiSelect) {
                      if (selected) {
                        _selected.add(locale);
                      } else if (_selected.length > 1) {
                        _selected.remove(locale);
                      }
                    } else {
                      _selected = [locale];
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (widget.multiSelect)
            Text(
              context.tr('language_picker_hint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/widgets/language_picker_sheet.dart
git commit -m "feat: add LanguagePickerSheet widget for multi/single language selection"
```

---

## Phase 10: Flutter — Question Wizard Language Chip

### Task 13: Wizard'a Dil Chip'i Ekleme

**Files:**
- Modify: `lib/features/questions/screens/question_create_screen.dart`

**Context:** Step 1'de (soru metni + kategori) dil chip'i eklenir. App locale'den default gelir, tıklanınca LanguagePickerSheet açılır (single select mode).

**Step 1: State'e _selectedLocale ekle**

Mevcut state değişkenlerinin yanına:
```dart
late String _selectedLocale;
```

`initState()` veya `didChangeDependencies()`'da:
```dart
_selectedLocale = widget.editQuestion?.locale ?? Localizations.localeOf(context).languageCode;
// Eğer desteklenen dillerde değilse default 'tr'
if (!AppConstants.supportedQuestionLocales.contains(_selectedLocale)) {
  _selectedLocale = 'tr';
}
```

Eğer AI suggestion'dan geliyorsa (AiSuggestionModel), prefill locale'ini de al.

**Step 2: Step 1 UI'a dil chip'i ekle**

`_buildStepQuestion()` fonksiyonunda, kategori seçiminin üstüne dil chip'i ekle:

```dart
// Language chip
Row(
  children: [
    Text(context.tr('question_language'), style: theme.textTheme.titleSmall),
    const SizedBox(width: 8),
    ActionChip(
      avatar: Text(AppConstants.localeFlagEmojis[_selectedLocale] ?? '🌐'),
      label: Text(context.tr('locale_$_selectedLocale')),
      onPressed: () async {
        final result = await showModalBottomSheet<List<String>>(
          context: context,
          builder: (_) => LanguagePickerSheet(
            selectedLanguages: [_selectedLocale],
            multiSelect: false,
          ),
        );
        if (result != null && result.isNotEmpty) {
          setState(() => _selectedLocale = result.first);
        }
      },
    ),
  ],
),
const SizedBox(height: 16),
```

**Step 3: Save fonksiyonunda locale'i gönder**

Soru oluşturma/güncelleme data map'ine ekle:
```dart
'locale': _selectedLocale,
```

**Step 4: Commit**

```bash
git add lib/features/questions/screens/question_create_screen.dart
git commit -m "feat: add language chip to question wizard Step 1"
```

---

## Phase 11: Flutter — Easy Mode Language Integration

### Task 14: Easy Mode'da Dil Chip Entegrasyonu

**Files:**
- Modify: `lib/features/questions/screens/question_easy_mode_screen.dart`

**Context:** Easy mode'da mevcut `Localizations.localeOf(context).languageCode` kullanımı var. Buna ek olarak bir dil chip'i eklenir — kullanıcı değiştirirse AI suggestions o dilde gelir.

**Step 1: State'e _selectedLocale ekle**

```dart
late String _selectedLocale;
```

`initState()`'de:
```dart
_selectedLocale = Localizations.localeOf(context).languageCode;
if (!AppConstants.supportedQuestionLocales.contains(_selectedLocale)) {
  _selectedLocale = 'tr';
}
```

**Step 2: UI'a dil chip'i ekle (kategori seçiminin üstüne)**

```dart
// Language chip — same pattern as wizard
Row(
  children: [
    Text(context.tr('question_language')),
    const SizedBox(width: 8),
    ActionChip(
      avatar: Text(AppConstants.localeFlagEmojis[_selectedLocale] ?? '🌐'),
      label: Text(context.tr('locale_$_selectedLocale')),
      onPressed: () async {
        final result = await showModalBottomSheet<List<String>>(
          context: context,
          builder: (_) => LanguagePickerSheet(
            selectedLanguages: [_selectedLocale],
            multiSelect: false,
          ),
        );
        if (result != null && result.isNotEmpty) {
          setState(() => _selectedLocale = result.first);
        }
      },
    ),
  ],
),
```

**Step 3: AI suggestion fetch'lerinde _selectedLocale kullan**

Mevcut `final locale = Localizations.localeOf(context).languageCode;` satırını kaldır, yerine `_selectedLocale` kullan:

```dart
ref.read(aiSuggestionProvider.notifier).fetchSuggestions(
  category: category,
  locale: _selectedLocale,
);
```

**Step 4: Wizard'a navigate ederken locale'i de geçir**

AI suggestion seçilip wizard'a gidildiğinde, locale bilgisini de taşı.

**Step 5: Commit**

```bash
git add lib/features/questions/screens/question_easy_mode_screen.dart
git commit -m "feat: add language chip to easy mode, pass to AI suggestions"
```

---

## Phase 12: Flutter — Settings Language Preferences

### Task 15: Settings'e Dil Tercihleri Bölümü

**Files:**
- Modify: `lib/features/settings/screens/settings_screen.dart`

**Context:** Mevcut language toggle (TR/EN) altına "Soru Dilleri" bölümü eklenir. LanguagePickerSheet multi-select mode'da açılır.

**Step 1: Provider'ı watch et**

```dart
final languagesAsync = ref.watch(userLanguagesProvider);
```

**Step 2: Mevcut language toggle'ından sonra yeni ListTile ekle**

```dart
ListTile(
  leading: const Icon(Icons.translate),
  title: Text(context.tr('settings_question_languages')),
  subtitle: languagesAsync.when(
    data: (langs) => langs.isEmpty
        ? Text(context.tr('settings_question_languages_none'))
        : Text(langs.map((l) => '${AppConstants.localeFlagEmojis[l] ?? ''} ${context.tr('locale_$l')}').join(', ')),
    loading: () => const AppLoadingWidget.small(),
    error: (_, __) => Text(context.tr('error_generic')),
  ),
  trailing: const Icon(Icons.chevron_right),
  onTap: () async {
    final currentLangs = languagesAsync.valueOrNull ?? [];
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      builder: (_) => LanguagePickerSheet(
        selectedLanguages: currentLangs,
        multiSelect: true,
      ),
    );
    if (result != null) {
      ref.read(userLanguagesProvider.notifier).save(result);
    }
  },
),
```

**Step 3: initState'de fetch tetikle**

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  ref.read(userLanguagesProvider.notifier).fetch();
});
```

**Step 4: Commit**

```bash
git add lib/features/settings/screens/settings_screen.dart
git commit -m "feat: add question language preferences section to settings"
```

---

## Phase 13: Flutter — Onboarding Language Slide

### Task 16: Onboarding'e Dil Seçimi Slide'ı

**Files:**
- Modify: `lib/features/questions/screens/question_onboarding_screen.dart`

**Context:** Mevcut 3 slide'a 4. slide eklenir — dil seçimi. Chip grid doğrudan slide'da gömülü olur (bottom sheet değil).

**Step 1: 4. slide ekle (slide 3'ten sonra)**

Mevcut slides listesine 4. slide ekle:

```dart
// Slide 4 — Language selection
_buildLanguageSlide(context, theme),
```

**Step 2: _buildLanguageSlide metodu**

```dart
Widget _buildLanguageSlide(BuildContext context, ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        QIcon(QIcons.icGlobe, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          context.tr('onboarding_questions_slide4_title'),
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('onboarding_questions_slide4_desc'),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Inline chip grid for language selection
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: AppConstants.supportedQuestionLocales.map((locale) {
            final isSelected = _selectedLanguages.contains(locale);
            final flag = AppConstants.localeFlagEmojis[locale] ?? '';
            return FilterChip(
              label: Text('$flag ${context.tr('locale_$locale')}'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLanguages.add(locale);
                  } else if (_selectedLanguages.length > 1) {
                    _selectedLanguages.remove(locale);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    ),
  );
}
```

**Step 3: State'e _selectedLanguages ekle**

```dart
late List<String> _selectedLanguages;
```

initState'de app locale ile başlat:
```dart
final appLocale = Localizations.localeOf(context).languageCode;
_selectedLanguages = [AppConstants.supportedQuestionLocales.contains(appLocale) ? appLocale : 'tr'];
```

**Step 4: "Hemen Başla" butonunda kaydet**

Onboarding bittiğinde (son slide'da veya "Hemen Başla" tıklandığında):
```dart
ref.read(userLanguagesProvider.notifier).save(_selectedLanguages);
```

**Step 5: PageController page count'u 4 yap**

Dot indicator ve page count'u güncelle.

**Step 6: Commit**

```bash
git add lib/features/questions/screens/question_onboarding_screen.dart
git commit -m "feat: add language selection slide to question onboarding"
```

---

## Phase 14: Flutter — Discover Card & Questions Screen

### Task 17: Discover Kartında Dil Chip'leri

**Files:**
- Modify: `lib/features/discover/widgets/profile_card.dart`
- Modify: `lib/features/profile/screens/questions_screen.dart`

**Step 1: Profile card'da language chip'leri göster**

`_buildQuestionInfoSection()` fonksiyonunda, kategori chip'lerinin yanına dil chip'leri ekle:

```dart
// Language chips (after category chips)
if (info.languages.isNotEmpty) ...[
  const SizedBox(height: 4),
  Wrap(
    spacing: 4,
    children: info.languages.map((lang) => Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      label: Text(
        '${AppConstants.localeFlagEmojis[lang] ?? ''} ${lang.toUpperCase()}',
        style: theme.textTheme.labelSmall,
      ),
    )).toList(),
  ),
],
```

**Step 2: Questions screen'deki soru kartlarında locale göster**

`_QuestionCard` widget'ında, mevcut category tag'ının yanına locale chip'i ekle:

```dart
if (question.locale != null) ...[
  const SizedBox(width: 4),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      '${AppConstants.localeFlagEmojis[question.locale] ?? ''} ${question.locale!.toUpperCase()}',
      style: theme.textTheme.labelSmall,
    ),
  ),
],
```

**Step 3: Commit**

```bash
git add lib/features/discover/widgets/profile_card.dart lib/features/profile/screens/questions_screen.dart
git commit -m "feat: show language chips on discover card and question cards"
```

---

## Phase 15: Flutter — i18n Keys

### Task 18: Çeviri Anahtarları

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

**Context:** Tüm yeni özellikler için Türkçe ve İngilizce çeviri anahtarları eklenir.

**Step 1: Türkçe çeviriler ekle** (`_tr` map'inin sonuna)

```dart
// Language system
'question_language': 'Soru dili',
'language_picker_title': 'Hangi dillerde soru çözebilirsin?',
'language_picker_select_one': 'Soru dilini seç',
'language_picker_hint': 'En az bir dil seçili olmalı',
'settings_question_languages': 'Soru Dilleri',
'settings_question_languages_none': 'Henüz dil seçilmedi',
'onboarding_questions_slide4_title': 'Hangi Dilleri Biliyorsun?',
'onboarding_questions_slide4_desc': 'Sana uygun dillerdeki profilleri gösterelim. Birden fazla seçebilirsin!',

// Locale names
'locale_tr': 'Türkçe',
'locale_en': 'English',
'locale_de': 'Deutsch',
'locale_fr': 'Français',
'locale_es': 'Español',
'locale_ar': 'العربية',
'locale_ru': 'Русский',
'locale_pt': 'Português',
'locale_it': 'Italiano',
'locale_ja': '日本語',
'locale_ko': '한국어',
'locale_zh': '中文',
'locale_nl': 'Nederlands',
'locale_pl': 'Polski',
'locale_sv': 'Svenska',
```

**Step 2: İngilizce çeviriler ekle** (`_en` map'inin sonuna)

```dart
// Language system
'question_language': 'Question language',
'language_picker_title': 'Which languages can you answer questions in?',
'language_picker_select_one': 'Select question language',
'language_picker_hint': 'At least one language must be selected',
'settings_question_languages': 'Question Languages',
'settings_question_languages_none': 'No languages selected yet',
'onboarding_questions_slide4_title': 'Which Languages Do You Know?',
'onboarding_questions_slide4_desc': 'We\'ll show you profiles with questions in your languages. You can select multiple!',

// Locale names (same in both languages — native names)
'locale_tr': 'Türkçe',
'locale_en': 'English',
'locale_de': 'Deutsch',
'locale_fr': 'Français',
'locale_es': 'Español',
'locale_ar': 'العربية',
'locale_ru': 'Русский',
'locale_pt': 'Português',
'locale_it': 'Italiano',
'locale_ja': '日本語',
'locale_ko': '한국어',
'locale_zh': '中文',
'locale_nl': 'Nederlands',
'locale_pl': 'Polski',
'locale_sv': 'Svenska',
```

**Step 3: Commit**

```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "feat: add i18n keys for language system (30 keys, TR + EN)"
```

---

## Phase 16: Compilation & Verification

### Task 19: Backend Derleme Kontrolü

**Files:** Tüm backend dosyaları

**Step 1: TypeScript derle**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2/server && npx tsc --noEmit
```

Expected: No errors.

**Step 2: Hataları düzelt** (varsa)

**Step 3: Commit** (fix varsa)

### Task 20: Flutter Derleme Kontrolü

**Files:** Tüm Flutter dosyaları

**Step 1: build_runner çalıştır**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && dart run build_runner build --delete-conflicting-outputs
```

**Step 2: Dart analyze**

```bash
flutter analyze
```

Expected: No errors.

**Step 3: Hataları düzelt** (varsa)

**Step 4: Commit** (fix varsa)

```bash
git commit -am "fix: resolve compilation errors for language system"
```

---

## Özet

| Phase | Task | Açıklama |
|-------|------|----------|
| 1 | 1 | DB Migration 011 — user_languages + questions.locale |
| 2 | 2-3 | Backend sabitleri + validator güncellemeleri |
| 3 | 4-6 | User language service, routes, register entegrasyonu |
| 4 | 7 | Question service locale desteği |
| 5 | 8 | Discover dil filtresi (2+ ortak dil sorusu) |
| 6 | 9 | Quiz dil bazlı soru filtreleme |
| 7 | 10 | Flutter sabitleri + model güncellemeleri |
| 8 | 11 | User languages API, repository, provider |
| 9 | 12 | Language picker bottom sheet widget |
| 10 | 13 | Wizard'a dil chip'i |
| 11 | 14 | Easy mode dil chip entegrasyonu |
| 12 | 15 | Settings dil tercihleri bölümü |
| 13 | 16 | Onboarding dil slide'ı |
| 14 | 17 | Discover kart + soru listesi dil chip'leri |
| 15 | 18 | i18n anahtarları (30 key, TR + EN) |
| 16 | 19-20 | Backend + Flutter derleme kontrolü |

**Toplam: 20 task, 16 phase**
