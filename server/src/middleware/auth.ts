import type { Request, Response, NextFunction } from "express";
import { verifyAccessToken } from "../utils/jwt.js";
import type { JwtPayload } from "../types/index.js";
import { Errors } from "../utils/errors.js";
import { supabase } from "../config/supabase.js";

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

// Throttle last_seen_at updates: max once per 2 minutes per user
const lastSeenCache = new Map<string, number>();
const LAST_SEEN_THROTTLE_MS = 2 * 60 * 1000;
// Prevent unbounded growth — clear cache every 10 minutes
setInterval(() => lastSeenCache.clear(), 10 * 60 * 1000).unref();

function touchLastSeen(userId: string): void {
  const now = Date.now();
  const last = lastSeenCache.get(userId) ?? 0;
  if (now - last < LAST_SEEN_THROTTLE_MS) return;

  lastSeenCache.set(userId, now);
  // Fire-and-forget — don't block the request
  supabase
    .from("users")
    .update({ last_seen_at: new Date().toISOString() })
    .eq("id", userId)
    .then();
}

export function authMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction,
): void {
  const header = req.headers.authorization;

  if (!header?.startsWith("Bearer ")) {
    throw Errors.INVALID_TOKEN();
  }

  const token = header.slice(7);

  try {
    req.user = verifyAccessToken(token);
    touchLastSeen(req.user.userId);
    next();
  } catch {
    throw Errors.TOKEN_EXPIRED();
  }
}
