#!/usr/bin/env node
"use strict";

// Additive, non-destructive settings.json fusion.
//
// Claude Code merges array fields (hooks, permissions.*) across settings scopes,
// but at the global/user scope there is only one file (~/.claude/settings.json).
// So instead of overwriting it, Sober *merges* its own hooks (and a few safe
// permission/env defaults) into whatever the user already has, and on uninstall
// removes only its own hooks. Sober hooks are identified by their command path
// pointing into ~/.sober/scripts/hooks/.

const fs = require("node:fs");

const SOBER_HOOK_RE = /[/.]sober\/scripts\/hooks\//;

function readJson(p, fallback) {
  try {
    return JSON.parse(fs.readFileSync(p, "utf8"));
  } catch {
    return fallback;
  }
}

function groupHasSoberCommand(group) {
  return (
    group &&
    Array.isArray(group.hooks) &&
    group.hooks.some((h) => h && typeof h.command === "string" && SOBER_HOOK_RE.test(h.command))
  );
}

function sameGroup(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

function mergeHooks(userHooks, soberHooks) {
  const out = { ...(userHooks || {}) };
  for (const [event, groups] of Object.entries(soberHooks || {})) {
    const existing = Array.isArray(out[event]) ? out[event].slice() : [];
    for (const g of groups) {
      if (!existing.some((e) => sameGroup(e, g))) existing.push(g);
    }
    out[event] = existing;
  }
  return out;
}

function mergeStringArray(userArr, soberArr) {
  const out = Array.isArray(userArr) ? userArr.slice() : [];
  for (const s of soberArr || []) if (!out.includes(s)) out.push(s);
  return out;
}

// Merge Sober's settings into the user's, never removing anything the user set.
function mergeInstall(user, sober) {
  const out = { ...user };
  if (sober.hooks) out.hooks = mergeHooks(user.hooks, sober.hooks);
  if (sober.permissions) {
    out.permissions = { ...(user.permissions || {}) };
    for (const k of ["allow", "ask", "deny"]) {
      if (sober.permissions[k]) {
        out.permissions[k] = mergeStringArray(user.permissions && user.permissions[k], sober.permissions[k]);
      }
    }
  }
  if (sober.env) {
    // Add Sober's env keys, but the user's value always wins on a conflict.
    out.env = { ...sober.env, ...(user.env || {}) };
  }
  if (sober.$schema && !user.$schema) out.$schema = sober.$schema;
  return out;
}

// Remove only Sober's own hooks (by ~/.sober/scripts/hooks/ command path). Leave
// permission/env additions in place — they are additive grants, and removing them
// could clobber identical entries the user added themselves.
function uninstall(user) {
  const out = { ...user };
  if (user.hooks) {
    const hooks = {};
    for (const [event, groups] of Object.entries(user.hooks)) {
      const kept = (groups || [])
        .map((g) => {
          if (!g || !Array.isArray(g.hooks)) return g;
          const innerKept = g.hooks.filter(
            (h) => !(h && typeof h.command === "string" && SOBER_HOOK_RE.test(h.command)),
          );
          return innerKept.length ? { ...g, hooks: innerKept } : null;
        })
        .filter((g) => g && !groupHasSoberCommand(g));
      if (kept.length) hooks[event] = kept;
    }
    if (Object.keys(hooks).length) out.hooks = hooks;
    else delete out.hooks;
  }
  return out;
}

function main() {
  const [mode, userPath, soberPath] = process.argv.slice(2);
  if (!mode || !userPath) {
    console.error("usage: merge-settings.js <install|uninstall> <userSettings.json> [soberSettings.json]");
    process.exit(2);
  }
  const user = readJson(userPath, {});
  let result;
  if (mode === "install") {
    result = mergeInstall(user, readJson(soberPath, {}));
  } else if (mode === "uninstall") {
    result = uninstall(user);
  } else {
    console.error(`unknown mode: ${mode}`);
    process.exit(2);
  }
  fs.writeFileSync(userPath, `${JSON.stringify(result, null, 2)}\n`);
}

if (require.main === module) main();

module.exports = { mergeInstall, uninstall, mergeHooks, SOBER_HOOK_RE };
