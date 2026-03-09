# Qulo V2 Backoffice Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Express server'a entegre, EJS template'li, guvenli bir admin backoffice paneli eklemek.

**Architecture:** Ayni Express uygulamasina `/admin` prefix'li route'lar eklenir. Session-based auth (httpOnly cookie), IP whitelist, CSRF korumasiyla guvenlik saglanir. Ayri `admin_users` tablosu kullanilir. EJS ile server-side render yapilir.

**Tech Stack:** EJS, express-session, bcryptjs (mevcut), Supabase (mevcut)

---

## Task 1: Dependencies & EJS Setup

**Files:**
- Modify: `server/package.json`
- Modify: `server/src/index.ts`
- Modify: `server/tsconfig.json`

**Step 1: Install dependencies**

```bash
cd server && npm install ejs express-session && npm install -D @types/express-session
```

**Step 2: Configure EJS in index.ts**

Add after `const app = express();` and before middleware block in `server/src/index.ts`:

```typescript
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "admin", "views"));
```

**Step 3: Verify EJS renders**

Create a minimal test view `server/src/admin/views/test.ejs`:
```html
<h1>Admin Works</h1>
```

Add a temp route in index.ts:
```typescript
app.get("/admin/test", (_req, res) => res.render("test"));
```

Run: `cd server && npm run dev`
Visit: `http://localhost:3000/admin/test`
Expected: "Admin Works" text rendered.

**Step 4: Remove test view & route, commit**

```bash
rm server/src/admin/views/test.ejs
git add -A && git commit -m "feat(admin): add ejs + express-session dependencies"
```

---

## Task 2: Admin Users Migration

**Files:**
- Create: `supabase/migrations/006_admin_users.sql`

**Step 1: Write migration SQL**

```sql
-- Admin users table (separate from app users)
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'ADMIN' CHECK (role IN ('SUPER_ADMIN', 'ADMIN')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login_at TIMESTAMPTZ
);

-- Disable RLS (service_role access)
ALTER TABLE admin_users DISABLE ROW LEVEL SECURITY;
```

**Step 2: Run migration in Supabase SQL Editor**

Copy-paste the SQL into Supabase dashboard SQL Editor and run it.

**Step 3: Commit**

```bash
git add supabase/migrations/006_admin_users.sql
git commit -m "feat(admin): add admin_users migration"
```

---

## Task 3: Admin Env Variables

**Files:**
- Modify: `server/src/config/env.ts`

**Step 1: Add admin env variables to schema**

Add these fields to the `envSchema` object in `server/src/config/env.ts`:

```typescript
// Admin
ADMIN_SESSION_SECRET: z.string().min(1),
ADMIN_SEED_EMAIL: z.string().email().optional(),
ADMIN_SEED_PASSWORD: z.string().min(8).optional(),
ADMIN_ALLOWED_IPS: z.string().optional(), // comma-separated: "1.2.3.4,5.6.7.8"
```

**Step 2: Add to .env file**

```
ADMIN_SESSION_SECRET=your-super-secret-session-key-change-in-production
ADMIN_SEED_EMAIL=admin@qulo.app
ADMIN_SEED_PASSWORD=AdminQulo2026!
ADMIN_ALLOWED_IPS=
```

**Step 3: Run dev to verify env loads**

Run: `cd server && npm run dev`
Expected: Server starts without env validation errors.

**Step 4: Commit**

```bash
git add server/src/config/env.ts
git commit -m "feat(admin): add admin env variables"
```

---

## Task 4: Admin Middleware (Auth, IP Whitelist, CSRF)

**Files:**
- Create: `server/src/admin/admin.middleware.ts`

**Step 1: Write admin middleware**

```typescript
import type { Request, Response, NextFunction } from "express";
import { env } from "../config/env.js";
import crypto from "crypto";

// Extend session type
declare module "express-session" {
  interface SessionData {
    adminId?: string;
    adminEmail?: string;
    adminRole?: string;
    csrfToken?: string;
  }
}

// Session auth check
export function adminAuth(req: Request, res: Response, next: NextFunction): void {
  if (!req.session.adminId) {
    res.redirect("/admin/login");
    return;
  }
  // Session timeout: 2 hours
  const maxAge = 2 * 60 * 60 * 1000;
  if (req.session.cookie.maxAge !== undefined && req.session.cookie.maxAge < 0) {
    req.session.destroy(() => {
      res.redirect("/admin/login");
    });
    return;
  }
  // Refresh session
  req.session.cookie.maxAge = maxAge;
  next();
}

// Super admin only
export function superAdminOnly(req: Request, res: Response, next: NextFunction): void {
  if (req.session.adminRole !== "SUPER_ADMIN") {
    res.status(403).render("error", { message: "Access denied. Super Admin only." });
    return;
  }
  next();
}

// IP whitelist
export function ipWhitelist(req: Request, res: Response, next: NextFunction): void {
  const allowedIps = env.ADMIN_ALLOWED_IPS;
  if (!allowedIps || allowedIps.trim() === "") {
    next();
    return;
  }

  const allowed = allowedIps.split(",").map((ip) => ip.trim());
  const clientIp = req.ip || req.socket.remoteAddress || "";

  if (!allowed.includes(clientIp)) {
    res.status(403).send("Forbidden");
    return;
  }
  next();
}

// CSRF token generation & validation
export function csrfGenerate(req: Request, _res: Response, next: NextFunction): void {
  if (!req.session.csrfToken) {
    req.session.csrfToken = crypto.randomBytes(32).toString("hex");
  }
  next();
}

export function csrfValidate(req: Request, res: Response, next: NextFunction): void {
  const token = req.body._csrf;
  if (!token || token !== req.session.csrfToken) {
    res.status(403).render("error", { message: "Invalid CSRF token. Please try again." });
    return;
  }
  // Regenerate after use
  req.session.csrfToken = crypto.randomBytes(32).toString("hex");
  next();
}
```

**Step 2: Commit**

```bash
git add server/src/admin/admin.middleware.ts
git commit -m "feat(admin): add admin middleware (auth, IP, CSRF)"
```

---

## Task 5: Admin Service (DB Queries)

**Files:**
- Create: `server/src/admin/admin.service.ts`

**Step 1: Write admin service**

```typescript
import { supabase } from "../config/supabase.js";
import { hashPassword, comparePassword } from "../utils/hash.js";

class AdminService {
  // --- Auth ---
  async findByEmail(email: string) {
    const { data } = await supabase
      .from("admin_users")
      .select("*")
      .eq("email", email)
      .single();
    return data;
  }

  async validateLogin(email: string, password: string) {
    const admin = await this.findByEmail(email);
    if (!admin) return null;
    const valid = await comparePassword(password, admin.password_hash);
    if (!valid) return null;
    await supabase
      .from("admin_users")
      .update({ last_login_at: new Date().toISOString() })
      .eq("id", admin.id);
    return admin;
  }

  async seedAdmin(email: string, password: string) {
    const existing = await this.findByEmail(email);
    if (existing) return;
    const password_hash = await hashPassword(password);
    await supabase.from("admin_users").insert({
      email,
      password_hash,
      role: "SUPER_ADMIN",
    });
    console.log(`[admin] Seed admin created: ${email}`);
  }

  // --- Dashboard ---
  async getDashboardStats() {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();

    const [
      { count: totalUsers },
      { count: activeUsers },
      { count: todayRegistrations },
      { count: totalMatches },
      { count: pendingReports },
    ] = await Promise.all([
      supabase.from("users").select("*", { count: "exact", head: true }).eq("is_deleted", false),
      supabase.from("users").select("*", { count: "exact", head: true }).eq("is_deleted", false).gte("last_seen_at", sevenDaysAgo),
      supabase.from("users").select("*", { count: "exact", head: true }).gte("created_at", todayStart),
      supabase.from("matches").select("*", { count: "exact", head: true }),
      supabase.from("reports").select("*", { count: "exact", head: true }).eq("status", "PENDING"),
    ]);

    // Diamond circulation
    const { data: greenSum } = await supabase.rpc("admin_sum_diamonds", { diamond_type: "GREEN" });
    const { data: purpleSum } = await supabase.rpc("admin_sum_diamonds", { diamond_type: "PURPLE" });

    return {
      totalUsers: totalUsers ?? 0,
      activeUsers: activeUsers ?? 0,
      todayRegistrations: todayRegistrations ?? 0,
      totalMatches: totalMatches ?? 0,
      pendingReports: pendingReports ?? 0,
      greenDiamondCirculation: greenSum ?? 0,
      purpleDiamondCirculation: purpleSum ?? 0,
    };
  }

  // --- Users ---
  async getUsers(page: number, limit: number, search?: string, gender?: string) {
    let query = supabase
      .from("users")
      .select("id, email, name, surname, age, gender, city, green_diamonds, purple_diamonds, is_online, is_deleted, created_at, last_seen_at, photos", { count: "exact" })
      .eq("is_deleted", false)
      .order("created_at", { ascending: false })
      .range((page - 1) * limit, page * limit - 1);

    if (search) {
      query = query.or(`email.ilike.%${search}%,name.ilike.%${search}%,surname.ilike.%${search}%`);
    }
    if (gender && gender !== "all") {
      query = query.eq("gender", gender);
    }

    const { data, count } = await query;
    return { users: data ?? [], total: count ?? 0 };
  }

  async getUserDetail(userId: string) {
    const { data: user } = await supabase
      .from("users")
      .select("*")
      .eq("id", userId)
      .single();

    const { data: details } = await supabase
      .from("user_details")
      .select("*")
      .eq("user_id", userId)
      .single();

    const { data: questions } = await supabase
      .from("questions")
      .select("*")
      .eq("user_id", userId)
      .order("order_num");

    return { user, details, questions: questions ?? [] };
  }

  async banUser(userId: string) {
    await supabase.from("users").update({ is_deleted: true }).eq("id", userId);
  }

  async unbanUser(userId: string) {
    await supabase.from("users").update({ is_deleted: false }).eq("id", userId);
  }

  async deleteUser(userId: string) {
    await supabase.from("users").delete().eq("id", userId);
  }

  async updateDiamonds(userId: string, green: number, purple: number) {
    await supabase
      .from("users")
      .update({ green_diamonds: green, purple_diamonds: purple })
      .eq("id", userId);
  }

  // --- Reports ---
  async getReports(page: number, limit: number, status?: string) {
    let query = supabase
      .from("reports")
      .select("*", { count: "exact" })
      .order("created_at", { ascending: false })
      .range((page - 1) * limit, page * limit - 1);

    if (status && status !== "all") {
      query = query.eq("status", status);
    }

    const { data, count } = await query;
    return { reports: data ?? [], total: count ?? 0 };
  }

  async getReportDetail(reportId: string) {
    const { data: report } = await supabase
      .from("reports")
      .select("*")
      .eq("id", reportId)
      .single();

    if (!report) return null;

    const [{ data: reporter }, { data: reported }] = await Promise.all([
      supabase.from("users").select("id, email, name, surname, photos").eq("id", report.reporter_id).single(),
      supabase.from("users").select("id, email, name, surname, photos, is_deleted").eq("id", report.reported_id).single(),
    ]);

    return { report, reporter, reported };
  }

  async updateReportStatus(reportId: string, status: string) {
    await supabase.from("reports").update({ status }).eq("id", reportId);
  }

  // --- Matches ---
  async getMatches(page: number, limit: number, active?: string) {
    let query = supabase
      .from("matches")
      .select("*", { count: "exact" })
      .order("matched_at", { ascending: false })
      .range((page - 1) * limit, page * limit - 1);

    if (active === "true") query = query.eq("is_active", true);
    if (active === "false") query = query.eq("is_active", false);

    const { data, count } = await query;

    // Fetch user names for each match
    if (data && data.length > 0) {
      const userIds = [...new Set(data.flatMap((m: any) => [m.user1_id, m.user2_id]))];
      const { data: users } = await supabase
        .from("users")
        .select("id, name, surname, email")
        .in("id", userIds);

      const userMap = new Map((users ?? []).map((u: any) => [u.id, u]));
      const enriched = data.map((m: any) => ({
        ...m,
        user1: userMap.get(m.user1_id),
        user2: userMap.get(m.user2_id),
      }));
      return { matches: enriched, total: count ?? 0 };
    }

    return { matches: data ?? [], total: count ?? 0 };
  }

  // --- Transactions ---
  async getTransactions(page: number, limit: number, type?: string, userId?: string) {
    let query = supabase
      .from("diamond_transactions")
      .select("*", { count: "exact" })
      .order("created_at", { ascending: false })
      .range((page - 1) * limit, page * limit - 1);

    if (type && type !== "all") query = query.eq("type", type);
    if (userId) query = query.eq("user_id", userId);

    const { data, count } = await query;
    return { transactions: data ?? [], total: count ?? 0 };
  }

  // --- Quiz Stats ---
  async getQuizStats() {
    const [
      { count: totalSessions },
      { count: completedSessions },
      { count: failedSessions },
    ] = await Promise.all([
      supabase.from("quiz_sessions").select("*", { count: "exact", head: true }),
      supabase.from("quiz_sessions").select("*", { count: "exact", head: true }).eq("status", "COMPLETED"),
      supabase.from("quiz_sessions").select("*", { count: "exact", head: true }).eq("status", "FAILED"),
    ]);

    // Power usage
    const { data: powerUsage } = await supabase
      .from("quiz_answers")
      .select("power_used")
      .not("power_used", "is", null);

    const powerCounts: Record<string, number> = {};
    (powerUsage ?? []).forEach((a: any) => {
      powerCounts[a.power_used] = (powerCounts[a.power_used] || 0) + 1;
    });

    return {
      totalSessions: totalSessions ?? 0,
      completedSessions: completedSessions ?? 0,
      failedSessions: failedSessions ?? 0,
      successRate: totalSessions ? Math.round(((completedSessions ?? 0) / totalSessions) * 100) : 0,
      powerUsage: powerCounts,
    };
  }

  // --- Admin Management ---
  async getAdmins() {
    const { data } = await supabase
      .from("admin_users")
      .select("id, email, role, created_at, last_login_at")
      .order("created_at");
    return data ?? [];
  }

  async createAdmin(email: string, password: string, role: string) {
    const existing = await this.findByEmail(email);
    if (existing) throw new Error("Admin already exists");
    const password_hash = await hashPassword(password);
    await supabase.from("admin_users").insert({ email, password_hash, role });
  }

  async deleteAdmin(adminId: string) {
    await supabase.from("admin_users").delete().eq("id", adminId);
  }
}

export const adminService = new AdminService();
```

**Step 2: Create RPC function for diamond sums**

Create `supabase/migrations/007_admin_rpc.sql`:

```sql
-- RPC for admin dashboard diamond sum
CREATE OR REPLACE FUNCTION admin_sum_diamonds(diamond_type TEXT)
RETURNS BIGINT AS $$
  SELECT COALESCE(SUM(ABS(amount)), 0)
  FROM diamond_transactions
  WHERE type = diamond_type AND amount < 0;
$$ LANGUAGE sql STABLE;
```

Run this in Supabase SQL Editor.

**Step 3: Commit**

```bash
git add server/src/admin/admin.service.ts supabase/migrations/007_admin_rpc.sql
git commit -m "feat(admin): add admin service with all DB queries"
```

---

## Task 6: Admin Routes & Controller

**Files:**
- Create: `server/src/admin/admin.routes.ts`
- Create: `server/src/admin/admin.controller.ts`

**Step 1: Write admin controller**

```typescript
import type { Request, Response } from "express";
import { adminService } from "./admin.service.js";

class AdminController {
  // --- Auth ---
  loginPage(req: Request, res: Response) {
    if (req.session.adminId) return res.redirect("/admin");
    res.render("login", { error: null, csrfToken: req.session.csrfToken });
  }

  async loginPost(req: Request, res: Response) {
    const { email, password } = req.body;
    const admin = await adminService.validateLogin(email, password);
    if (!admin) {
      return res.render("login", { error: "Invalid credentials", csrfToken: req.session.csrfToken });
    }
    req.session.adminId = admin.id;
    req.session.adminEmail = admin.email;
    req.session.adminRole = admin.role;
    res.redirect("/admin");
  }

  logout(req: Request, res: Response) {
    req.session.destroy(() => {
      res.redirect("/admin/login");
    });
  }

  // --- Dashboard ---
  async dashboard(req: Request, res: Response) {
    const stats = await adminService.getDashboardStats();
    res.render("dashboard", { stats, session: req.session });
  }

  // --- Users ---
  async users(req: Request, res: Response) {
    const page = parseInt(req.query.page as string) || 1;
    const search = req.query.search as string;
    const gender = req.query.gender as string;
    const { users, total } = await adminService.getUsers(page, 20, search, gender);
    const totalPages = Math.ceil(total / 20);
    res.render("users", { users, page, totalPages, total, search: search || "", gender: gender || "all", session: req.session });
  }

  async userDetail(req: Request, res: Response) {
    const { user, details, questions } = await adminService.getUserDetail(req.params.id);
    if (!user) return res.status(404).render("error", { message: "User not found" });
    res.render("user-detail", { user, details, questions, session: req.session, csrfToken: req.session.csrfToken });
  }

  async userAction(req: Request, res: Response) {
    const { id } = req.params;
    const { action, green_diamonds, purple_diamonds } = req.body;

    if (action === "ban") await adminService.banUser(id);
    else if (action === "unban") await adminService.unbanUser(id);
    else if (action === "delete") await adminService.deleteUser(id);
    else if (action === "update_diamonds") {
      await adminService.updateDiamonds(id, parseInt(green_diamonds), parseInt(purple_diamonds));
    }

    res.redirect(`/admin/users/${id}`);
  }

  // --- Reports ---
  async reports(req: Request, res: Response) {
    const page = parseInt(req.query.page as string) || 1;
    const status = req.query.status as string;
    const { reports, total } = await adminService.getReports(page, 20, status);
    const totalPages = Math.ceil(total / 20);
    res.render("reports", { reports, page, totalPages, total, status: status || "all", session: req.session });
  }

  async reportDetail(req: Request, res: Response) {
    const result = await adminService.getReportDetail(req.params.id);
    if (!result) return res.status(404).render("error", { message: "Report not found" });
    res.render("report-detail", { ...result, session: req.session, csrfToken: req.session.csrfToken });
  }

  async reportAction(req: Request, res: Response) {
    const { id } = req.params;
    const { status, ban_user } = req.body;
    await adminService.updateReportStatus(id, status);
    if (ban_user) {
      const detail = await adminService.getReportDetail(id);
      if (detail?.reported) await adminService.banUser(detail.reported.id);
    }
    res.redirect(`/admin/reports/${id}`);
  }

  // --- Matches ---
  async matches(req: Request, res: Response) {
    const page = parseInt(req.query.page as string) || 1;
    const active = req.query.active as string;
    const { matches, total } = await adminService.getMatches(page, 20, active);
    const totalPages = Math.ceil(total / 20);
    res.render("matches", { matches, page, totalPages, total, active: active || "all", session: req.session });
  }

  // --- Transactions ---
  async transactions(req: Request, res: Response) {
    const page = parseInt(req.query.page as string) || 1;
    const type = req.query.type as string;
    const userId = req.query.userId as string;
    const { transactions, total } = await adminService.getTransactions(page, 30, type, userId);
    const totalPages = Math.ceil(total / 30);
    res.render("transactions", { transactions, page, totalPages, total, type: type || "all", userId: userId || "", session: req.session });
  }

  // --- Quiz Stats ---
  async quizStats(req: Request, res: Response) {
    const stats = await adminService.getQuizStats();
    res.render("quiz-stats", { stats, session: req.session });
  }

  // --- Admin Management ---
  async admins(req: Request, res: Response) {
    const admins = await adminService.getAdmins();
    res.render("admins", { admins, session: req.session, csrfToken: req.session.csrfToken, error: null });
  }

  async createAdmin(req: Request, res: Response) {
    const { email, password, role } = req.body;
    try {
      await adminService.createAdmin(email, password, role || "ADMIN");
      res.redirect("/admin/admins");
    } catch (e: any) {
      const admins = await adminService.getAdmins();
      res.render("admins", { admins, session: req.session, csrfToken: req.session.csrfToken, error: e.message });
    }
  }

  async deleteAdminAction(req: Request, res: Response) {
    // Prevent self-delete
    if (req.params.id === req.session.adminId) {
      return res.redirect("/admin/admins");
    }
    await adminService.deleteAdmin(req.params.id);
    res.redirect("/admin/admins");
  }
}

export const adminController = new AdminController();
```

**Step 2: Write admin routes**

```typescript
import { Router } from "express";
import { adminController } from "./admin.controller.js";
import { adminAuth, superAdminOnly, ipWhitelist, csrfGenerate, csrfValidate } from "./admin.middleware.js";
import rateLimit from "express-rate-limit";

const router = Router();

// IP whitelist for all admin routes
router.use(ipWhitelist);

// Rate limit for login
const adminLoginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  message: "Too many login attempts. Try again in 15 minutes.",
});

// --- Public (login) ---
router.get("/login", csrfGenerate, (req, res) => adminController.loginPage(req, res));
router.post("/login", adminLoginLimiter, csrfGenerate, csrfValidate, (req, res) => adminController.loginPost(req, res));

// --- Protected ---
router.use(adminAuth);
router.use(csrfGenerate);

router.get("/logout", (req, res) => adminController.logout(req, res));
router.get("/", (req, res) => adminController.dashboard(req, res));

// Users
router.get("/users", (req, res) => adminController.users(req, res));
router.get("/users/:id", (req, res) => adminController.userDetail(req, res));
router.post("/users/:id/action", csrfValidate, (req, res) => adminController.userAction(req, res));

// Reports
router.get("/reports", (req, res) => adminController.reports(req, res));
router.get("/reports/:id", (req, res) => adminController.reportDetail(req, res));
router.post("/reports/:id/action", csrfValidate, (req, res) => adminController.reportAction(req, res));

// Matches
router.get("/matches", (req, res) => adminController.matches(req, res));

// Transactions
router.get("/transactions", (req, res) => adminController.transactions(req, res));

// Quiz Stats
router.get("/quiz-stats", (req, res) => adminController.quizStats(req, res));

// Admin Management (Super Admin only)
router.get("/admins", superAdminOnly, (req, res) => adminController.admins(req, res));
router.post("/admins", superAdminOnly, csrfValidate, (req, res) => adminController.createAdmin(req, res));
router.post("/admins/:id/delete", superAdminOnly, csrfValidate, (req, res) => adminController.deleteAdminAction(req, res));

export default router;
```

**Step 3: Commit**

```bash
git add server/src/admin/admin.controller.ts server/src/admin/admin.routes.ts
git commit -m "feat(admin): add admin routes and controller"
```

---

## Task 7: Register Admin Routes in Express & Seed Admin

**Files:**
- Modify: `server/src/index.ts`

**Step 1: Add session middleware and admin routes to index.ts**

Add imports at the top:
```typescript
import session from "express-session";
import adminRoutes from "./admin/admin.routes.js";
import { adminService } from "./admin/admin.service.js";
```

Add session middleware BEFORE routes (after `app.use(express.json(...))`):
```typescript
// Admin session middleware
app.use(
  session({
    secret: env.ADMIN_SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      secure: env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 2 * 60 * 60 * 1000, // 2 hours
    },
  }),
);

// Parse URL-encoded bodies for admin forms
app.use("/admin", express.urlencoded({ extended: false }));
```

Add admin routes BEFORE API routes:
```typescript
// Admin backoffice
app.use("/admin", adminRoutes);
```

Add seed admin after `app.listen`:
```typescript
// Seed admin user
if (env.ADMIN_SEED_EMAIL && env.ADMIN_SEED_PASSWORD) {
  adminService.seedAdmin(env.ADMIN_SEED_EMAIL, env.ADMIN_SEED_PASSWORD).catch(console.error);
}
```

**Step 2: Run dev and verify seed**

Run: `cd server && npm run dev`
Expected: `[admin] Seed admin created: admin@qulo.app` (first run only)

**Step 3: Commit**

```bash
git add server/src/index.ts
git commit -m "feat(admin): register admin routes and seed admin"
```

---

## Task 8: EJS Layout Template

**Files:**
- Create: `server/src/admin/views/layout.ejs`
- Create: `server/src/admin/views/error.ejs`

**Step 1: Write layout template**

Create `server/src/admin/views/layout.ejs`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Qulo Admin - <%= typeof title !== 'undefined' ? title : 'Backoffice' %></title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; color: #333; }
    .nav { background: #1a1a2e; color: #fff; padding: 12px 24px; display: flex; align-items: center; gap: 24px; }
    .nav a { color: #ccc; text-decoration: none; font-size: 14px; padding: 6px 12px; border-radius: 4px; }
    .nav a:hover, .nav a.active { color: #fff; background: rgba(255,255,255,0.1); }
    .nav .brand { font-weight: bold; font-size: 18px; color: #a855f7; margin-right: 16px; }
    .nav .right { margin-left: auto; font-size: 13px; color: #999; display: flex; align-items: center; gap: 12px; }
    .container { max-width: 1200px; margin: 24px auto; padding: 0 24px; }
    .card { background: #fff; border-radius: 8px; padding: 20px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
    .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 24px; }
    .stat-card { background: #fff; border-radius: 8px; padding: 20px; text-align: center; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
    .stat-card .value { font-size: 32px; font-weight: bold; color: #1a1a2e; }
    .stat-card .label { font-size: 13px; color: #666; margin-top: 4px; }
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #eee; font-size: 14px; }
    th { background: #fafafa; font-weight: 600; color: #555; }
    tr:hover { background: #fafafa; }
    .btn { display: inline-block; padding: 6px 16px; border-radius: 4px; border: none; cursor: pointer; font-size: 13px; text-decoration: none; }
    .btn-primary { background: #a855f7; color: #fff; }
    .btn-danger { background: #ef4444; color: #fff; }
    .btn-success { background: #22c55e; color: #fff; }
    .btn-sm { padding: 4px 10px; font-size: 12px; }
    input[type="text"], input[type="email"], input[type="password"], select {
      padding: 8px 12px; border: 1px solid #ddd; border-radius: 4px; font-size: 14px;
    }
    .filters { display: flex; gap: 12px; align-items: center; margin-bottom: 16px; flex-wrap: wrap; }
    .pagination { display: flex; gap: 8px; justify-content: center; margin-top: 16px; }
    .pagination a { padding: 6px 12px; border: 1px solid #ddd; border-radius: 4px; text-decoration: none; color: #333; font-size: 13px; }
    .pagination a.active { background: #a855f7; color: #fff; border-color: #a855f7; }
    .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; }
    .badge-pending { background: #fef3c7; color: #92400e; }
    .badge-reviewed { background: #dbeafe; color: #1e40af; }
    .badge-resolved { background: #d1fae5; color: #065f46; }
    .badge-online { background: #d1fae5; color: #065f46; }
    .badge-offline { background: #f3f4f6; color: #6b7280; }
    .detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    .detail-grid dt { font-weight: 600; color: #555; }
    .detail-grid dd { color: #333; }
    .alert { padding: 12px 16px; border-radius: 6px; margin-bottom: 16px; font-size: 14px; }
    .alert-error { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
    .photos-grid { display: flex; gap: 8px; flex-wrap: wrap; }
    .photos-grid img { width: 80px; height: 80px; object-fit: cover; border-radius: 6px; }
  </style>
</head>
<body>
  <% if (typeof session !== 'undefined' && session.adminId) { %>
  <nav class="nav">
    <span class="brand">Qulo Admin</span>
    <a href="/admin" class="<%= typeof title !== 'undefined' && title === 'Dashboard' ? 'active' : '' %>">Dashboard</a>
    <a href="/admin/users" class="<%= typeof title !== 'undefined' && title === 'Users' ? 'active' : '' %>">Users</a>
    <a href="/admin/reports" class="<%= typeof title !== 'undefined' && title === 'Reports' ? 'active' : '' %>">Reports</a>
    <a href="/admin/matches" class="<%= typeof title !== 'undefined' && title === 'Matches' ? 'active' : '' %>">Matches</a>
    <a href="/admin/transactions" class="<%= typeof title !== 'undefined' && title === 'Transactions' ? 'active' : '' %>">Transactions</a>
    <a href="/admin/quiz-stats" class="<%= typeof title !== 'undefined' && title === 'Quiz Stats' ? 'active' : '' %>">Quiz Stats</a>
    <% if (session.adminRole === 'SUPER_ADMIN') { %>
    <a href="/admin/admins" class="<%= typeof title !== 'undefined' && title === 'Admins' ? 'active' : '' %>">Admins</a>
    <% } %>
    <div class="right">
      <span><%= session.adminEmail %></span>
      <a href="/admin/logout" style="color: #ef4444;">Logout</a>
    </div>
  </nav>
  <% } %>
  <div class="container">
    <%- body %>
  </div>
</body>
</html>
```

**Step 2: Write error template**

Create `server/src/admin/views/error.ejs`:

```html
<% var title = 'Error'; %>
<%- include('layout', { body: ` %>
<div class="card">
  <h2>Error</h2>
  <p style="margin-top: 12px; color: #ef4444;"><%= message %></p>
  <a href="/admin" class="btn btn-primary" style="margin-top: 16px;">Back to Dashboard</a>
</div>
<% ` }) %>
```

NOTE: EJS does not support nested includes this way. Instead, each page will be a standalone file that uses include for the layout header/footer. We will use a simpler approach: each view includes a `_header.ejs` and `_footer.ejs` partial.

**Revised approach — create partials:**

Create `server/src/admin/views/_header.ejs`:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Qulo Admin</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; color: #333; }
    .nav { background: #1a1a2e; color: #fff; padding: 12px 24px; display: flex; align-items: center; gap: 24px; }
    .nav a { color: #ccc; text-decoration: none; font-size: 14px; padding: 6px 12px; border-radius: 4px; }
    .nav a:hover, .nav a.active { color: #fff; background: rgba(255,255,255,0.1); }
    .nav .brand { font-weight: bold; font-size: 18px; color: #a855f7; margin-right: 16px; }
    .nav .right { margin-left: auto; font-size: 13px; color: #999; display: flex; align-items: center; gap: 12px; }
    .container { max-width: 1200px; margin: 24px auto; padding: 0 24px; }
    .card { background: #fff; border-radius: 8px; padding: 20px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
    .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 24px; }
    .stat-card { background: #fff; border-radius: 8px; padding: 20px; text-align: center; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
    .stat-card .value { font-size: 32px; font-weight: bold; color: #1a1a2e; }
    .stat-card .label { font-size: 13px; color: #666; margin-top: 4px; }
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #eee; font-size: 14px; }
    th { background: #fafafa; font-weight: 600; color: #555; }
    tr:hover { background: #fafafa; }
    .btn { display: inline-block; padding: 6px 16px; border-radius: 4px; border: none; cursor: pointer; font-size: 13px; text-decoration: none; }
    .btn-primary { background: #a855f7; color: #fff; }
    .btn-danger { background: #ef4444; color: #fff; }
    .btn-success { background: #22c55e; color: #fff; }
    .btn-sm { padding: 4px 10px; font-size: 12px; }
    input[type="text"], input[type="email"], input[type="password"], select {
      padding: 8px 12px; border: 1px solid #ddd; border-radius: 4px; font-size: 14px;
    }
    .filters { display: flex; gap: 12px; align-items: center; margin-bottom: 16px; flex-wrap: wrap; }
    .pagination { display: flex; gap: 8px; justify-content: center; margin-top: 16px; }
    .pagination a { padding: 6px 12px; border: 1px solid #ddd; border-radius: 4px; text-decoration: none; color: #333; font-size: 13px; }
    .pagination a.active { background: #a855f7; color: #fff; border-color: #a855f7; }
    .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; }
    .badge-pending { background: #fef3c7; color: #92400e; }
    .badge-reviewed { background: #dbeafe; color: #1e40af; }
    .badge-resolved { background: #d1fae5; color: #065f46; }
    .badge-online { background: #d1fae5; color: #065f46; }
    .badge-offline { background: #f3f4f6; color: #6b7280; }
    .detail-grid { display: grid; grid-template-columns: 200px 1fr; gap: 8px 16px; }
    .detail-grid dt { font-weight: 600; color: #555; }
    .detail-grid dd { color: #333; }
    .alert { padding: 12px 16px; border-radius: 6px; margin-bottom: 16px; font-size: 14px; }
    .alert-error { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
    .photos-grid { display: flex; gap: 8px; flex-wrap: wrap; }
    .photos-grid img { width: 80px; height: 80px; object-fit: cover; border-radius: 6px; }
  </style>
</head>
<body>
<% if (typeof session !== 'undefined' && session.adminId) { %>
<nav class="nav">
  <span class="brand">Qulo Admin</span>
  <a href="/admin">Dashboard</a>
  <a href="/admin/users">Users</a>
  <a href="/admin/reports">Reports</a>
  <a href="/admin/matches">Matches</a>
  <a href="/admin/transactions">Transactions</a>
  <a href="/admin/quiz-stats">Quiz Stats</a>
  <% if (session.adminRole === 'SUPER_ADMIN') { %>
  <a href="/admin/admins">Admins</a>
  <% } %>
  <div class="right">
    <span><%= session.adminEmail %></span>
    <a href="/admin/logout" style="color: #ef4444;">Logout</a>
  </div>
</nav>
<% } %>
<div class="container">
```

Create `server/src/admin/views/_footer.ejs`:
```html
</div>
</body>
</html>
```

Create `server/src/admin/views/error.ejs`:
```html
<%- include('_header') %>
<div class="card">
  <h2>Error</h2>
  <p style="margin-top: 12px; color: #ef4444;"><%= message %></p>
  <a href="/admin" class="btn btn-primary" style="margin-top: 16px;">Back to Dashboard</a>
</div>
<%- include('_footer') %>
```

**Step 3: Commit**

```bash
git add server/src/admin/views/
git commit -m "feat(admin): add EJS layout partials and error page"
```

---

## Task 9: Login Page

**Files:**
- Create: `server/src/admin/views/login.ejs`

**Step 1: Write login template**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Qulo Admin - Login</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #1a1a2e; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
    .login-card { background: #fff; border-radius: 12px; padding: 40px; width: 380px; box-shadow: 0 4px 24px rgba(0,0,0,0.2); }
    .login-card h1 { text-align: center; color: #a855f7; margin-bottom: 8px; }
    .login-card p { text-align: center; color: #999; font-size: 14px; margin-bottom: 24px; }
    .form-group { margin-bottom: 16px; }
    .form-group label { display: block; font-size: 13px; font-weight: 600; color: #555; margin-bottom: 4px; }
    .form-group input { width: 100%; padding: 10px 14px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; }
    .form-group input:focus { outline: none; border-color: #a855f7; }
    .btn-login { width: 100%; padding: 12px; background: #a855f7; color: #fff; border: none; border-radius: 6px; font-size: 15px; font-weight: 600; cursor: pointer; }
    .btn-login:hover { background: #9333ea; }
    .error { background: #fef2f2; color: #991b1b; padding: 10px 14px; border-radius: 6px; font-size: 13px; margin-bottom: 16px; text-align: center; }
  </style>
</head>
<body>
  <div class="login-card">
    <h1>Qulo Admin</h1>
    <p>Backoffice Panel</p>
    <% if (error) { %>
    <div class="error"><%= error %></div>
    <% } %>
    <form method="POST" action="/admin/login">
      <input type="hidden" name="_csrf" value="<%= csrfToken %>">
      <div class="form-group">
        <label>Email</label>
        <input type="email" name="email" required autocomplete="email">
      </div>
      <div class="form-group">
        <label>Password</label>
        <input type="password" name="password" required autocomplete="current-password">
      </div>
      <button type="submit" class="btn-login">Login</button>
    </form>
  </div>
</body>
</html>
```

**Step 2: Test login page**

Run: `cd server && npm run dev`
Visit: `http://localhost:3000/admin/login`
Expected: Login form rendered with purple branding.

**Step 3: Commit**

```bash
git add server/src/admin/views/login.ejs
git commit -m "feat(admin): add login page"
```

---

## Task 10: Dashboard Page

**Files:**
- Create: `server/src/admin/views/dashboard.ejs`

**Step 1: Write dashboard template**

```html
<%- include('_header') %>
<h2 style="margin-bottom: 20px;">Dashboard</h2>
<div class="stats-grid">
  <div class="stat-card">
    <div class="value"><%= stats.totalUsers %></div>
    <div class="label">Total Users</div>
  </div>
  <div class="stat-card">
    <div class="value"><%= stats.activeUsers %></div>
    <div class="label">Active (7d)</div>
  </div>
  <div class="stat-card">
    <div class="value"><%= stats.todayRegistrations %></div>
    <div class="label">Today Registrations</div>
  </div>
  <div class="stat-card">
    <div class="value"><%= stats.totalMatches %></div>
    <div class="label">Total Matches</div>
  </div>
  <div class="stat-card">
    <div class="value" style="color: #ef4444;"><%= stats.pendingReports %></div>
    <div class="label">Pending Reports</div>
  </div>
  <div class="stat-card">
    <div class="value" style="color: #22c55e;"><%= stats.greenDiamondCirculation %></div>
    <div class="label">Green Diamonds Spent</div>
  </div>
  <div class="stat-card">
    <div class="value" style="color: #a855f7;"><%= stats.purpleDiamondCirculation %></div>
    <div class="label">Purple Diamonds Spent</div>
  </div>
</div>
<%- include('_footer') %>
```

**Step 2: Commit**

```bash
git add server/src/admin/views/dashboard.ejs
git commit -m "feat(admin): add dashboard page"
```

---

## Task 11: Users List & Detail Pages

**Files:**
- Create: `server/src/admin/views/users.ejs`
- Create: `server/src/admin/views/user-detail.ejs`

**Step 1: Write users list template**

```html
<%- include('_header') %>
<h2 style="margin-bottom: 20px;">Users (<%= total %>)</h2>
<form class="filters" method="GET" action="/admin/users">
  <input type="text" name="search" placeholder="Search email/name..." value="<%= search %>">
  <select name="gender">
    <option value="all" <%= gender === 'all' ? 'selected' : '' %>>All Genders</option>
    <option value="MAN" <%= gender === 'MAN' ? 'selected' : '' %>>Man</option>
    <option value="WOMAN" <%= gender === 'WOMAN' ? 'selected' : '' %>>Woman</option>
  </select>
  <button type="submit" class="btn btn-primary">Filter</button>
</form>
<div class="card">
  <table>
    <thead>
      <tr>
        <th>Name</th>
        <th>Email</th>
        <th>Age</th>
        <th>Gender</th>
        <th>City</th>
        <th>Diamonds (G/P)</th>
        <th>Status</th>
        <th>Joined</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <% users.forEach(function(u) { %>
      <tr>
        <td><%= u.name %> <%= u.surname %></td>
        <td><%= u.email %></td>
        <td><%= u.age %></td>
        <td><%= u.gender %></td>
        <td><%= u.city || '-' %></td>
        <td><span style="color:#22c55e"><%= u.green_diamonds %></span> / <span style="color:#a855f7"><%= u.purple_diamonds %></span></td>
        <td><span class="badge <%= u.is_online ? 'badge-online' : 'badge-offline' %>"><%= u.is_online ? 'Online' : 'Offline' %></span></td>
        <td><%= new Date(u.created_at).toLocaleDateString() %></td>
        <td><a href="/admin/users/<%= u.id %>" class="btn btn-primary btn-sm">Detail</a></td>
      </tr>
      <% }); %>
    </tbody>
  </table>
</div>
<% if (totalPages > 1) { %>
<div class="pagination">
  <% for (var i = 1; i <= totalPages; i++) { %>
  <a href="/admin/users?page=<%= i %>&search=<%= search %>&gender=<%= gender %>" class="<%= i === page ? 'active' : '' %>"><%= i %></a>
  <% } %>
</div>
<% } %>
<%- include('_footer') %>
```

**Step 2: Write user detail template**

```html
<%- include('_header') %>
<a href="/admin/users" style="color:#a855f7; text-decoration:none; font-size:14px;">&larr; Back to Users</a>
<h2 style="margin: 12px 0 20px;"><%= user.name %> <%= user.surname %></h2>

<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
  <div class="card">
    <h3 style="margin-bottom: 12px;">Profile</h3>
    <dl class="detail-grid">
      <dt>Email</dt><dd><%= user.email %></dd>
      <dt>Age</dt><dd><%= user.age %></dd>
      <dt>Gender</dt><dd><%= user.gender %></dd>
      <dt>City</dt><dd><%= user.city || '-' %></dd>
      <dt>Bio</dt><dd><%= user.bio || '-' %></dd>
      <dt>Online</dt><dd><span class="badge <%= user.is_online ? 'badge-online' : 'badge-offline' %>"><%= user.is_online ? 'Yes' : 'No' %></span></dd>
      <dt>Verified</dt><dd><%= user.email_verified ? 'Yes' : 'No' %></dd>
      <dt>Banned</dt><dd><%= user.is_deleted ? 'Yes' : 'No' %></dd>
      <dt>Last Seen</dt><dd><%= user.last_seen_at ? new Date(user.last_seen_at).toLocaleString() : '-' %></dd>
      <dt>Joined</dt><dd><%= new Date(user.created_at).toLocaleString() %></dd>
      <dt>Profile %</dt><dd><%= user.profile_completion %>%</dd>
    </dl>
  </div>

  <div class="card">
    <h3 style="margin-bottom: 12px;">Diamonds & Actions</h3>
    <p style="margin-bottom: 8px;">
      <span style="color:#22c55e; font-weight:bold; font-size:24px;"><%= user.green_diamonds %></span> Green &nbsp;
      <span style="color:#a855f7; font-weight:bold; font-size:24px;"><%= user.purple_diamonds %></span> Purple
    </p>
    <form method="POST" action="/admin/users/<%= user.id %>/action" style="margin-bottom: 12px;">
      <input type="hidden" name="_csrf" value="<%= csrfToken %>">
      <input type="hidden" name="action" value="update_diamonds">
      <div style="display:flex; gap:8px; margin-bottom:8px;">
        <input type="text" name="green_diamonds" value="<%= user.green_diamonds %>" style="width:100px" placeholder="Green">
        <input type="text" name="purple_diamonds" value="<%= user.purple_diamonds %>" style="width:100px" placeholder="Purple">
        <button type="submit" class="btn btn-primary btn-sm">Update</button>
      </div>
    </form>
    <div style="display:flex; gap:8px;">
      <% if (user.is_deleted) { %>
      <form method="POST" action="/admin/users/<%= user.id %>/action">
        <input type="hidden" name="_csrf" value="<%= csrfToken %>">
        <input type="hidden" name="action" value="unban">
        <button type="submit" class="btn btn-success btn-sm">Unban</button>
      </form>
      <% } else { %>
      <form method="POST" action="/admin/users/<%= user.id %>/action">
        <input type="hidden" name="_csrf" value="<%= csrfToken %>">
        <input type="hidden" name="action" value="ban">
        <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('Ban this user?')">Ban</button>
      </form>
      <% } %>
      <form method="POST" action="/admin/users/<%= user.id %>/action">
        <input type="hidden" name="_csrf" value="<%= csrfToken %>">
        <input type="hidden" name="action" value="delete">
        <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('PERMANENTLY delete this user? This cannot be undone.')">Delete</button>
      </form>
    </div>
    <p style="margin-top:12px;"><a href="/admin/transactions?userId=<%= user.id %>" style="color:#a855f7;">View transactions &rarr;</a></p>
  </div>
</div>

<% if (user.photos && user.photos.length > 0) { %>
<div class="card">
  <h3 style="margin-bottom: 12px;">Photos (<%= user.photos.length %>)</h3>
  <div class="photos-grid">
    <% user.photos.forEach(function(photo) { %>
    <img src="<%= photo %>" alt="photo">
    <% }); %>
  </div>
</div>
<% } %>

<% if (questions.length > 0) { %>
<div class="card">
  <h3 style="margin-bottom: 12px;">Questions (<%= questions.length %>)</h3>
  <table>
    <thead><tr><th>#</th><th>Question</th><th>Correct</th><th>Stats (C/W)</th></tr></thead>
    <tbody>
      <% questions.forEach(function(q) { %>
      <tr>
        <td><%= q.order_num %></td>
        <td><%= q.question_text %></td>
        <td>Answer <%= q.correct_answer %></td>
        <td><span style="color:#22c55e"><%= q.stats_correct %></span> / <span style="color:#ef4444"><%= q.stats_wrong %></span></td>
      </tr>
      <% }); %>
    </tbody>
  </table>
</div>
<% } %>

<% if (details) { %>
<div class="card">
  <h3 style="margin-bottom: 12px;">Details</h3>
  <dl class="detail-grid">
    <dt>Height</dt><dd><%= details.height || '-' %></dd>
    <dt>Weight</dt><dd><%= details.weight || '-' %></dd>
    <dt>Zodiac</dt><dd><%= details.zodiac || '-' %></dd>
    <dt>Job</dt><dd><%= details.job || '-' %></dd>
    <dt>School</dt><dd><%= details.school || '-' %></dd>
    <dt>Smoking</dt><dd><%= details.smoking || '-' %></dd>
    <dt>Alcohol</dt><dd><%= details.alcohol || '-' %></dd>
    <dt>Pets</dt><dd><%= details.pets || '-' %></dd>
    <dt>Music</dt><dd><%= details.music_type || '-' %></dd>
    <dt>Personality</dt><dd><%= details.personality || '-' %></dd>
  </dl>
</div>
<% } %>
<%- include('_footer') %>
```

**Step 3: Commit**

```bash
git add server/src/admin/views/users.ejs server/src/admin/views/user-detail.ejs
git commit -m "feat(admin): add users list and detail pages"
```

---

## Task 12: Reports Pages

**Files:**
- Create: `server/src/admin/views/reports.ejs`
- Create: `server/src/admin/views/report-detail.ejs`

**Step 1: Write reports list template**

```html
<%- include('_header') %>
<h2 style="margin-bottom: 20px;">Reports (<%= total %>)</h2>
<form class="filters" method="GET" action="/admin/reports">
  <select name="status">
    <option value="all" <%= status === 'all' ? 'selected' : '' %>>All Status</option>
    <option value="PENDING" <%= status === 'PENDING' ? 'selected' : '' %>>Pending</option>
    <option value="REVIEWED" <%= status === 'REVIEWED' ? 'selected' : '' %>>Reviewed</option>
    <option value="RESOLVED" <%= status === 'RESOLVED' ? 'selected' : '' %>>Resolved</option>
  </select>
  <button type="submit" class="btn btn-primary">Filter</button>
</form>
<div class="card">
  <table>
    <thead><tr><th>Reporter</th><th>Reported</th><th>Reason</th><th>Status</th><th>Date</th><th></th></tr></thead>
    <tbody>
      <% reports.forEach(function(r) { %>
      <tr>
        <td><%= r.reporter_id.substring(0,8) %>...</td>
        <td><%= r.reported_id.substring(0,8) %>...</td>
        <td><%= r.reason.substring(0, 50) %></td>
        <td><span class="badge badge-<%= r.status.toLowerCase() %>"><%= r.status %></span></td>
        <td><%= new Date(r.created_at).toLocaleDateString() %></td>
        <td><a href="/admin/reports/<%= r.id %>" class="btn btn-primary btn-sm">Detail</a></td>
      </tr>
      <% }); %>
    </tbody>
  </table>
</div>
<% if (totalPages > 1) { %>
<div class="pagination">
  <% for (var i = 1; i <= totalPages; i++) { %>
  <a href="/admin/reports?page=<%= i %>&status=<%= status %>" class="<%= i === page ? 'active' : '' %>"><%= i %></a>
  <% } %>
</div>
<% } %>
<%- include('_footer') %>
```

**Step 2: Write report detail template**

```html
<%- include('_header') %>
<a href="/admin/reports" style="color:#a855f7; text-decoration:none; font-size:14px;">&larr; Back to Reports</a>
<h2 style="margin: 12px 0 20px;">Report Detail</h2>

<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
  <div class="card">
    <h3 style="margin-bottom: 12px;">Reporter</h3>
    <% if (reporter) { %>
    <dl class="detail-grid">
      <dt>Name</dt><dd><%= reporter.name %> <%= reporter.surname %></dd>
      <dt>Email</dt><dd><%= reporter.email %></dd>
    </dl>
    <a href="/admin/users/<%= reporter.id %>" class="btn btn-primary btn-sm" style="margin-top:8px;">View Profile</a>
    <% } else { %>
    <p>User not found</p>
    <% } %>
  </div>

  <div class="card">
    <h3 style="margin-bottom: 12px;">Reported</h3>
    <% if (reported) { %>
    <dl class="detail-grid">
      <dt>Name</dt><dd><%= reported.name %> <%= reported.surname %></dd>
      <dt>Email</dt><dd><%= reported.email %></dd>
      <dt>Banned</dt><dd><%= reported.is_deleted ? 'Yes' : 'No' %></dd>
    </dl>
    <a href="/admin/users/<%= reported.id %>" class="btn btn-primary btn-sm" style="margin-top:8px;">View Profile</a>
    <% } else { %>
    <p>User not found</p>
    <% } %>
  </div>
</div>

<div class="card">
  <h3 style="margin-bottom: 12px;">Report Info</h3>
  <dl class="detail-grid">
    <dt>Status</dt><dd><span class="badge badge-<%= report.status.toLowerCase() %>"><%= report.status %></span></dd>
    <dt>Reason</dt><dd><%= report.reason %></dd>
    <dt>Date</dt><dd><%= new Date(report.created_at).toLocaleString() %></dd>
  </dl>

  <% if (report.status !== 'RESOLVED') { %>
  <h4 style="margin: 16px 0 8px;">Take Action</h4>
  <div style="display:flex; gap:8px;">
    <form method="POST" action="/admin/reports/<%= report.id %>/action">
      <input type="hidden" name="_csrf" value="<%= csrfToken %>">
      <input type="hidden" name="status" value="REVIEWED">
      <button type="submit" class="btn btn-primary btn-sm">Mark Reviewed</button>
    </form>
    <form method="POST" action="/admin/reports/<%= report.id %>/action">
      <input type="hidden" name="_csrf" value="<%= csrfToken %>">
      <input type="hidden" name="status" value="RESOLVED">
      <button type="submit" class="btn btn-success btn-sm">Resolve</button>
    </form>
    <form method="POST" action="/admin/reports/<%= report.id %>/action">
      <input type="hidden" name="_csrf" value="<%= csrfToken %>">
      <input type="hidden" name="status" value="RESOLVED">
      <input type="hidden" name="ban_user" value="1">
      <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('Ban user and resolve report?')">Ban & Resolve</button>
    </form>
  </div>
  <% } %>
</div>
<%- include('_footer') %>
```

**Step 3: Commit**

```bash
git add server/src/admin/views/reports.ejs server/src/admin/views/report-detail.ejs
git commit -m "feat(admin): add reports list and detail pages"
```

---

## Task 13: Matches, Transactions, Quiz Stats Pages

**Files:**
- Create: `server/src/admin/views/matches.ejs`
- Create: `server/src/admin/views/transactions.ejs`
- Create: `server/src/admin/views/quiz-stats.ejs`

**Step 1: Write matches template**

```html
<%- include('_header') %>
<h2 style="margin-bottom: 20px;">Matches (<%= total %>)</h2>
<form class="filters" method="GET" action="/admin/matches">
  <select name="active">
    <option value="all" <%= active === 'all' ? 'selected' : '' %>>All</option>
    <option value="true" <%= active === 'true' ? 'selected' : '' %>>Active</option>
    <option value="false" <%= active === 'false' ? 'selected' : '' %>>Inactive</option>
  </select>
  <button type="submit" class="btn btn-primary">Filter</button>
</form>
<div class="card">
  <table>
    <thead><tr><th>User 1</th><th>User 2</th><th>Active</th><th>Matched At</th></tr></thead>
    <tbody>
      <% matches.forEach(function(m) { %>
      <tr>
        <td><% if (m.user1) { %><a href="/admin/users/<%= m.user1_id %>" style="color:#a855f7;"><%= m.user1.name %> <%= m.user1.surname %></a><% } else { %><%= m.user1_id.substring(0,8) %>...<% } %></td>
        <td><% if (m.user2) { %><a href="/admin/users/<%= m.user2_id %>" style="color:#a855f7;"><%= m.user2.name %> <%= m.user2.surname %></a><% } else { %><%= m.user2_id.substring(0,8) %>...<% } %></td>
        <td><span class="badge <%= m.is_active ? 'badge-online' : 'badge-offline' %>"><%= m.is_active ? 'Active' : 'Inactive' %></span></td>
        <td><%= new Date(m.matched_at).toLocaleString() %></td>
      </tr>
      <% }); %>
    </tbody>
  </table>
</div>
<% if (totalPages > 1) { %>
<div class="pagination">
  <% for (var i = 1; i <= totalPages; i++) { %>
  <a href="/admin/matches?page=<%= i %>&active=<%= active %>" class="<%= i === page ? 'active' : '' %>"><%= i %></a>
  <% } %>
</div>
<% } %>
<%- include('_footer') %>
```

**Step 2: Write transactions template**

```html
<%- include('_header') %>
<h2 style="margin-bottom: 20px;">Diamond Transactions (<%= total %>)</h2>
<form class="filters" method="GET" action="/admin/transactions">
  <select name="type">
    <option value="all" <%= type === 'all' ? 'selected' : '' %>>All Types</option>
    <option value="GREEN" <%= type === 'GREEN' ? 'selected' : '' %>>Green</option>
    <option value="PURPLE" <%= type === 'PURPLE' ? 'selected' : '' %>>Purple</option>
  </select>
  <input type="text" name="userId" placeholder="User ID" value="<%= userId %>">
  <button type="submit" class="btn btn-primary">Filter</button>
</form>
<div class="card">
  <table>
    <thead><tr><th>User</th><th>Type</th><th>Amount</th><th>Reason</th><th>Reference</th><th>Date</th></tr></thead>
    <tbody>
      <% transactions.forEach(function(t) { %>
      <tr>
        <td><a href="/admin/users/<%= t.user_id %>" style="color:#a855f7;"><%= t.user_id.substring(0,8) %>...</a></td>
        <td><span style="color: <%= t.type === 'GREEN' ? '#22c55e' : '#a855f7' %>; font-weight:600;"><%= t.type %></span></td>
        <td style="color: <%= t.amount > 0 ? '#22c55e' : '#ef4444' %>; font-weight:600;"><%= t.amount > 0 ? '+' : '' %><%= t.amount %></td>
        <td><%= t.reason %></td>
        <td><%= t.reference_id || '-' %></td>
        <td><%= new Date(t.created_at).toLocaleString() %></td>
      </tr>
      <% }); %>
    </tbody>
  </table>
</div>
<% if (totalPages > 1) { %>
<div class="pagination">
  <% for (var i = 1; i <= totalPages; i++) { %>
  <a href="/admin/transactions?page=<%= i %>&type=<%= type %>&userId=<%= userId %>" class="<%= i === page ? 'active' : '' %>"><%= i %></a>
  <% } %>
</div>
<% } %>
<%- include('_footer') %>
```

**Step 3: Write quiz stats template**

```html
<%- include('_header') %>
<h2 style="margin-bottom: 20px;">Quiz Statistics</h2>
<div class="stats-grid">
  <div class="stat-card">
    <div class="value"><%= stats.totalSessions %></div>
    <div class="label">Total Sessions</div>
  </div>
  <div class="stat-card">
    <div class="value" style="color: #22c55e;"><%= stats.completedSessions %></div>
    <div class="label">Completed</div>
  </div>
  <div class="stat-card">
    <div class="value" style="color: #ef4444;"><%= stats.failedSessions %></div>
    <div class="label">Failed</div>
  </div>
  <div class="stat-card">
    <div class="value" style="color: #a855f7;"><%= stats.successRate %>%</div>
    <div class="label">Success Rate</div>
  </div>
</div>
<div class="card">
  <h3 style="margin-bottom: 12px;">Power Usage</h3>
  <table>
    <thead><tr><th>Power</th><th>Times Used</th></tr></thead>
    <tbody>
      <% Object.entries(stats.powerUsage).sort((a, b) => b[1] - a[1]).forEach(function([power, count]) { %>
      <tr>
        <td><%= power %></td>
        <td><%= count %></td>
      </tr>
      <% }); %>
      <% if (Object.keys(stats.powerUsage).length === 0) { %>
      <tr><td colspan="2" style="text-align:center; color:#999;">No power usage data yet</td></tr>
      <% } %>
    </tbody>
  </table>
</div>
<%- include('_footer') %>
```

**Step 4: Commit**

```bash
git add server/src/admin/views/matches.ejs server/src/admin/views/transactions.ejs server/src/admin/views/quiz-stats.ejs
git commit -m "feat(admin): add matches, transactions, quiz stats pages"
```

---

## Task 14: Admin Management Page

**Files:**
- Create: `server/src/admin/views/admins.ejs`

**Step 1: Write admins template**

```html
<%- include('_header') %>
<h2 style="margin-bottom: 20px;">Admin Management</h2>

<% if (error) { %>
<div class="alert alert-error"><%= error %></div>
<% } %>

<div class="card">
  <h3 style="margin-bottom: 12px;">Add New Admin</h3>
  <form method="POST" action="/admin/admins" style="display:flex; gap:8px; flex-wrap:wrap;">
    <input type="hidden" name="_csrf" value="<%= csrfToken %>">
    <input type="email" name="email" placeholder="Email" required>
    <input type="password" name="password" placeholder="Password (min 8)" required minlength="8">
    <select name="role">
      <option value="ADMIN">Admin</option>
      <option value="SUPER_ADMIN">Super Admin</option>
    </select>
    <button type="submit" class="btn btn-primary">Add Admin</button>
  </form>
</div>

<div class="card">
  <h3 style="margin-bottom: 12px;">Current Admins</h3>
  <table>
    <thead><tr><th>Email</th><th>Role</th><th>Created</th><th>Last Login</th><th></th></tr></thead>
    <tbody>
      <% admins.forEach(function(a) { %>
      <tr>
        <td><%= a.email %></td>
        <td><span class="badge <%= a.role === 'SUPER_ADMIN' ? 'badge-reviewed' : 'badge-resolved' %>"><%= a.role %></span></td>
        <td><%= new Date(a.created_at).toLocaleDateString() %></td>
        <td><%= a.last_login_at ? new Date(a.last_login_at).toLocaleString() : 'Never' %></td>
        <td>
          <% if (a.id !== session.adminId) { %>
          <form method="POST" action="/admin/admins/<%= a.id %>/delete" style="display:inline;">
            <input type="hidden" name="_csrf" value="<%= csrfToken %>">
            <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('Delete this admin?')">Delete</button>
          </form>
          <% } %>
        </td>
      </tr>
      <% }); %>
    </tbody>
  </table>
</div>
<%- include('_footer') %>
```

**Step 2: Commit**

```bash
git add server/src/admin/views/admins.ejs
git commit -m "feat(admin): add admin management page"
```

---

## Task 15: Final Integration & Smoke Test

**Files:**
- Modify: `server/src/index.ts` (verify all wiring)

**Step 1: Start server and test full flow**

Run: `cd server && npm run dev`

Test checklist:
1. Visit `http://localhost:3000/admin/login` — login form renders
2. Login with seed credentials — redirects to dashboard
3. Dashboard shows stats
4. Navigate to Users — list renders
5. Click a user — detail page renders
6. Navigate to Reports, Matches, Transactions, Quiz Stats — all render
7. Navigate to Admins (Super Admin only) — admin management renders
8. Logout — redirects to login
9. Try accessing `/admin` without session — redirects to login
10. Try logging in with wrong credentials — shows error message

**Step 2: Commit final state**

```bash
git add -A && git commit -m "feat(admin): complete backoffice integration"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Dependencies & EJS setup | package.json, index.ts, tsconfig |
| 2 | admin_users migration | migration 006 |
| 3 | Admin env variables | env.ts, .env |
| 4 | Admin middleware (auth, IP, CSRF) | admin.middleware.ts |
| 5 | Admin service (all DB queries) | admin.service.ts, migration 007 |
| 6 | Admin routes & controller | admin.routes.ts, admin.controller.ts |
| 7 | Express integration & seed | index.ts |
| 8 | EJS layout partials | _header, _footer, error |
| 9 | Login page | login.ejs |
| 10 | Dashboard page | dashboard.ejs |
| 11 | Users list & detail | users.ejs, user-detail.ejs |
| 12 | Reports list & detail | reports.ejs, report-detail.ejs |
| 13 | Matches, transactions, quiz stats | matches.ejs, transactions.ejs, quiz-stats.ejs |
| 14 | Admin management | admins.ejs |
| 15 | Final integration & smoke test | verify all |
