import { Router, type IRouter } from "express";
import { existsSync, readFileSync, statSync } from "node:fs";
import path from "node:path";

const router: IRouter = Router();

function resolveVerifyPath(): string {
  const candidates = [
    path.resolve(process.cwd(), "lean-proof", "VERIFY.txt"),
    path.resolve(process.cwd(), "..", "..", "lean-proof", "VERIFY.txt"),
    path.resolve(process.cwd(), "..", "lean-proof", "VERIFY.txt"),
  ];
  for (const c of candidates) {
    if (existsSync(c)) return c;
  }
  return candidates[0];
}

const VERIFY_PATH = resolveVerifyPath();

interface ParsedVerification {
  toolchain: string;
  dateVerified: string;
  axiomDebt: string[];
  axiomLines: string[];
  content: string;
  lastModified: string;
}

function parseVerification(content: string, lastModified: string): ParsedVerification {
  const toolchainMatch = content.match(/Lean toolchain\s*:\s*(.+)/);
  const dateMatch = content.match(/Date verified\s*:\s*(.+)/);
  const axiomLines = content
    .split("\n")
    .filter((l) => /does not depend on any axioms/.test(l))
    .map((l) => l.trim());
  // Any line of the form "axiom Foo : ..." would indicate remaining debt.
  // The verification log only emits axiom declarations as remaining debt; the
  // "does not depend on any axioms" lines mean debt = [].
  const debtMatch = content.match(/Axiom debt\s*=\s*\[([^\]]*)\]/);
  const axiomDebt = debtMatch && debtMatch[1].trim().length > 0
    ? debtMatch[1].split(",").map((s) => s.trim()).filter(Boolean)
    : [];

  return {
    toolchain: toolchainMatch ? toolchainMatch[1].trim() : "unknown",
    dateVerified: dateMatch ? dateMatch[1].trim() : "unknown",
    axiomDebt,
    axiomLines,
    content,
    lastModified,
  };
}

let cached: ParsedVerification | null = null;
let cachedError: string | null = null;

function load(): ParsedVerification | null {
  if (cached) return cached;
  if (cachedError) return null;
  try {
    const content = readFileSync(VERIFY_PATH, "utf8");
    const stat = statSync(VERIFY_PATH);
    cached = parseVerification(content, stat.mtime.toISOString());
    return cached;
  } catch (err) {
    cachedError = err instanceof Error ? err.message : String(err);
    return null;
  }
}

router.get("/lean/verify", (req, res) => {
  const parsed = load();
  if (!parsed) {
    req.log.error({ path: VERIFY_PATH, err: cachedError }, "Failed to read VERIFY.txt");
    res.status(500).json({ error: "Verification log unavailable" });
    return;
  }
  const ageMs = Date.now() - new Date(parsed.lastModified).getTime();
  const ageDays = ageMs / (1000 * 60 * 60 * 24);
  res.json({ ...parsed, ageDays });
});

export default router;
