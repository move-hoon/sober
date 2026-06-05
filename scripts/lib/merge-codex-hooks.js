"use strict";

const fs = require("node:fs");

function isSoberHook(handler) {
  return Boolean(handler && typeof handler.command === "string" && handler.command.includes(".sober/scripts/"));
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function stripSoberHooks(config) {
  const out = clone(config || {});
  if (!out.hooks || typeof out.hooks !== "object") return out;
  for (const [event, groups] of Object.entries(out.hooks)) {
    if (!Array.isArray(groups)) continue;
    out.hooks[event] = groups
      .map((group) => {
        if (!group || typeof group !== "object") return group;
        const next = { ...group };
        next.hooks = Array.isArray(group.hooks) ? group.hooks.filter((h) => !isSoberHook(h)) : group.hooks;
        return next;
      })
      .filter((group) => !Array.isArray(group.hooks) || group.hooks.length > 0);
    if (out.hooks[event].length === 0) delete out.hooks[event];
  }
  if (Object.keys(out.hooks).length === 0) delete out.hooks;
  return out;
}

function mergeCodexHooks(existing, sober) {
  const out = stripSoberHooks(existing || {});
  const src = sober && sober.hooks && typeof sober.hooks === "object" ? sober.hooks : {};
  if (!out.hooks || typeof out.hooks !== "object") out.hooks = {};
  for (const [event, groups] of Object.entries(src)) {
    if (!Array.isArray(groups)) continue;
    if (!Array.isArray(out.hooks[event])) out.hooks[event] = [];
    out.hooks[event].push(...clone(groups));
  }
  return out;
}

function readJson(path, fallback = {}) {
  if (!fs.existsSync(path)) return fallback;
  return JSON.parse(fs.readFileSync(path, "utf8"));
}

function install(targetPath, sourcePath) {
  const existing = readJson(targetPath, {});
  const source = readJson(sourcePath, {});
  return mergeCodexHooks(existing, source);
}

function uninstall(existing) {
  return stripSoberHooks(existing || {});
}

if (require.main === module) {
  const [mode, targetPath, sourcePath] = process.argv.slice(2);
  if (!mode || !targetPath || (mode === "install" && !sourcePath)) {
    console.error("usage: merge-codex-hooks.js install <target> <source> | uninstall <target>");
    process.exit(2);
  }
  const current = readJson(targetPath, {});
  const next = mode === "install" ? install(targetPath, sourcePath) : uninstall(current);
  fs.mkdirSync(require("node:path").dirname(targetPath), { recursive: true });
  fs.writeFileSync(targetPath, `${JSON.stringify(next, null, 2)}\n`);
}

module.exports = { mergeCodexHooks, stripSoberHooks, install, uninstall };
