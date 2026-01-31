/**
 * Rules single source of truth enforcement (rules-src -> generated outputs).
 *
 * This is intentionally lightweight and cross-platform: no pwsh requirement.
 * If rules-src doesn't exist at the repo root, the check is skipped.
 */

import { existsSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { execSync } from "node:child_process";

export interface RulesCheckResult {
  enabled: boolean;
  ok: boolean;
  errors: string[];
}

function tryGitRoot(cwd: string): string | null {
  try {
    const out = execSync("git rev-parse --show-toplevel", {
      cwd,
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"]
    }).trim();
    return out.length ? out : null;
  } catch {
    return null;
  }
}

function findRepoRoot(startCwd: string): string {
  // Prefer git root if available.
  const gitRoot = tryGitRoot(startCwd);
  if (gitRoot) return gitRoot;

  // Fallback: walk up until we find rules-src or stop at filesystem root.
  let cur = resolve(startCwd);
  while (true) {
    if (existsSync(join(cur, "rules-src", "rules"))) return cur;
    const parent = resolve(cur, "..");
    if (parent === cur) return startCwd;
    cur = parent;
  }
}

function normalizeEol(s: string): string {
  return s.replace(/\r\n/g, "\n").replace(/\r/g, "\n");
}

function readUtf8(path: string): string {
  return normalizeEol(readFileSync(path, "utf-8"));
}

function isJsonWrappedRule(content: string): boolean {
  return content.trimStart().startsWith("{");
}

// Mirrors scripts/gen-rules.ps1 mapping.
const rootMdcRules = [
  "agent-protocol",
  "commands",
  "diagnostics",
  "issue-reporting-and-apply-report",
  "knowledge-base",
  "verification",
  "windows-systems-and-toolchain"
] as const;

const setupCursorRuleDirs = [
  "diagnostics",
  "issue-reporting-and-apply-report",
  "python-3-14",
  "windows-systems-and-toolchain"
] as const;

const precursorMdcRules = [
  "diagnostics",
  "issue-reporting-and-apply-report",
  "python-3-14",
  "python",
  "web",
  "windows-systems-and-toolchain"
] as const;

const precursorRuleDirs = [
  "diagnostics",
  "issue-reporting-and-apply-report",
  "python-3-14",
  "windows-systems-and-toolchain"
] as const;

export function checkRulesUpToDate(cwd: string = process.cwd()): RulesCheckResult {
  const repoRoot = findRepoRoot(cwd);
  const srcRulesDir = join(repoRoot, "rules-src", "rules");
  const srcIncidents = join(repoRoot, "rules-src", "INCIDENTS.md");

  // If this repo doesn't use rules-src, do nothing.
  if (!existsSync(srcRulesDir) || !existsSync(srcIncidents)) {
    return { enabled: false, ok: true, errors: [] };
  }

  const errors: string[] = [];

  // Helper: compare src->dst.
  const compare = (id: string, src: string, dst: string) => {
    if (!existsSync(src)) {
      errors.push(`[rules-src missing] ${id}: ${src}`);
      return;
    }
    if (!existsSync(dst)) {
      errors.push(`[generated missing] ${id}: ${dst}`);
      return;
    }

    const s = readUtf8(src);
    const d = readUtf8(dst);

    if (dst.endsWith(".mdc") && isJsonWrappedRule(d)) {
      errors.push(`[corrupt .mdc] ${id}: ${dst} looks JSON-wrapped (starts with '{')`);
      return;
    }

    if (s !== d) {
      errors.push(`[drift] ${id}: ${dst} differs from ${src}`);
    }
  };

  for (const id of rootMdcRules) {
    compare(
      `root:${id}`,
      join(srcRulesDir, `${id}.md`),
      join(repoRoot, ".cursor", "rules", `${id}.mdc`)
    );
  }

  compare(
    "root:INCIDENTS",
    srcIncidents,
    join(repoRoot, ".cursor", "rules", "INCIDENTS.md")
  );

  for (const id of setupCursorRuleDirs) {
    compare(
      `setup-cursor:${id}`,
      join(srcRulesDir, `${id}.md`),
      join(repoRoot, "packages", "setup-cursor", ".cursor", "rules", id, "RULE.md")
    );
  }

  compare(
    "setup-cursor:INCIDENTS",
    srcIncidents,
    join(repoRoot, "packages", "setup-cursor", ".cursor", "rules", "INCIDENTS.md")
  );

  for (const id of precursorMdcRules) {
    compare(
      `precursor:${id}`,
      join(srcRulesDir, `${id}.md`),
      join(repoRoot, "packages", "precursor", ".cursor", "rules", `${id}.mdc`)
    );
  }

  for (const id of precursorRuleDirs) {
    compare(
      `precursor-dir:${id}`,
      join(srcRulesDir, `${id}.md`),
      join(repoRoot, "packages", "precursor", ".cursor", "rules", id, "RULE.md")
    );
  }

  return { enabled: true, ok: errors.length === 0, errors };
}
