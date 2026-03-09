# Qulo V2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a quiz-based dating app with Node.js+Express backend, Supabase DB, and Flutter+Riverpod mobile client.

**Architecture:** Monolithic Express+TS backend connects to Supabase PostgreSQL for data, Supabase Realtime for chat, Firebase for push notifications. Flutter mobile app communicates exclusively through REST API. All critical operations (diamonds, matching, quiz) are server-side.

**Tech Stack:** Node.js, Express, TypeScript, Supabase (PostgreSQL + Realtime + Storage), Firebase (FCM + Crashlytics), Flutter, Riverpod, Dio, Zod

**Design Doc:** `docs/plans/2026-03-07-qulo-v2-design.md`

---

## Phase 1: Backend Foundation

### Task 1: Initialize Node.js + Express + TypeScript Project

**Files:**
- Create: `server/package.json`
- Create: `server/tsconfig.json`
- Create: `server/.env.example`
- Create: `server/.gitignore`
- Create: `server/src/index.ts`
- Create: `server/src/config/env.ts`

**Step 1: Initialize project**

```bash
cd server
npm init -y
npm install express cors helmet dotenv @supabase/supabase-js zod bcryptjs jsonwebtoken express-rate-limit
npm install -D typescript @types/node @types/express @types/cors @types/bcryptjs @types/jsonwebtoken ts-node nodemon tsx
npx tsc --init
```

**Step 2: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

**Step 3: Create env config**

```typescript
// server/src/config/env.ts
import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.string().default('3000'),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  FIREBASE_SERVICE_ACCOUNT: z.string().min(1),
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.string().optional(),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  APP_URL: z.string().url().default('http://localhost:3000'),
});

export const env = envSchema.parse(process.env);
```

**Step 4: Create Express app entry**

```typescript
// server/src/index.ts
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './config/env.js';

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(Number(env.PORT), () => {
  console.log(`Server running on port ${env.PORT}`);
});

export default app;
```

**Step 5: Add scripts to package.json**

```json
{
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "vitest"
  }
}
```

**Step 6: Create .env.example and .gitignore**

```env
# server/.env.example
PORT=3000
NODE_ENV=development
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxx
JWT_ACCESS_SECRET=change-me-min-32-chars-long-secret
JWT_REFRESH_SECRET=change-me-min-32-chars-long-secret
FIREBASE_SERVICE_ACCOUNT={}
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
APP_URL=http://localhost:3000
```

```gitignore
# server/.gitignore
node_modules/
dist/
.env
*.log
```

**Step 7: Test health endpoint**

```bash
cd server && npm run dev
# In another terminal:
curl http://localhost:3000/health
# Expected: {"status":"ok","timestamp":"..."}
```

**Step 8: Commit**

```bash
git add server/
git commit -m "feat(server): initialize Express + TypeScript project with config"
```

---

### Task 2: Supabase Client + Firebase Admin Setup

**Files:**
- Create: `server/src/config/supabase.ts`
- Create: `server/src/config/firebase.ts`

**Step 1: Create Supabase client**

```typescript
// server/src/config/supabase.ts
import { createClient } from '@supabase/supabase-js';
import { env } from './env.js';

export const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
```

**Step 2: Install Firebase Admin and create config**

```bash
cd server && npm install firebase-admin
```

```typescript
// server/src/config/firebase.ts
import admin from 'firebase-admin';
import { env } from './env.js';

const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export const firebaseAdmin = admin;
export const fcm = admin.messaging();
```

**Step 3: Commit**

```bash
git add server/src/config/
git commit -m "feat(server): add Supabase client and Firebase Admin SDK setup"
```

---

### Task 3: Database Migrations

**Files:**
- Create: `supabase/migrations/001_initial_schema.sql`
- Create: `supabase/migrations/002_postgis_and_indexes.sql`
- Create: `supabase/migrations/003_seed_powers_and_iap.sql`

**Step 1: Create initial schema migration**

```sql
-- supabase/migrations/001_initial_schema.sql

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Enums
CREATE TYPE gender_type AS ENUM ('MAN', 'WOMAN');
CREATE TYPE gender_pref_type AS ENUM ('MAN', 'WOMAN', 'BOTH');
CREATE TYPE frequency_type AS ENUM ('YES', 'NO', 'SOMETIMES');
CREATE TYPE swipe_action AS ENUM ('LIKE', 'REJECT');
CREATE TYPE quiz_status AS ENUM ('IN_PROGRESS', 'COMPLETED', 'FAILED');
CREATE TYPE diamond_type AS ENUM ('GREEN', 'PURPLE');
CREATE TYPE report_status AS ENUM ('PENDING', 'REVIEWED', 'RESOLVED');

-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  email_verified BOOLEAN DEFAULT false,
  verify_token TEXT,
  name TEXT NOT NULL,
  surname TEXT NOT NULL,
  age INT NOT NULL CHECK (age >= 18 AND age <= 99),
  gender gender_type NOT NULL,
  gender_pref gender_pref_type NOT NULL DEFAULT 'BOTH',
  bio TEXT,
  city TEXT,
  country TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  match_radius_km INT DEFAULT 50 CHECK (match_radius_km >= 1 AND match_radius_km <= 500),
  age_pref_min INT DEFAULT 18 CHECK (age_pref_min >= 18),
  age_pref_max INT DEFAULT 45 CHECK (age_pref_max <= 99),
  photos TEXT[] DEFAULT '{}',
  green_diamonds INT DEFAULT 0 CHECK (green_diamonds >= 0),
  purple_diamonds INT DEFAULT 0 CHECK (purple_diamonds >= 0),
  is_online BOOLEAN DEFAULT false,
  push_token TEXT,
  passport_city TEXT,
  passport_lat DOUBLE PRECISION,
  passport_lng DOUBLE PRECISION,
  profile_completion INT DEFAULT 0 CHECK (profile_completion >= 0 AND profile_completion <= 100),
  locale TEXT DEFAULT 'tr' CHECK (locale IN ('tr', 'en')),
  like_received_count INT DEFAULT 0,
  times_shown_count INT DEFAULT 0,
  boost_until TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  last_seen_at TIMESTAMPTZ DEFAULT now()
);

-- User Details (optional profile)
CREATE TABLE user_details (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  height INT,
  weight INT,
  zodiac TEXT,
  job TEXT,
  school TEXT,
  smoking frequency_type,
  alcohol frequency_type,
  pets TEXT,
  music_type TEXT,
  personality TEXT
);

-- Questions
CREATE TABLE questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  order_num INT NOT NULL CHECK (order_num >= 1 AND order_num <= 6),
  question_text TEXT NOT NULL,
  correct_answer INT NOT NULL CHECK (correct_answer >= 1 AND correct_answer <= 4),
  answer_1 TEXT NOT NULL,
  answer_2 TEXT NOT NULL,
  answer_3 TEXT NOT NULL,
  answer_4 TEXT NOT NULL,
  hint_text TEXT,
  stats_correct INT DEFAULT 0,
  stats_wrong INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, order_num)
);

-- Swipes
CREATE TABLE swipes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  swiper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action swipe_action NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(swiper_id, target_id)
);

-- Quiz Sessions
CREATE TABLE quiz_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  solver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  current_q INT DEFAULT 1,
  status quiz_status DEFAULT 'IN_PROGRESS',
  started_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL
);

-- Quiz Answers
CREATE TABLE quiz_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  selected_answer INT NOT NULL CHECK (selected_answer >= 1 AND selected_answer <= 4),
  is_correct BOOLEAN NOT NULL,
  power_used TEXT,
  answered_at TIMESTAMPTZ DEFAULT now()
);

-- Matches
CREATE TABLE matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  matched_at TIMESTAMPTZ DEFAULT now(),
  is_active BOOLEAN DEFAULT true,
  UNIQUE(user1_id, user2_id)
);

-- Messages
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_image BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Diamond Transactions
CREATE TABLE diamond_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type diamond_type NOT NULL,
  amount INT NOT NULL,
  reason TEXT NOT NULL,
  reference_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Powers
CREATE TABLE powers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  base_cost INT NOT NULL,
  description TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true
);

-- IAP Products
CREATE TABLE iap_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id_android TEXT NOT NULL,
  store_id_ios TEXT NOT NULL,
  purple_amount INT NOT NULL,
  tier INT NOT NULL CHECK (tier >= 1 AND tier <= 6),
  is_active BOOLEAN DEFAULT true
);

-- Reports
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reported_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  status report_status DEFAULT 'PENDING',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Refresh Tokens
CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Disable RLS (using service_role key from backend)
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_details DISABLE ROW LEVEL SECURITY;
ALTER TABLE questions DISABLE ROW LEVEL SECURITY;
ALTER TABLE swipes DISABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_answers DISABLE ROW LEVEL SECURITY;
ALTER TABLE matches DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE diamond_transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE powers DISABLE ROW LEVEL SECURITY;
ALTER TABLE iap_products DISABLE ROW LEVEL SECURITY;
ALTER TABLE reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens DISABLE ROW LEVEL SECURITY;
```

**Step 2: Create indexes migration**

```sql
-- supabase/migrations/002_postgis_and_indexes.sql

-- Spatial index for location-based queries
CREATE INDEX idx_users_location ON users USING GIST (
  ST_MakePoint(lng, lat)::geography
) WHERE lat IS NOT NULL AND lng IS NOT NULL;

-- Performance indexes
CREATE INDEX idx_users_gender ON users(gender) WHERE is_deleted = false;
CREATE INDEX idx_users_age ON users(age) WHERE is_deleted = false;
CREATE INDEX idx_users_last_seen ON users(last_seen_at DESC) WHERE is_deleted = false;
CREATE INDEX idx_users_boost ON users(boost_until) WHERE boost_until IS NOT NULL;
CREATE INDEX idx_users_email ON users(email);

CREATE INDEX idx_swipes_swiper ON swipes(swiper_id);
CREATE INDEX idx_swipes_target ON swipes(target_id);

CREATE INDEX idx_questions_user ON questions(user_id);

CREATE INDEX idx_quiz_sessions_solver ON quiz_sessions(solver_id);
CREATE INDEX idx_quiz_sessions_target ON quiz_sessions(target_id);
CREATE INDEX idx_quiz_sessions_status ON quiz_sessions(status) WHERE status = 'IN_PROGRESS';

CREATE INDEX idx_matches_user1 ON matches(user1_id) WHERE is_active = true;
CREATE INDEX idx_matches_user2 ON matches(user2_id) WHERE is_active = true;

CREATE INDEX idx_messages_match ON messages(match_id, created_at DESC);
CREATE INDEX idx_messages_unread ON messages(match_id, sender_id) WHERE read_at IS NULL;

CREATE INDEX idx_diamond_transactions_user ON diamond_transactions(user_id, created_at DESC);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);

CREATE INDEX idx_reports_reported ON reports(reported_id) WHERE status = 'PENDING';
```

**Step 3: Create seed data migration**

```sql
-- supabase/migrations/003_seed_powers_and_iap.sql

-- Seed powers
INSERT INTO powers (name, base_cost, description) VALUES
  ('COPY', 15, 'Shows the correct answer for 3 seconds'),
  ('HALF', 10, 'Removes 2 wrong answer options'),
  ('SKIP', 20, 'Marks this question as correct and skips'),
  ('SKIP_ALL', 60, 'Skips all questions and matches directly'),
  ('TIME_EXTEND', 5, 'Adds 15 extra seconds to the timer'),
  ('HINT', 8, 'Shows the hint text written by the question owner');

-- Seed IAP products
INSERT INTO iap_products (store_id_android, store_id_ios, purple_amount, tier) VALUES
  ('qulo_purple_30', 'qulo_purple_30', 30, 1),
  ('qulo_purple_80', 'qulo_purple_80', 80, 2),
  ('qulo_purple_180', 'qulo_purple_180', 180, 3),
  ('qulo_purple_400', 'qulo_purple_400', 400, 4),
  ('qulo_purple_900', 'qulo_purple_900', 900, 5),
  ('qulo_purple_2000', 'qulo_purple_2000', 2000, 6);
```

**Step 4: Run migrations in Supabase SQL Editor**

User runs these 3 SQL files in Supabase Dashboard > SQL Editor, in order.

**Step 5: Commit**

```bash
git add supabase/
git commit -m "feat(db): add initial schema, indexes, PostGIS, and seed data"
```

---

### Task 4: Shared Types + Error Handling + Middleware

**Files:**
- Create: `server/src/types/index.ts`
- Create: `server/src/utils/errors.ts`
- Create: `server/src/middleware/errorHandler.ts`
- Create: `server/src/middleware/validate.ts`
- Create: `server/src/middleware/rateLimit.ts`

**Step 1: Create shared types**

```typescript
// server/src/types/index.ts
export interface JwtPayload {
  userId: string;
  email: string;
}

export interface AuthenticatedRequest extends Express.Request {
  user?: JwtPayload;
}

export type PowerName = 'COPY' | 'HALF' | 'SKIP' | 'SKIP_ALL' | 'TIME_EXTEND' | 'HINT';

export const QUESTION_COUNT_MULTIPLIERS: Record<number, number> = {
  2: 0.5,
  3: 0.75,
  4: 1.0,
  5: 1.25,
  6: 1.5,
};

export const GREEN_DIAMOND_REWARD_RATIO = 0.30;
```

**Step 2: Create error utilities**

```typescript
// server/src/utils/errors.ts
export class AppError extends Error {
  constructor(
    public code: string,
    public statusCode: number,
    public params?: Record<string, unknown>
  ) {
    super(code);
  }
}

export const Errors = {
  // Auth
  INVALID_CREDENTIALS: () => new AppError('INVALID_CREDENTIALS', 401),
  EMAIL_NOT_VERIFIED: () => new AppError('EMAIL_NOT_VERIFIED', 403),
  EMAIL_ALREADY_EXISTS: () => new AppError('EMAIL_ALREADY_EXISTS', 409),
  TOKEN_EXPIRED: () => new AppError('TOKEN_EXPIRED', 401),
  INVALID_TOKEN: () => new AppError('INVALID_TOKEN', 401),

  // Quiz
  SESSION_EXPIRED: () => new AppError('SESSION_EXPIRED', 410),
  TIME_UP: () => new AppError('TIME_UP', 410),
  ALREADY_ANSWERED: () => new AppError('ALREADY_ANSWERED', 409),
  SESSION_NOT_FOUND: () => new AppError('SESSION_NOT_FOUND', 404),

  // Diamond
  INSUFFICIENT_DIAMONDS: (required: number, current: number) =>
    new AppError('INSUFFICIENT_DIAMONDS', 403, { required, current }),
  INVALID_RECEIPT: () => new AppError('INVALID_RECEIPT', 400),
  DUPLICATE_RECEIPT: () => new AppError('DUPLICATE_RECEIPT', 409),

  // Match
  ALREADY_SWIPED: () => new AppError('ALREADY_SWIPED', 409),
  NO_QUESTIONS: () => new AppError('NO_QUESTIONS', 400),
  SELF_SWIPE: () => new AppError('SELF_SWIPE', 400),

  // Chat
  NOT_MATCHED: () => new AppError('NOT_MATCHED', 403),
  MATCH_INACTIVE: () => new AppError('MATCH_INACTIVE', 403),

  // User
  PROFILE_INCOMPLETE: () => new AppError('PROFILE_INCOMPLETE', 400),
  MAX_PHOTOS_REACHED: () => new AppError('MAX_PHOTOS_REACHED', 400),
  MAX_QUESTIONS_REACHED: () => new AppError('MAX_QUESTIONS_REACHED', 400),
  USER_NOT_FOUND: () => new AppError('USER_NOT_FOUND', 404),

  // General
  RATE_LIMITED: () => new AppError('RATE_LIMITED', 429),
  VALIDATION_ERROR: (details: unknown) => new AppError('VALIDATION_ERROR', 400, { details }),
  SERVER_ERROR: () => new AppError('SERVER_ERROR', 500),
};
```

**Step 3: Create middleware**

```typescript
// server/src/middleware/errorHandler.ts
import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/errors.js';

export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      error: { code: err.code, params: err.params },
    });
    return;
  }
  console.error('Unhandled error:', err);
  res.status(500).json({ error: { code: 'SERVER_ERROR' } });
}
```

```typescript
// server/src/middleware/validate.ts
import { Request, Response, NextFunction } from 'express';
import { ZodSchema } from 'zod';
import { Errors } from '../utils/errors.js';

export function validate(schema: ZodSchema, source: 'body' | 'query' | 'params' = 'body') {
  return (req: Request, _res: Response, next: NextFunction) => {
    const result = schema.safeParse(req[source]);
    if (!result.success) {
      throw Errors.VALIDATION_ERROR(result.error.flatten());
    }
    req[source] = result.data;
    next();
  };
}
```

```typescript
// server/src/middleware/rateLimit.ts
import rateLimit from 'express-rate-limit';

export const authLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  message: { error: { code: 'RATE_LIMITED' } },
});

export const discoverLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  message: { error: { code: 'RATE_LIMITED' } },
});

export const chatLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  message: { error: { code: 'RATE_LIMITED' } },
});

export const generalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  message: { error: { code: 'RATE_LIMITED' } },
});
```

**Step 4: Commit**

```bash
git add server/src/types/ server/src/utils/ server/src/middleware/
git commit -m "feat(server): add types, error handling, and middleware (validate, rateLimit)"
```

---

## Phase 2: Auth Module

### Task 5: JWT Utilities + Password Hashing

**Files:**
- Create: `server/src/utils/jwt.ts`
- Create: `server/src/utils/hash.ts`
- Create: `server/src/middleware/auth.ts`

**Step 1: Create JWT utility**

```typescript
// server/src/utils/jwt.ts
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import type { JwtPayload } from '../types/index.js';

export function signAccessToken(payload: JwtPayload): string {
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, { expiresIn: '15m' });
}

export function signRefreshToken(payload: JwtPayload): string {
  return jwt.sign(payload, env.JWT_REFRESH_SECRET, { expiresIn: '30d' });
}

export function verifyAccessToken(token: string): JwtPayload {
  return jwt.verify(token, env.JWT_ACCESS_SECRET) as JwtPayload;
}

export function verifyRefreshToken(token: string): JwtPayload {
  return jwt.verify(token, env.JWT_REFRESH_SECRET) as JwtPayload;
}
```

**Step 2: Create hash utility**

```typescript
// server/src/utils/hash.ts
import bcrypt from 'bcryptjs';
import crypto from 'crypto';

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}

export async function comparePassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function generateToken(): string {
  return crypto.randomBytes(32).toString('hex');
}
```

**Step 3: Create auth middleware**

```typescript
// server/src/middleware/auth.ts
import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../utils/jwt.js';
import { Errors } from '../utils/errors.js';
import type { JwtPayload } from '../types/index.js';

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

export function authenticate(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    throw Errors.INVALID_TOKEN();
  }
  try {
    const token = header.split(' ')[1];
    req.user = verifyAccessToken(token);
    next();
  } catch {
    throw Errors.TOKEN_EXPIRED();
  }
}
```

**Step 4: Commit**

```bash
git add server/src/utils/jwt.ts server/src/utils/hash.ts server/src/middleware/auth.ts
git commit -m "feat(server): add JWT, password hashing, and auth middleware"
```

---

### Task 6: Email Utility

**Files:**
- Create: `server/src/utils/email.ts`

**Step 1: Install nodemailer**

```bash
cd server && npm install nodemailer && npm install -D @types/nodemailer
```

**Step 2: Create email utility**

```typescript
// server/src/utils/email.ts
import nodemailer from 'nodemailer';
import { env } from '../config/env.js';

const transporter = nodemailer.createTransport({
  host: env.SMTP_HOST,
  port: Number(env.SMTP_PORT),
  secure: false,
  auth: {
    user: env.SMTP_USER,
    pass: env.SMTP_PASS,
  },
});

export async function sendVerificationEmail(to: string, token: string, locale: string) {
  const verifyUrl = `${env.APP_URL}/api/v1/auth/verify-email?token=${token}`;

  const subjects: Record<string, string> = {
    tr: 'Qulo - Email Dogrulama',
    en: 'Qulo - Email Verification',
  };

  const bodies: Record<string, string> = {
    tr: `<h2>Qulo'ya Hosgeldiniz!</h2><p>Email adresinizi dogrulamak icin <a href="${verifyUrl}">buraya tiklayin</a>.</p>`,
    en: `<h2>Welcome to Qulo!</h2><p>Click <a href="${verifyUrl}">here</a> to verify your email.</p>`,
  };

  await transporter.sendMail({
    from: '"Qulo" <noreply@qulo.app>',
    to,
    subject: subjects[locale] || subjects['en'],
    html: bodies[locale] || bodies['en'],
  });
}

export async function sendPasswordResetEmail(to: string, token: string, locale: string) {
  const resetUrl = `${env.APP_URL}/reset-password?token=${token}`;

  const subjects: Record<string, string> = {
    tr: 'Qulo - Sifre Sifirlama',
    en: 'Qulo - Password Reset',
  };

  const bodies: Record<string, string> = {
    tr: `<h2>Sifre Sifirlama</h2><p>Sifrenizi sifirlamak icin <a href="${resetUrl}">buraya tiklayin</a>.</p>`,
    en: `<h2>Password Reset</h2><p>Click <a href="${resetUrl}">here</a> to reset your password.</p>`,
  };

  await transporter.sendMail({
    from: '"Qulo" <noreply@qulo.app>',
    to,
    subject: subjects[locale] || subjects['en'],
    html: bodies[locale] || bodies['en'],
  });
}
```

**Step 3: Commit**

```bash
git add server/src/utils/email.ts server/package.json server/package-lock.json
git commit -m "feat(server): add email utility with i18n support"
```

---

### Task 7: Auth Service + Routes + Controller

**Files:**
- Create: `server/src/services/auth.service.ts`
- Create: `server/src/validators/auth.validator.ts`
- Create: `server/src/controllers/auth.controller.ts`
- Create: `server/src/routes/auth.routes.ts`
- Modify: `server/src/index.ts` (register routes)

**Step 1: Create auth validator**

```typescript
// server/src/validators/auth.validator.ts
import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(100),
  name: z.string().min(1).max(50),
  surname: z.string().min(1).max(50),
  age: z.number().int().min(18).max(99),
  gender: z.enum(['MAN', 'WOMAN']),
  locale: z.enum(['tr', 'en']).default('tr'),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

export const verifyEmailSchema = z.object({
  token: z.string().min(1),
});

export const forgotPasswordSchema = z.object({
  email: z.string().email(),
});

export const resetPasswordSchema = z.object({
  token: z.string().min(1),
  password: z.string().min(8).max(100),
});
```

**Step 2: Create auth service**

```typescript
// server/src/services/auth.service.ts
import { supabase } from '../config/supabase.js';
import { hashPassword, comparePassword, hashToken, generateToken } from '../utils/hash.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../utils/jwt.js';
import { sendVerificationEmail, sendPasswordResetEmail } from '../utils/email.js';
import { Errors } from '../utils/errors.js';
import type { JwtPayload } from '../types/index.js';

export class AuthService {
  async register(data: {
    email: string; password: string; name: string; surname: string;
    age: number; gender: string; locale: string;
  }) {
    const { data: existing } = await supabase
      .from('users').select('id').eq('email', data.email).single();
    if (existing) throw Errors.EMAIL_ALREADY_EXISTS();

    const password_hash = await hashPassword(data.password);
    const verify_token = generateToken();

    const { data: user, error } = await supabase.from('users').insert({
      email: data.email,
      password_hash,
      verify_token: hashToken(verify_token),
      name: data.name,
      surname: data.surname,
      age: data.age,
      gender: data.gender,
      locale: data.locale,
    }).select('id, email').single();

    if (error) throw Errors.SERVER_ERROR();

    await sendVerificationEmail(data.email, verify_token, data.locale);

    return { userId: user!.id, email: user!.email };
  }

  async verifyEmail(token: string) {
    const tokenHash = hashToken(token);
    const { data: user, error } = await supabase
      .from('users')
      .update({ email_verified: true, verify_token: null })
      .eq('verify_token', tokenHash)
      .eq('email_verified', false)
      .select('id')
      .single();

    if (error || !user) throw Errors.INVALID_TOKEN();
    return { verified: true };
  }

  async login(email: string, password: string) {
    const { data: user } = await supabase
      .from('users')
      .select('id, email, password_hash, email_verified, is_deleted')
      .eq('email', email)
      .single();

    if (!user || user.is_deleted) throw Errors.INVALID_CREDENTIALS();
    if (!user.email_verified) throw Errors.EMAIL_NOT_VERIFIED();

    const valid = await comparePassword(password, user.password_hash);
    if (!valid) throw Errors.INVALID_CREDENTIALS();

    const payload: JwtPayload = { userId: user.id, email: user.email };
    const accessToken = signAccessToken(payload);
    const refreshToken = signRefreshToken(payload);

    await supabase.from('refresh_tokens').insert({
      user_id: user.id,
      token_hash: hashToken(refreshToken),
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    });

    await supabase.from('users').update({ last_seen_at: new Date().toISOString(), is_online: true }).eq('id', user.id);

    return { accessToken, refreshToken, userId: user.id };
  }

  async refresh(refreshToken: string) {
    let payload: JwtPayload;
    try {
      payload = verifyRefreshToken(refreshToken);
    } catch {
      throw Errors.TOKEN_EXPIRED();
    }

    const tokenHash = hashToken(refreshToken);
    const { data: stored } = await supabase
      .from('refresh_tokens')
      .select('id')
      .eq('token_hash', tokenHash)
      .eq('user_id', payload.userId)
      .single();

    if (!stored) throw Errors.INVALID_TOKEN();

    // Rotate: delete old, create new
    await supabase.from('refresh_tokens').delete().eq('id', stored.id);

    const newAccessToken = signAccessToken(payload);
    const newRefreshToken = signRefreshToken(payload);

    await supabase.from('refresh_tokens').insert({
      user_id: payload.userId,
      token_hash: hashToken(newRefreshToken),
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    });

    return { accessToken: newAccessToken, refreshToken: newRefreshToken };
  }

  async logout(userId: string, refreshToken: string) {
    const tokenHash = hashToken(refreshToken);
    await supabase.from('refresh_tokens').delete().eq('token_hash', tokenHash).eq('user_id', userId);
    await supabase.from('users').update({ is_online: false }).eq('id', userId);
  }

  async forgotPassword(email: string) {
    const { data: user } = await supabase
      .from('users').select('id, locale').eq('email', email).eq('is_deleted', false).single();
    if (!user) return; // Don't reveal if email exists

    const token = generateToken();
    await supabase.from('users').update({ verify_token: hashToken(token) }).eq('id', user.id);
    await sendPasswordResetEmail(email, token, user.locale);
  }

  async resetPassword(token: string, newPassword: string) {
    const tokenHash = hashToken(token);
    const password_hash = await hashPassword(newPassword);

    const { data: user, error } = await supabase
      .from('users')
      .update({ password_hash, verify_token: null })
      .eq('verify_token', tokenHash)
      .select('id')
      .single();

    if (error || !user) throw Errors.INVALID_TOKEN();

    // Invalidate all refresh tokens
    await supabase.from('refresh_tokens').delete().eq('user_id', user.id);
  }
}

export const authService = new AuthService();
```

**Step 3: Create auth controller**

```typescript
// server/src/controllers/auth.controller.ts
import { Request, Response, NextFunction } from 'express';
import { authService } from '../services/auth.service.js';

export class AuthController {
  async register(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.register(req.body);
      res.status(201).json(result);
    } catch (e) { next(e); }
  }

  async verifyEmail(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.verifyEmail(req.query.token as string);
      res.json(result);
    } catch (e) { next(e); }
  }

  async login(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.login(req.body.email, req.body.password);
      res.json(result);
    } catch (e) { next(e); }
  }

  async refresh(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.refresh(req.body.refreshToken);
      res.json(result);
    } catch (e) { next(e); }
  }

  async logout(req: Request, res: Response, next: NextFunction) {
    try {
      await authService.logout(req.user!.userId, req.body.refreshToken);
      res.json({ success: true });
    } catch (e) { next(e); }
  }

  async forgotPassword(req: Request, res: Response, next: NextFunction) {
    try {
      await authService.forgotPassword(req.body.email);
      res.json({ success: true });
    } catch (e) { next(e); }
  }

  async resetPassword(req: Request, res: Response, next: NextFunction) {
    try {
      await authService.resetPassword(req.body.token, req.body.password);
      res.json({ success: true });
    } catch (e) { next(e); }
  }
}

export const authController = new AuthController();
```

**Step 4: Create auth routes**

```typescript
// server/src/routes/auth.routes.ts
import { Router } from 'express';
import { authController } from '../controllers/auth.controller.js';
import { validate } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
import { authLimiter } from '../middleware/rateLimit.js';
import {
  registerSchema, loginSchema, refreshSchema,
  verifyEmailSchema, forgotPasswordSchema, resetPasswordSchema
} from '../validators/auth.validator.js';

const router = Router();

router.post('/register', authLimiter, validate(registerSchema), authController.register);
router.get('/verify-email', validate(verifyEmailSchema, 'query'), authController.verifyEmail);
router.post('/login', authLimiter, validate(loginSchema), authController.login);
router.post('/refresh', validate(refreshSchema), authController.refresh);
router.post('/logout', authenticate, authController.logout);
router.post('/forgot-password', authLimiter, validate(forgotPasswordSchema), authController.forgotPassword);
router.post('/reset-password', validate(resetPasswordSchema), authController.resetPassword);

export default router;
```

**Step 5: Register routes in index.ts**

```typescript
// server/src/index.ts - updated
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './config/env.js';
import { errorHandler } from './middleware/errorHandler.js';
import authRoutes from './routes/auth.routes.js';

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes
app.use('/api/v1/auth', authRoutes);

// Error handler (must be last)
app.use(errorHandler);

app.listen(Number(env.PORT), () => {
  console.log(`Server running on port ${env.PORT}`);
});

export default app;
```

**Step 6: Test auth endpoints**

```bash
# Register
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test1234!","name":"Test","surname":"User","age":25,"gender":"MAN"}'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test1234!"}'
```

**Step 7: Commit**

```bash
git add server/src/
git commit -m "feat(server): implement auth module (register, login, verify, refresh, logout, password reset)"
```

---

## Phase 3: User & Profile Module

### Task 8: User Service + Routes

**Files:**
- Create: `server/src/services/user.service.ts`
- Create: `server/src/validators/user.validator.ts`
- Create: `server/src/controllers/user.controller.ts`
- Create: `server/src/routes/user.routes.ts`
- Modify: `server/src/index.ts` (register route)

**Step 1: Create user validator**

```typescript
// server/src/validators/user.validator.ts
import { z } from 'zod';

export const updateProfileSchema = z.object({
  name: z.string().min(1).max(50).optional(),
  surname: z.string().min(1).max(50).optional(),
  bio: z.string().max(500).optional(),
  age: z.number().int().min(18).max(99).optional(),
  gender_pref: z.enum(['MAN', 'WOMAN', 'BOTH']).optional(),
  match_radius_km: z.number().int().min(1).max(500).optional(),
  age_pref_min: z.number().int().min(18).max(99).optional(),
  age_pref_max: z.number().int().min(18).max(99).optional(),
  city: z.string().max(100).optional(),
  country: z.string().max(100).optional(),
  locale: z.enum(['tr', 'en']).optional(),
});

export const updateDetailsSchema = z.object({
  height: z.number().int().min(100).max(250).nullable().optional(),
  weight: z.number().int().min(30).max(300).nullable().optional(),
  zodiac: z.string().max(30).nullable().optional(),
  job: z.string().max(100).nullable().optional(),
  school: z.string().max(100).nullable().optional(),
  smoking: z.enum(['YES', 'NO', 'SOMETIMES']).nullable().optional(),
  alcohol: z.enum(['YES', 'NO', 'SOMETIMES']).nullable().optional(),
  pets: z.string().max(100).nullable().optional(),
  music_type: z.string().max(100).nullable().optional(),
  personality: z.string().max(200).nullable().optional(),
});

export const updateLocationSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

export const updatePushTokenSchema = z.object({
  push_token: z.string().min(1),
});
```

**Step 2: Create user service**

```typescript
// server/src/services/user.service.ts
import { supabase } from '../config/supabase.js';
import { Errors } from '../utils/errors.js';

export class UserService {
  async getMe(userId: string) {
    const { data: user } = await supabase
      .from('users')
      .select('*, user_details(*)')
      .eq('id', userId)
      .eq('is_deleted', false)
      .single();

    if (!user) throw Errors.USER_NOT_FOUND();

    const { password_hash, verify_token, is_deleted, ...safeUser } = user;
    return safeUser;
  }

  async updateProfile(userId: string, data: Record<string, unknown>) {
    const { error } = await supabase.from('users').update(data).eq('id', userId);
    if (error) throw Errors.SERVER_ERROR();
    await this.recalculateProfileCompletion(userId);
    return this.getMe(userId);
  }

  async updateDetails(userId: string, data: Record<string, unknown>) {
    const { data: existing } = await supabase
      .from('user_details').select('user_id').eq('user_id', userId).single();

    if (existing) {
      await supabase.from('user_details').update(data).eq('user_id', userId);
    } else {
      await supabase.from('user_details').insert({ user_id: userId, ...data });
    }

    await this.recalculateProfileCompletion(userId);
    return this.getMe(userId);
  }

  async updateLocation(userId: string, lat: number, lng: number) {
    await supabase.from('users').update({ lat, lng }).eq('id', userId);
  }

  async updatePushToken(userId: string, push_token: string) {
    await supabase.from('users').update({ push_token }).eq('id', userId);
  }

  async deleteAccount(userId: string) {
    await supabase.from('users').update({ is_deleted: true, is_online: false }).eq('id', userId);
    await supabase.from('refresh_tokens').delete().eq('user_id', userId);
  }

  async uploadPhoto(userId: string, fileBuffer: Buffer, mimeType: string) {
    const { data: user } = await supabase.from('users').select('photos').eq('id', userId).single();
    if (!user) throw Errors.USER_NOT_FOUND();
    if (user.photos && user.photos.length >= 6) throw Errors.MAX_PHOTOS_REACHED();

    const fileName = `${userId}/${Date.now()}.${mimeType === 'image/png' ? 'png' : 'jpg'}`;
    const { error: uploadError } = await supabase.storage
      .from('photos')
      .upload(fileName, fileBuffer, { contentType: mimeType });
    if (uploadError) throw Errors.SERVER_ERROR();

    const { data: urlData } = supabase.storage.from('photos').getPublicUrl(fileName);
    const newPhotos = [...(user.photos || []), urlData.publicUrl];

    await supabase.from('users').update({ photos: newPhotos }).eq('id', userId);
    await this.recalculateProfileCompletion(userId);
    return { photos: newPhotos };
  }

  async deletePhoto(userId: string, index: number) {
    const { data: user } = await supabase.from('users').select('photos').eq('id', userId).single();
    if (!user || !user.photos || index >= user.photos.length) throw Errors.USER_NOT_FOUND();

    const photoUrl = user.photos[index];
    const path = photoUrl.split('/photos/')[1];
    if (path) await supabase.storage.from('photos').remove([path]);

    const newPhotos = user.photos.filter((_: string, i: number) => i !== index);
    await supabase.from('users').update({ photos: newPhotos }).eq('id', userId);
    await this.recalculateProfileCompletion(userId);
    return { photos: newPhotos };
  }

  private async recalculateProfileCompletion(userId: string) {
    const { data: user } = await supabase
      .from('users').select('name, surname, bio, city, photos, lat, lng, user_details(*)').eq('id', userId).single();
    if (!user) return;

    let score = 0;
    const total = 10;

    if (user.name) score++;
    if (user.surname) score++;
    if (user.bio) score++;
    if (user.city) score++;
    if (user.lat && user.lng) score++;
    if (user.photos && user.photos.length >= 1) score++;
    if (user.photos && user.photos.length >= 3) score++;

    const details = user.user_details?.[0] || user.user_details;
    if (details) {
      if (details.job || details.school) score++;
      if (details.height || details.weight) score++;
      if (details.zodiac || details.personality) score++;
    }

    const completion = Math.round((score / total) * 100);
    await supabase.from('users').update({ profile_completion: completion }).eq('id', userId);
  }
}

export const userService = new UserService();
```

**Step 3: Create user controller**

```typescript
// server/src/controllers/user.controller.ts
import { Request, Response, NextFunction } from 'express';
import { userService } from '../services/user.service.js';

export class UserController {
  async getMe(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await userService.getMe(req.user!.userId);
      res.json(result);
    } catch (e) { next(e); }
  }

  async updateProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await userService.updateProfile(req.user!.userId, req.body);
      res.json(result);
    } catch (e) { next(e); }
  }

  async updateDetails(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await userService.updateDetails(req.user!.userId, req.body);
      res.json(result);
    } catch (e) { next(e); }
  }

  async updateLocation(req: Request, res: Response, next: NextFunction) {
    try {
      await userService.updateLocation(req.user!.userId, req.body.lat, req.body.lng);
      res.json({ success: true });
    } catch (e) { next(e); }
  }

  async updatePushToken(req: Request, res: Response, next: NextFunction) {
    try {
      await userService.updatePushToken(req.user!.userId, req.body.push_token);
      res.json({ success: true });
    } catch (e) { next(e); }
  }

  async deleteAccount(req: Request, res: Response, next: NextFunction) {
    try {
      await userService.deleteAccount(req.user!.userId);
      res.json({ success: true });
    } catch (e) { next(e); }
  }

  async uploadPhoto(req: Request, res: Response, next: NextFunction) {
    try {
      // Multer or raw body parsing expected here
      const file = (req as any).file;
      const result = await userService.uploadPhoto(req.user!.userId, file.buffer, file.mimetype);
      res.json(result);
    } catch (e) { next(e); }
  }

  async deletePhoto(req: Request, res: Response, next: NextFunction) {
    try {
      const index = parseInt(req.params.index);
      const result = await userService.deletePhoto(req.user!.userId, index);
      res.json(result);
    } catch (e) { next(e); }
  }
}

export const userController = new UserController();
```

**Step 4: Create user routes**

```typescript
// server/src/routes/user.routes.ts
import { Router } from 'express';
import multer from 'multer';
import { userController } from '../controllers/user.controller.js';
import { authenticate } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { generalLimiter } from '../middleware/rateLimit.js';
import { updateProfileSchema, updateDetailsSchema, updateLocationSchema, updatePushTokenSchema } from '../validators/user.validator.js';

const router = Router();
const upload = multer({
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (['image/jpeg', 'image/png'].includes(file.mimetype)) cb(null, true);
    else cb(new Error('Only jpg/png allowed'));
  },
});

router.use(authenticate);
router.use(generalLimiter);

router.get('/me', userController.getMe);
router.patch('/me', validate(updateProfileSchema), userController.updateProfile);
router.patch('/me/details', validate(updateDetailsSchema), userController.updateDetails);
router.patch('/me/location', validate(updateLocationSchema), userController.updateLocation);
router.patch('/me/push-token', validate(updatePushTokenSchema), userController.updatePushToken);
router.post('/me/photos', upload.single('photo'), userController.uploadPhoto);
router.delete('/me/photos/:index', userController.deletePhoto);
router.delete('/me', userController.deleteAccount);

export default router;
```

**Step 5: Install multer, register route in index.ts**

```bash
cd server && npm install multer && npm install -D @types/multer
```

Add to index.ts: `import userRoutes from './routes/user.routes.js';` and `app.use('/api/v1/users', userRoutes);`

**Step 6: Commit**

```bash
git add server/
git commit -m "feat(server): implement user/profile module (CRUD, photos, location, details)"
```

---

## Phase 4: Questions Module

### Task 9: Question Service + Routes

**Files:**
- Create: `server/src/services/question.service.ts`
- Create: `server/src/validators/question.validator.ts`
- Create: `server/src/controllers/question.controller.ts`
- Create: `server/src/routes/question.routes.ts`
- Modify: `server/src/index.ts`

**Step 1: Create question validator**

```typescript
// server/src/validators/question.validator.ts
import { z } from 'zod';

export const createQuestionSchema = z.object({
  order_num: z.number().int().min(1).max(6),
  question_text: z.string().min(5).max(500),
  correct_answer: z.number().int().min(1).max(4),
  answer_1: z.string().min(1).max(200),
  answer_2: z.string().min(1).max(200),
  answer_3: z.string().min(1).max(200),
  answer_4: z.string().min(1).max(200),
  hint_text: z.string().max(300).optional(),
});

export const updateQuestionSchema = createQuestionSchema.partial().omit({ order_num: true });
```

**Step 2: Create question service**

```typescript
// server/src/services/question.service.ts
import { supabase } from '../config/supabase.js';
import { Errors } from '../utils/errors.js';

export class QuestionService {
  async getMyQuestions(userId: string) {
    const { data } = await supabase
      .from('questions')
      .select('*')
      .eq('user_id', userId)
      .order('order_num');
    return data || [];
  }

  async createQuestion(userId: string, data: any) {
    const { data: existing } = await supabase
      .from('questions').select('id').eq('user_id', userId);
    if (existing && existing.length >= 6) throw Errors.MAX_QUESTIONS_REACHED();

    const { data: question, error } = await supabase
      .from('questions')
      .insert({ user_id: userId, ...data })
      .select()
      .single();
    if (error) {
      if (error.code === '23505') throw Errors.VALIDATION_ERROR('Question order already exists');
      throw Errors.SERVER_ERROR();
    }
    return question;
  }

  async updateQuestion(userId: string, orderNum: number, data: any) {
    const { data: question, error } = await supabase
      .from('questions')
      .update(data)
      .eq('user_id', userId)
      .eq('order_num', orderNum)
      .select()
      .single();
    if (error || !question) throw Errors.SESSION_NOT_FOUND();
    return question;
  }

  async deleteQuestion(userId: string, orderNum: number) {
    const { error } = await supabase
      .from('questions')
      .delete()
      .eq('user_id', userId)
      .eq('order_num', orderNum);
    if (error) throw Errors.SERVER_ERROR();
  }

  async getQuestionCount(userId: string) {
    const { count } = await supabase
      .from('questions')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId);
    return { count: count || 0 };
  }
}

export const questionService = new QuestionService();
```

**Step 3: Create controller + routes (same pattern as auth/user)**

Controller wraps service calls with try/catch/next. Routes use authenticate + validate middleware.

Register in index.ts: `app.use('/api/v1/questions', questionRoutes);`

**Step 4: Commit**

```bash
git add server/
git commit -m "feat(server): implement question module (CRUD, validation, max 6)"
```

---

## Phase 5: Matching & Discover Module

### Task 10: Notification Service

**Files:**
- Create: `server/src/services/notification.service.ts`
- Create: `server/src/locales/tr.json`
- Create: `server/src/locales/en.json`

**Step 1: Create locale files**

```json
// server/src/locales/tr.json
{
  "push": {
    "new_message": "{name} size mesaj gonderdi",
    "new_message_image": "{name} size bir fotograf gonderdi",
    "new_match": "Yeni bir eslesme! {name} tum sorularinizi cozdu",
    "quiz_started": "{name} sorularinizi cozmeye basladi",
    "passport_expired": "Pasaport modunuz sona erdi"
  }
}
```

```json
// server/src/locales/en.json
{
  "push": {
    "new_message": "{name} sent you a message",
    "new_message_image": "{name} sent you a photo",
    "new_match": "New match! {name} solved all your questions",
    "quiz_started": "{name} started solving your questions",
    "passport_expired": "Your passport mode has expired"
  }
}
```

**Step 2: Create notification service**

```typescript
// server/src/services/notification.service.ts
import { fcm } from '../config/firebase.js';
import { supabase } from '../config/supabase.js';
import trLocale from '../locales/tr.json' assert { type: 'json' };
import enLocale from '../locales/en.json' assert { type: 'json' };

const locales: Record<string, any> = { tr: trLocale, en: enLocale };

function interpolate(template: string, params: Record<string, string>): string {
  return Object.entries(params).reduce(
    (str, [key, val]) => str.replace(`{${key}}`, val), template
  );
}

export class NotificationService {
  async sendPush(userId: string, type: string, params: Record<string, string>, data?: Record<string, string>) {
    const { data: user } = await supabase
      .from('users').select('push_token, locale').eq('id', userId).single();
    if (!user?.push_token) return;

    const locale = locales[user.locale] || locales['en'];
    const template = locale.push[type];
    if (!template) return;

    const body = interpolate(template, params);

    try {
      await fcm.send({
        token: user.push_token,
        notification: { title: 'Qulo', body },
        data: { type, ...data },
      });
    } catch (e) {
      console.error('FCM send failed:', e);
    }
  }
}

export const notificationService = new NotificationService();
```

**Step 3: Commit**

```bash
git add server/src/services/notification.service.ts server/src/locales/
git commit -m "feat(server): add notification service with i18n push templates"
```

---

### Task 11: Scoring Service + Matching Service + Discover

**Files:**
- Create: `server/src/services/scoring.service.ts`
- Create: `server/src/services/matching.service.ts`
- Create: `server/src/validators/match.validator.ts`
- Create: `server/src/controllers/match.controller.ts`
- Create: `server/src/routes/match.routes.ts`

**Step 1: Create scoring service**

```typescript
// server/src/services/scoring.service.ts
export class ScoringService {
  desirabilityScore(likeReceived: number, timesShown: number): number {
    if (timesShown === 0) return 5;
    const ratio = likeReceived / timesShown;
    if (ratio > 0.6) return 10;
    if (ratio > 0.4) return 7;
    if (ratio > 0.2) return 5;
    if (ratio > 0.1) return 3;
    return 1;
  }

  recencyScore(lastSeenAt: string): number {
    const hours = (Date.now() - new Date(lastSeenAt).getTime()) / (1000 * 60 * 60);
    if (hours <= 1) return 10;
    if (hours <= 6) return 8;
    if (hours <= 24) return 6;
    if (hours <= 72) return 3;
    if (hours <= 168) return 1;
    return 0; // 7+ days -> should be filtered out
  }

  distanceScore(distanceKm: number, maxRadius: number): number {
    return Math.max(0, (1 - distanceKm / maxRadius) * 10);
  }

  profileScore(completion: number, photoCount: number, hasBio: boolean): number {
    let score = (completion / 100) * 10;
    if (photoCount >= 3) score += 2;
    if (hasBio) score += 1;
    return Math.min(score, 13);
  }

  engagementScore(greenDiamonds: number, quizCompletionRate: number): number {
    const diamondScore = Math.min(greenDiamonds / 50, 5);
    const quizScore = quizCompletionRate * 5;
    return diamondScore + quizScore;
  }

  totalScore(params: {
    likeReceived: number; timesShown: number; lastSeenAt: string;
    distanceKm: number; maxRadius: number; completion: number;
    photoCount: number; hasBio: boolean; greenDiamonds: number;
    quizCompletionRate: number; boostUntil: string | null;
  }): number {
    const d = this.desirabilityScore(params.likeReceived, params.timesShown) * 0.25;
    const e = this.engagementScore(params.greenDiamonds, params.quizCompletionRate) * 0.25;
    const r = this.recencyScore(params.lastSeenAt) * 0.20;
    const dist = this.distanceScore(params.distanceKm, params.maxRadius) * 0.15;
    const p = this.profileScore(params.completion, params.photoCount, params.hasBio) * 0.10;
    const boost = (params.boostUntil && new Date(params.boostUntil) > new Date()) ? 50 : 0;

    return d + e + r + dist + p + boost;
  }
}

export const scoringService = new ScoringService();
```

**Step 2: Create matching service**

```typescript
// server/src/services/matching.service.ts
import { supabase } from '../config/supabase.js';
import { scoringService } from './scoring.service.js';
import { Errors } from '../utils/errors.js';

export class MatchingService {
  async discover(userId: string, page: number = 1) {
    const { data: me } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();
    if (!me) throw Errors.USER_NOT_FOUND();

    // Use passport location if active
    const myLat = me.passport_lat || me.lat;
    const myLng = me.passport_lng || me.lng;
    if (!myLat || !myLng) throw Errors.PROFILE_INCOMPLETE();

    // Get already swiped IDs
    const { data: swiped } = await supabase
      .from('swipes').select('target_id').eq('swiper_id', userId);
    const swipedIds = (swiped || []).map(s => s.target_id);
    swipedIds.push(userId); // exclude self

    // Query candidates with PostGIS
    const radiusMeters = me.match_radius_km * 1000;
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    let query = supabase.rpc('discover_candidates', {
      my_lat: myLat,
      my_lng: myLng,
      radius_m: radiusMeters,
      gender_filter: me.gender_pref === 'BOTH' ? null : me.gender_pref,
      age_min: me.age_pref_min,
      age_max: me.age_pref_max,
      excluded_ids: swipedIds,
      min_last_seen: sevenDaysAgo,
      page_limit: 50,
    });

    const { data: candidates } = await query;
    if (!candidates || candidates.length === 0) return [];

    // Score and sort
    const scored = candidates.map((c: any) => ({
      ...c,
      score: scoringService.totalScore({
        likeReceived: c.like_received_count,
        timesShown: c.times_shown_count,
        lastSeenAt: c.last_seen_at,
        distanceKm: c.distance_km,
        maxRadius: me.match_radius_km,
        completion: c.profile_completion,
        photoCount: c.photos?.length || 0,
        hasBio: !!c.bio,
        greenDiamonds: c.green_diamonds,
        quizCompletionRate: 0, // TODO: calculate from quiz_sessions
        boostUntil: c.boost_until,
      }),
    }));

    scored.sort((a: any, b: any) => b.score - a.score);

    // Paginate (10 per page)
    const start = (page - 1) * 10;
    const results = scored.slice(start, start + 10);

    // Increment times_shown for returned users
    const shownIds = results.map((r: any) => r.id);
    if (shownIds.length > 0) {
      await supabase.rpc('increment_times_shown', { user_ids: shownIds });
    }

    // Return safe profile cards
    return results.map((u: any) => ({
      user_id: u.id,
      name: u.name,
      age: u.age,
      city: u.city,
      bio: u.bio,
      photos: u.photos,
      distance_km: Math.round(u.distance_km * 10) / 10,
      question_count: u.question_count,
      profile_completion: u.profile_completion,
      is_boosted: u.boost_until && new Date(u.boost_until) > new Date(),
    }));
  }

  async swipe(swiperId: string, targetId: string, action: 'LIKE' | 'REJECT') {
    if (swiperId === targetId) throw Errors.SELF_SWIPE();

    // Check target has questions
    if (action === 'LIKE') {
      const { count } = await supabase
        .from('questions')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', targetId);
      if (!count || count < 2) throw Errors.NO_QUESTIONS();
    }

    const { error } = await supabase.from('swipes').insert({
      swiper_id: swiperId, target_id: targetId, action,
    });
    if (error?.code === '23505') throw Errors.ALREADY_SWIPED();
    if (error) throw Errors.SERVER_ERROR();

    // Update like count
    if (action === 'LIKE') {
      await supabase.rpc('increment_like_received', { target_user_id: targetId });
    }

    return { action };
  }

  async getMatches(userId: string) {
    const { data } = await supabase
      .from('matches')
      .select(`
        id, matched_at, is_active,
        user1:users!matches_user1_id_fkey(id, name, photos, is_online, last_seen_at),
        user2:users!matches_user2_id_fkey(id, name, photos, is_online, last_seen_at)
      `)
      .or(`user1_id.eq.${userId},user2_id.eq.${userId}`)
      .eq('is_active', true)
      .order('matched_at', { ascending: false });

    return (data || []).map((m: any) => ({
      match_id: m.id,
      matched_at: m.matched_at,
      other_user: m.user1?.id === userId ? m.user2 : m.user1,
    }));
  }

  async unmatch(userId: string, matchId: string) {
    const { error } = await supabase
      .from('matches')
      .update({ is_active: false })
      .eq('id', matchId)
      .or(`user1_id.eq.${userId},user2_id.eq.${userId}`);
    if (error) throw Errors.SERVER_ERROR();
  }
}

export const matchingService = new MatchingService();
```

**Step 3: Create Supabase RPC functions (migration)**

```sql
-- supabase/migrations/004_rpc_functions.sql

-- Discover candidates with PostGIS distance
CREATE OR REPLACE FUNCTION discover_candidates(
  my_lat DOUBLE PRECISION,
  my_lng DOUBLE PRECISION,
  radius_m INT,
  gender_filter TEXT,
  age_min INT,
  age_max INT,
  excluded_ids UUID[],
  min_last_seen TIMESTAMPTZ,
  page_limit INT DEFAULT 50
)
RETURNS TABLE (
  id UUID, name TEXT, age INT, city TEXT, bio TEXT, photos TEXT[],
  profile_completion INT, green_diamonds INT, like_received_count INT,
  times_shown_count INT, last_seen_at TIMESTAMPTZ, boost_until TIMESTAMPTZ,
  distance_km DOUBLE PRECISION, question_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id, u.name, u.age, u.city, u.bio, u.photos,
    u.profile_completion, u.green_diamonds, u.like_received_count,
    u.times_shown_count, u.last_seen_at, u.boost_until,
    ST_Distance(
      ST_MakePoint(u.lng, u.lat)::geography,
      ST_MakePoint(my_lng, my_lat)::geography
    ) / 1000.0 AS distance_km,
    (SELECT COUNT(*) FROM questions q WHERE q.user_id = u.id) AS question_count
  FROM users u
  WHERE u.is_deleted = false
    AND u.email_verified = true
    AND u.lat IS NOT NULL
    AND u.lng IS NOT NULL
    AND u.id != ALL(excluded_ids)
    AND u.last_seen_at >= min_last_seen
    AND u.age BETWEEN age_min AND age_max
    AND (gender_filter IS NULL OR u.gender::TEXT = gender_filter)
    AND ST_DWithin(
      ST_MakePoint(u.lng, u.lat)::geography,
      ST_MakePoint(my_lng, my_lat)::geography,
      radius_m
    )
    AND (SELECT COUNT(*) FROM questions q WHERE q.user_id = u.id) >= 2
  LIMIT page_limit;
END;
$$ LANGUAGE plpgsql;

-- Increment times_shown
CREATE OR REPLACE FUNCTION increment_times_shown(user_ids UUID[])
RETURNS VOID AS $$
BEGIN
  UPDATE users SET times_shown_count = times_shown_count + 1
  WHERE id = ANY(user_ids);
END;
$$ LANGUAGE plpgsql;

-- Increment like_received
CREATE OR REPLACE FUNCTION increment_like_received(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET like_received_count = like_received_count + 1
  WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql;
```

**Step 4: Create controller + routes, register in index.ts**

Register: `app.use('/api/v1/match', matchRoutes);`

**Step 5: Commit**

```bash
git add server/ supabase/
git commit -m "feat(server): implement matching/discover module with scoring algorithm and PostGIS"
```

---

## Phase 6: Quiz + Powers + Diamond Module

### Task 12: Diamond Service

**Files:**
- Create: `server/src/services/diamond.service.ts`
- Create: `server/src/controllers/diamond.controller.ts`
- Create: `server/src/routes/diamond.routes.ts`

**Step 1: Create diamond service**

```typescript
// server/src/services/diamond.service.ts
import { supabase } from '../config/supabase.js';
import { Errors } from '../utils/errors.js';

export class DiamondService {
  async getBalance(userId: string) {
    const { data } = await supabase
      .from('users').select('green_diamonds, purple_diamonds').eq('id', userId).single();
    if (!data) throw Errors.USER_NOT_FOUND();
    return { green: data.green_diamonds, purple: data.purple_diamonds };
  }

  async getHistory(userId: string, page: number = 1, limit: number = 20) {
    const offset = (page - 1) * limit;
    const { data, count } = await supabase
      .from('diamond_transactions')
      .select('*', { count: 'exact' })
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);
    return { transactions: data || [], total: count || 0, page, limit };
  }

  async spendPurple(userId: string, amount: number, reason: string, referenceId?: string) {
    const { data: user } = await supabase
      .from('users').select('purple_diamonds').eq('id', userId).single();
    if (!user || user.purple_diamonds < amount) {
      throw Errors.INSUFFICIENT_DIAMONDS(amount, user?.purple_diamonds || 0);
    }

    await supabase.from('users')
      .update({ purple_diamonds: user.purple_diamonds - amount })
      .eq('id', userId);

    await supabase.from('diamond_transactions').insert({
      user_id: userId, type: 'PURPLE', amount: -amount, reason, reference_id: referenceId,
    });
  }

  async earnGreen(userId: string, amount: number, reason: string, referenceId?: string) {
    const { data: user } = await supabase
      .from('users').select('green_diamonds').eq('id', userId).single();
    if (!user) throw Errors.USER_NOT_FOUND();

    await supabase.from('users')
      .update({ green_diamonds: user.green_diamonds + amount })
      .eq('id', userId);

    await supabase.from('diamond_transactions').insert({
      user_id: userId, type: 'GREEN', amount, reason, reference_id: referenceId,
    });
  }

  async spendGreen(userId: string, amount: number, reason: string, referenceId?: string) {
    const { data: user } = await supabase
      .from('users').select('green_diamonds').eq('id', userId).single();
    if (!user || user.green_diamonds < amount) {
      throw Errors.INSUFFICIENT_DIAMONDS(amount, user?.green_diamonds || 0);
    }

    await supabase.from('users')
      .update({ green_diamonds: user.green_diamonds - amount })
      .eq('id', userId);

    await supabase.from('diamond_transactions').insert({
      user_id: userId, type: 'GREEN', amount: -amount, reason, reference_id: referenceId,
    });
  }

  async addPurple(userId: string, amount: number, reason: string, referenceId?: string) {
    const { data: user } = await supabase
      .from('users').select('purple_diamonds').eq('id', userId).single();
    if (!user) throw Errors.USER_NOT_FOUND();

    await supabase.from('users')
      .update({ purple_diamonds: user.purple_diamonds + amount })
      .eq('id', userId);

    await supabase.from('diamond_transactions').insert({
      user_id: userId, type: 'PURPLE', amount, reason, reference_id: referenceId,
    });
  }
}

export const diamondService = new DiamondService();
```

**Step 2: Create controller + routes, register in index.ts**

Register: `app.use('/api/v1/diamonds', diamondRoutes);`

**Step 3: Commit**

```bash
git add server/
git commit -m "feat(server): implement diamond service (balance, history, spend, earn)"
```

---

### Task 13: Quiz Service (Core Game Logic)

**Files:**
- Create: `server/src/services/quiz.service.ts`
- Create: `server/src/validators/quiz.validator.ts`
- Create: `server/src/controllers/quiz.controller.ts`
- Create: `server/src/routes/quiz.routes.ts`
- Create: `server/src/utils/math.ts`

**Step 1: Create math utility**

```typescript
// server/src/utils/math.ts
import { QUESTION_COUNT_MULTIPLIERS, GREEN_DIAMOND_REWARD_RATIO } from '../types/index.js';

export function calculatePowerCost(baseCost: number, questionCount: number): number {
  const multiplier = QUESTION_COUNT_MULTIPLIERS[questionCount] || 1.0;
  return Math.ceil(baseCost * multiplier);
}

export function calculateGreenReward(purpleSpent: number): number {
  return Math.ceil(purpleSpent * GREEN_DIAMOND_REWARD_RATIO);
}

export function shuffleArray<T>(array: T[]): T[] {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}
```

**Step 2: Create quiz service**

```typescript
// server/src/services/quiz.service.ts
import { supabase } from '../config/supabase.js';
import { diamondService } from './diamond.service.js';
import { notificationService } from './notification.service.js';
import { Errors } from '../utils/errors.js';
import { calculatePowerCost, calculateGreenReward, shuffleArray } from '../utils/math.js';
import type { PowerName } from '../types/index.js';

const QUESTION_TIME_LIMIT_MS = 30 * 1000; // 30 seconds per question

export class QuizService {
  async startSession(solverId: string, targetId: string) {
    // Check target has questions
    const { data: questions } = await supabase
      .from('questions').select('id').eq('user_id', targetId);
    if (!questions || questions.length < 2) throw Errors.NO_QUESTIONS();

    // Check no active session exists
    const { data: existing } = await supabase
      .from('quiz_sessions')
      .select('id')
      .eq('solver_id', solverId)
      .eq('target_id', targetId)
      .eq('status', 'IN_PROGRESS')
      .single();
    if (existing) return { session_id: existing.id, already_active: true };

    const totalTime = questions.length * QUESTION_TIME_LIMIT_MS;
    const expiresAt = new Date(Date.now() + totalTime).toISOString();

    const { data: session, error } = await supabase.from('quiz_sessions').insert({
      solver_id: solverId,
      target_id: targetId,
      current_q: 1,
      status: 'IN_PROGRESS',
      expires_at: expiresAt,
    }).select('id').single();

    if (error) throw Errors.SERVER_ERROR();

    // Notify target
    const { data: solver } = await supabase.from('users').select('name').eq('id', solverId).single();
    await notificationService.sendPush(targetId, 'quiz_started', { name: solver?.name || '?' });

    return { session_id: session!.id, total_questions: questions.length };
  }

  async getCurrentQuestion(sessionId: string, solverId: string) {
    const session = await this.getActiveSession(sessionId, solverId);

    const { data: questions } = await supabase
      .from('questions')
      .select('id, order_num, question_text, answer_1, answer_2, answer_3, answer_4, hint_text')
      .eq('user_id', session.target_id)
      .order('order_num');

    if (!questions || session.current_q > questions.length) {
      throw Errors.SESSION_NOT_FOUND();
    }

    const q = questions[session.current_q - 1];
    // Shuffle answer order
    const answers = shuffleArray([
      { index: 1, text: q.answer_1 },
      { index: 2, text: q.answer_2 },
      { index: 3, text: q.answer_3 },
      { index: 4, text: q.answer_4 },
    ]);

    return {
      session_id: sessionId,
      question_number: session.current_q,
      total_questions: questions.length,
      question_id: q.id,
      question_text: q.question_text,
      answers: answers.map(a => ({ index: a.index, text: a.text })),
      has_hint: !!q.hint_text,
      time_limit_seconds: 30,
    };
  }

  async answerQuestion(sessionId: string, solverId: string, selectedAnswer: number, powerUsed?: PowerName) {
    const session = await this.getActiveSession(sessionId, solverId);

    // Get current question with correct answer
    const { data: questions } = await supabase
      .from('questions')
      .select('*')
      .eq('user_id', session.target_id)
      .order('order_num');

    if (!questions || session.current_q > questions.length) throw Errors.SESSION_NOT_FOUND();

    const currentQ = questions[session.current_q - 1];
    const totalQuestions = questions.length;

    // Check if already answered
    const { data: existingAnswer } = await supabase
      .from('quiz_answers')
      .select('id')
      .eq('session_id', sessionId)
      .eq('question_id', currentQ.id)
      .single();
    if (existingAnswer) throw Errors.ALREADY_ANSWERED();

    let isCorrect = selectedAnswer === currentQ.correct_answer;
    let powerResult: any = null;

    // Handle power usage
    if (powerUsed) {
      const { data: power } = await supabase
        .from('powers').select('*').eq('name', powerUsed).eq('is_active', true).single();
      if (!power) throw Errors.VALIDATION_ERROR('Invalid power');

      const cost = calculatePowerCost(power.base_cost, totalQuestions);

      // Spend solver's purple diamonds
      await diamondService.spendPurple(solverId, cost, 'POWER_USED', `${powerUsed}:${sessionId}`);

      // Reward target's green diamonds (30%)
      const greenReward = calculateGreenReward(cost);
      await diamondService.earnGreen(session.target_id, greenReward, 'POWER_REWARD', `${powerUsed}:${sessionId}`);

      // Apply power effect
      switch (powerUsed) {
        case 'SKIP':
          isCorrect = true;
          break;
        case 'SKIP_ALL':
          isCorrect = true;
          // Mark all remaining as correct and complete
          await this.skipAllRemaining(sessionId, session, questions, solverId);
          return { matched: true, power_used: 'SKIP_ALL' };
        case 'COPY':
          powerResult = { correct_answer_index: currentQ.correct_answer, show_seconds: 3 };
          // Don't auto-correct, user still needs to answer
          return { power_result: powerResult, awaiting_answer: true };
        case 'HALF':
          const wrongAnswers = [1, 2, 3, 4].filter(i => i !== currentQ.correct_answer);
          const removed = shuffleArray(wrongAnswers).slice(0, 2);
          powerResult = { removed_indices: removed };
          return { power_result: powerResult, awaiting_answer: true };
        case 'TIME_EXTEND':
          powerResult = { extra_seconds: 15 };
          return { power_result: powerResult, awaiting_answer: true };
        case 'HINT':
          powerResult = { hint_text: currentQ.hint_text || 'No hint available' };
          return { power_result: powerResult, awaiting_answer: true };
      }
    }

    // Record answer
    await supabase.from('quiz_answers').insert({
      session_id: sessionId,
      question_id: currentQ.id,
      selected_answer: selectedAnswer,
      is_correct: isCorrect,
      power_used: powerUsed,
    });

    // Update question stats
    await supabase.from('questions').update({
      [isCorrect ? 'stats_correct' : 'stats_wrong']:
        currentQ[isCorrect ? 'stats_correct' : 'stats_wrong'] + 1,
    }).eq('id', currentQ.id);

    if (!isCorrect) {
      // Failed
      await supabase.from('quiz_sessions').update({
        status: 'FAILED', completed_at: new Date().toISOString(),
      }).eq('id', sessionId);
      return { is_correct: false, session_status: 'FAILED' };
    }

    // Check if all questions answered
    if (session.current_q >= totalQuestions) {
      // All correct -> MATCH!
      await this.createMatch(sessionId, solverId, session.target_id);
      return { is_correct: true, session_status: 'COMPLETED', matched: true };
    }

    // Move to next question
    await supabase.from('quiz_sessions').update({
      current_q: session.current_q + 1,
    }).eq('id', sessionId);

    return { is_correct: true, next_question: session.current_q + 1, session_status: 'IN_PROGRESS' };
  }

  async getSessionResult(sessionId: string, solverId: string) {
    const { data: session } = await supabase
      .from('quiz_sessions')
      .select('*, quiz_answers(*)')
      .eq('id', sessionId)
      .eq('solver_id', solverId)
      .single();
    if (!session) throw Errors.SESSION_NOT_FOUND();
    return session;
  }

  private async getActiveSession(sessionId: string, solverId: string) {
    const { data: session } = await supabase
      .from('quiz_sessions')
      .select('*')
      .eq('id', sessionId)
      .eq('solver_id', solverId)
      .single();

    if (!session) throw Errors.SESSION_NOT_FOUND();
    if (session.status !== 'IN_PROGRESS') throw Errors.SESSION_EXPIRED();
    if (new Date(session.expires_at) < new Date()) {
      await supabase.from('quiz_sessions').update({
        status: 'FAILED', completed_at: new Date().toISOString(),
      }).eq('id', sessionId);
      throw Errors.TIME_UP();
    }
    return session;
  }

  private async createMatch(sessionId: string, solverId: string, targetId: string) {
    // Order IDs for unique constraint
    const [user1, user2] = [solverId, targetId].sort();

    await supabase.from('matches').insert({
      user1_id: user1, user2_id: user2,
    });

    await supabase.from('quiz_sessions').update({
      status: 'COMPLETED', completed_at: new Date().toISOString(),
    }).eq('id', sessionId);

    // Notify both users
    const { data: solver } = await supabase.from('users').select('name').eq('id', solverId).single();
    const { data: target } = await supabase.from('users').select('name').eq('id', targetId).single();

    await notificationService.sendPush(targetId, 'new_match', { name: solver?.name || '?' }, { match_id: sessionId });
    await notificationService.sendPush(solverId, 'new_match', { name: target?.name || '?' }, { match_id: sessionId });
  }

  private async skipAllRemaining(sessionId: string, session: any, questions: any[], solverId: string) {
    for (let i = session.current_q - 1; i < questions.length; i++) {
      await supabase.from('quiz_answers').insert({
        session_id: sessionId,
        question_id: questions[i].id,
        selected_answer: questions[i].correct_answer,
        is_correct: true,
        power_used: i === session.current_q - 1 ? 'SKIP_ALL' : null,
      });
    }
    await this.createMatch(sessionId, solverId, session.target_id);
  }
}

export const quizService = new QuizService();
```

**Step 3: Create validators, controller, routes**

```typescript
// server/src/validators/quiz.validator.ts
import { z } from 'zod';

export const startQuizSchema = z.object({
  target_id: z.string().uuid(),
});

export const answerQuizSchema = z.object({
  selected_answer: z.number().int().min(1).max(4),
  power_used: z.enum(['COPY', 'HALF', 'SKIP', 'SKIP_ALL', 'TIME_EXTEND', 'HINT']).optional(),
});
```

Controller + routes follow same pattern. Register: `app.use('/api/v1/quiz', quizRoutes);`

**Step 4: Create powers route (simple GET)**

```typescript
// server/src/routes/power.routes.ts
import { Router } from 'express';
import { authenticate } from '../middleware/auth.js';
import { supabase } from '../config/supabase.js';

const router = Router();
router.use(authenticate);

router.get('/', async (_req, res) => {
  const { data } = await supabase.from('powers').select('*').eq('is_active', true);
  res.json(data || []);
});

export default router;
```

Register: `app.use('/api/v1/powers', powerRoutes);`

**Step 5: Commit**

```bash
git add server/ supabase/
git commit -m "feat(server): implement quiz system with powers, diamond economy, and anti-cheat"
```

---

## Phase 7: Chat + Passport + Boost

### Task 14: Chat Service

**Files:**
- Create: `server/src/services/chat.service.ts`
- Create: `server/src/validators/chat.validator.ts`
- Create: `server/src/controllers/chat.controller.ts`
- Create: `server/src/routes/chat.routes.ts`

**Step 1: Create chat service**

```typescript
// server/src/services/chat.service.ts
import { supabase } from '../config/supabase.js';
import { notificationService } from './notification.service.js';
import { Errors } from '../utils/errors.js';

export class ChatService {
  async getMessages(userId: string, matchId: string, page: number = 1, limit: number = 30) {
    await this.verifyMatchAccess(userId, matchId);

    const offset = (page - 1) * limit;
    const { data, count } = await supabase
      .from('messages')
      .select('*', { count: 'exact' })
      .eq('match_id', matchId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    return { messages: data || [], total: count || 0, page, limit };
  }

  async sendMessage(userId: string, matchId: string, content: string, isImage: boolean = false) {
    const match = await this.verifyMatchAccess(userId, matchId);

    const { data: message, error } = await supabase.from('messages').insert({
      match_id: matchId, sender_id: userId, content, is_image: isImage,
    }).select().single();

    if (error) throw Errors.SERVER_ERROR();

    // Send push to other user
    const otherId = match.user1_id === userId ? match.user2_id : match.user1_id;
    const { data: sender } = await supabase.from('users').select('name').eq('id', userId).single();

    const pushType = isImage ? 'new_message_image' : 'new_message';
    await notificationService.sendPush(otherId, pushType, {
      name: sender?.name || '?',
    }, { match_id: matchId });

    return message;
  }

  async markAsRead(userId: string, matchId: string) {
    await this.verifyMatchAccess(userId, matchId);

    await supabase.from('messages')
      .update({ read_at: new Date().toISOString() })
      .eq('match_id', matchId)
      .neq('sender_id', userId)
      .is('read_at', null);
  }

  private async verifyMatchAccess(userId: string, matchId: string) {
    const { data: match } = await supabase
      .from('matches')
      .select('*')
      .eq('id', matchId)
      .or(`user1_id.eq.${userId},user2_id.eq.${userId}`)
      .single();

    if (!match) throw Errors.NOT_MATCHED();
    if (!match.is_active) throw Errors.MATCH_INACTIVE();
    return match;
  }
}

export const chatService = new ChatService();
```

**Step 2: Create validator, controller, routes. Register: `app.use('/api/v1/chat', chatRoutes);`**

**Step 3: Commit**

```bash
git add server/
git commit -m "feat(server): implement chat module (messages, read receipts, push notifications)"
```

---

### Task 15: Passport + Boost + Report Services

**Files:**
- Create: `server/src/routes/passport.routes.ts`
- Create: `server/src/routes/report.routes.ts`

**Step 1: Passport routes (uses diamondService)**

```typescript
// Passport activate: spend 50 purple, set passport_* fields
// Passport deactivate: clear passport_* fields
// Register: app.use('/api/v1/passport', passportRoutes);
```

**Step 2: Boost endpoint (in user routes or separate)**

```typescript
// POST /api/v1/users/me/boost
// Spend 30 green diamonds, set boost_until = now + 30min
```

**Step 3: Report routes**

```typescript
// POST /api/v1/reports { reported_id, reason }
// Register: app.use('/api/v1/reports', reportRoutes);
```

**Step 4: Commit**

```bash
git add server/
git commit -m "feat(server): implement passport, boost, and report modules"
```

---

### Task 16: Wire All Routes + Final Backend Cleanup

**Files:**
- Modify: `server/src/index.ts` (all routes registered)

**Step 1: Ensure all routes are registered**

```typescript
// server/src/index.ts - final
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/questions', questionRoutes);
app.use('/api/v1/match', matchRoutes);
app.use('/api/v1/quiz', quizRoutes);
app.use('/api/v1/diamonds', diamondRoutes);
app.use('/api/v1/powers', powerRoutes);
app.use('/api/v1/passport', passportRoutes);
app.use('/api/v1/chat', chatRoutes);
app.use('/api/v1/reports', reportRoutes);
app.use(errorHandler);
```

**Step 2: Test all health + auth endpoints**

**Step 3: Commit**

```bash
git add server/
git commit -m "feat(server): wire all routes, backend API complete"
```

---

## Phase 8: Flutter Mobile Foundation

### Task 17: Initialize Flutter Project

**Step 1: Create Flutter project**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2
flutter create --org com.qulo --project-name qulo_v2 .
# OR if project already needs to be at root:
flutter create --org com.qulo .
```

**Step 2: Update pubspec.yaml dependencies**

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  # Network
  dio: ^5.4.3+1
  # Supabase (Realtime only)
  supabase_flutter: ^2.5.3
  # Firebase
  firebase_core: ^2.31.0
  firebase_messaging: ^14.9.1
  firebase_crashlytics: ^3.5.4
  firebase_analytics: ^10.10.4
  # Navigation
  go_router: ^14.2.0
  # Storage
  shared_preferences: ^2.2.3
  flutter_secure_storage: ^9.0.0
  # Image
  image_picker: ^1.1.1
  cached_network_image: ^3.3.1
  # Location
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  # UI
  flutter_svg: ^2.0.10+1
  lottie: ^3.1.0
  shimmer: ^3.0.0
  # Utils
  intl: ^0.19.0
  equatable: ^2.0.5
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
```

**Step 3: Create folder structure**

```bash
mkdir -p lib/{core/{config,network,theme,l10n,utils,constants},data/{models,repositories,datasources/{remote,local}},providers,features/{auth/{screens,widgets},onboarding/{screens,widgets},discover/{screens,widgets},quiz/{screens,widgets},chat/{screens,widgets},diamonds/{screens,widgets},profile/{screens,widgets},passport/{screens,widgets},settings/{screens,widgets}},shared/{widgets,dialogs},routing}
```

**Step 4: Commit**

```bash
git add .
git commit -m "feat(mobile): initialize Flutter project with dependencies and folder structure"
```

---

### Task 18: Core Layer (Config, Network, Theme)

**Files:**
- Create: `lib/core/config/env.dart`
- Create: `lib/core/config/supabase_config.dart`
- Create: `lib/core/config/firebase_config.dart`
- Create: `lib/core/network/api_client.dart`
- Create: `lib/core/network/api_endpoints.dart`
- Create: `lib/core/network/token_interceptor.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/constants/app_constants.dart`

**Step 1: Create environment config**

```dart
// lib/core/config/env.dart
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

**Step 2: Create API client with Dio + token interceptor**

```dart
// lib/core/network/api_client.dart
// Dio instance with base URL, JSON content type, token interceptor
// Auto-refresh on 401 via interceptor
```

**Step 3: Create theme with purple/green color palette**

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  static const purple = Color(0xFF9C27B0);
  static const purpleLight = Color(0xFFCE93D8);
  static const green = Color(0xFF4CAF50);
  static const greenLight = Color(0xFFA5D6A7);
  // ... rest of palette
}
```

**Step 4: Commit**

```bash
git add lib/core/
git commit -m "feat(mobile): add core layer (config, API client, theme, constants)"
```

---

### Task 19: Data Layer (Models + Repositories)

**Files:**
- Create all model files in `lib/data/models/`
- Create all repository files in `lib/data/repositories/`
- Create remote data sources in `lib/data/datasources/remote/`

**Step 1: Create models (user_model, question_model, match_model, message_model, etc.)**

Each model: fromJson, toJson, with json_serializable annotations.

**Step 2: Create repositories**

Each repository wraps API calls via Dio and returns typed models.

**Step 3: Commit**

```bash
git add lib/data/
git commit -m "feat(mobile): add data layer (models, repositories, data sources)"
```

---

### Task 20: Providers Layer

**Files:**
- Create all provider files in `lib/providers/`

**Step 1: Create Riverpod providers for each feature**

```dart
// lib/providers/auth_provider.dart
// StateNotifier or AsyncNotifier for auth state
// Manages: login, register, logout, token storage
```

**Step 2: Commit**

```bash
git add lib/providers/
git commit -m "feat(mobile): add Riverpod providers for all features"
```

---

### Task 21: Routing + App Entry

**Files:**
- Create: `lib/routing/app_router.dart`
- Create: `lib/routing/route_guards.dart`
- Modify: `lib/main.dart`
- Create: `lib/app.dart`

**Step 1: Setup GoRouter with auth guard**

**Step 2: Setup main.dart with ProviderScope, Firebase init, Supabase init**

**Step 3: Commit**

```bash
git add lib/
git commit -m "feat(mobile): add routing, app entry, and initialization"
```

---

## Phase 9: Mobile Features

### Task 22: Auth Feature (Login, Register, Verify, Forgot Password)
### Task 23: Onboarding Feature (Basic Info, Photos, Questions Setup)
### Task 24: Discover Feature (Tinder Cards, Swipe)
### Task 25: Quiz Feature (Question Solving, Powers, Timer)
### Task 26: Chat Feature (Match List, Messages, Realtime)
### Task 27: Diamond Feature (Balance, Purchase, History)
### Task 28: Profile Feature (View, Edit, Details, Photos)
### Task 29: Passport Feature (Activate, City Selection)
### Task 30: Settings Feature (Notifications, Language, Delete Account)

Each feature follows the same pattern:
1. Create screen widgets in `features/<name>/screens/`
2. Create reusable widgets in `features/<name>/widgets/`
3. Connect to providers
4. Test navigation flow
5. Commit

---

## Phase 10: Supabase Realtime Integration

### Task 31: Enable Realtime for messages table

```sql
-- supabase/migrations/005_enable_realtime.sql
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
```

### Task 32: Flutter Realtime subscription for chat

```dart
// In chat provider, subscribe to Supabase Realtime channel
// Listen for INSERT events on messages table filtered by match_id
```

**Commit after each task.**

---

## Execution Order Summary

| # | Task | Phase | Dependency |
|---|------|-------|------------|
| 1 | Init Express+TS | Backend Foundation | None |
| 2 | Supabase+Firebase config | Backend Foundation | 1 |
| 3 | DB Migrations | Backend Foundation | 2 |
| 4 | Types+Errors+Middleware | Backend Foundation | 1 |
| 5 | JWT+Hash+Auth middleware | Auth | 4 |
| 6 | Email utility | Auth | 5 |
| 7 | Auth service+routes | Auth | 5, 6 |
| 8 | User service+routes | User | 7 |
| 9 | Question service+routes | Questions | 7 |
| 10 | Notification service | Matching | 2 |
| 11 | Scoring+Matching+Discover | Matching | 10 |
| 12 | Diamond service | Diamond | 7 |
| 13 | Quiz service (core game) | Quiz | 11, 12 |
| 14 | Chat service | Chat | 10 |
| 15 | Passport+Boost+Report | Extras | 12 |
| 16 | Wire all routes | Backend Complete | 7-15 |
| 17 | Init Flutter project | Mobile Foundation | None (parallel) |
| 18 | Core layer | Mobile Foundation | 17 |
| 19 | Data layer (models+repos) | Mobile Foundation | 18 |
| 20 | Providers | Mobile Foundation | 19 |
| 21 | Routing+App entry | Mobile Foundation | 20 |
| 22-30 | Feature screens | Mobile Features | 21 |
| 31-32 | Realtime chat | Integration | 14, 26 |

Backend tasks (1-16) ve Mobile foundation (17-21) paralel olarak gelistirilebilir.
