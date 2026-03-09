---
name: add-endpoint
description: Add a new Express route with service, validator, controller, and auth middleware
disable-model-invocation: true
---

# Add Endpoint

Creates a new backend API endpoint with all required files following the project pattern.

## Arguments

- `<resource>` — Resource name in kebab-case (e.g., `feedback`, `block-list`)
- `<method>` — HTTP method: GET, POST, PUT, PATCH, DELETE
- `<path>` — Route path (e.g., `/`, `/:id`, `/me/stats`)
- `--no-auth` — (optional) Skip auth middleware
- `--admin` — (optional) Add admin middleware

## Steps

1. **Check if route file exists** at `server/src/routes/<resource>.routes.ts`
   - If not, create new route file (see template below)
   - If exists, add the new endpoint to it

2. **Check if service file exists** at `server/src/services/<resource>.service.ts`
   - If not, create with class pattern + singleton export (see template)
   - If exists, add new method

3. **Create validator** (if POST/PUT/PATCH) at `server/src/validators/<resource>.validator.ts`
   - Use Zod schema
   - If file exists, add new schema to it

4. **Create controller** at `server/src/controllers/<resource>.controller.ts`
   - If file exists, add new handler function
   - Always use try/catch with `Errors` utility

5. **Register route** in `server/src/routes/app.routes.ts`:
   ```ts
   import <resource>Routes from "./<resource>.routes.js";
   router.use("/<resource>s", <resource>Routes);
   ```

6. **Run** `npx tsc --noEmit` in server/ to verify no type errors

## Route File Template

```ts
import { Router } from "express";
import { authMiddleware } from "../middleware/auth.js";
import { generalLimiter } from "../middleware/rateLimit.js";
import { validate } from "../middleware/validate.js";
import { <schema>Schema } from "../validators/<resource>.validator.js";
import { <handler>Handler } from "../controllers/<resource>.controller.js";

const router = Router();

router.use(authMiddleware, generalLimiter);

router.<method>("<path>", validate(<schema>Schema), <handler>Handler);

export default router;
```

## Service File Template

```ts
import { supabase } from "../config/supabase.js";
import { Errors } from "../utils/errors.js";

export class <Resource>Service {
  async <methodName>(userId: string, ...) {
    const { data, error } = await supabase
      .from("<table>")
      .select("*")
      ...;

    if (error) {
      throw Errors.SERVER_ERROR();
    }

    return data;
  }
}

export const <resource>Service = new <Resource>Service();
```

## Conventions

- All imports use `.js` extension (ESM)
- Service classes are PascalCase, singleton export is camelCase
- Validators use Zod schemas
- Controllers extract `req.user.id` for authenticated routes
- Error handling via `Errors` utility (SERVER_ERROR, NOT_FOUND, BAD_REQUEST, etc.)
- Route registration in `app.routes.ts` with plural resource name
