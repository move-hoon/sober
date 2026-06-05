"use strict";

const { execSync, spawnSync } = require("node:child_process");
const path = require("node:path");
const fs = require("node:fs");
const pkg = require("../package.json");
const { uninstall: unmergeSoberSettings } = require("../.sober/scripts/lib/merge-settings.js");
const { uninstall: unmergeCodexHooks } = require("../.sober/scripts/lib/merge-codex-hooks.js");

// Skills Sober manages (kept in lockstep with install.sh). Used by uninstall to
// remove only Sober's own symlinks, never the user-owned `learned` skill.
const MANAGED_SKILLS = [
  "karpathy",
  "caveman",
  "search-ladder",
  "edit-deterministic",
  "observe",
  "structure-graph",
  "sober-review",
];

const DEPS = [
  {
    key: "claude",
    command: "claude",
    required: false,
    prerequisite: true,
    installKind: "skip",
    description: "Claude Code CLI",
    installHint: "curl -fsSL https://claude.ai/install.sh | bash",
  },
  {
    key: "jq",
    command: "jq",
    required: true,
    installKind: "system",
    systemPackage: "jq",
    description: "JSON processor for CLI workflows",
  },
  {
    key: "mgrep",
    command: "mgrep",
    required: false,
    installKind: "npm",
    npmPackage: "@mixedbread/mgrep",
    postInstall: ["mgrep", "install-claude-code"],
    description: "Semantic search (optional, last-resort per P1)",
  },
  {
    key: "ctx7",
    command: "ctx7",
    required: false,
    installKind: "skip",
    description: "Official Context7 CLI",
  },
];

// Deterministic substrate (P1/P2). Absence is WARN, never FAIL — base operation
// must not depend on these. Contract levels: PASS | WARN | FAIL | BLOCK.
const OPTIONAL_TOOLS = [
  {
    key: "ast-grep",
    commands: ["ast-grep"],
    policy: "P2",
    role: "Structural search & --rewrite edits",
    install: "brew install ast-grep   # or: npm i -g @ast-grep/cli",
  },
  {
    key: "probe",
    commands: ["probe"],
    policy: "P1",
    role: "Structural code search",
    install: "curl -fsSL https://raw.githubusercontent.com/buger/probe/main/install.sh | bash",
  },
  {
    key: "serena",
    commands: ["serena", "serena-mcp-server"],
    policy: "P2",
    role: "Symbol/LSP edits (single MCP)",
    install: "uvx --from git+https://github.com/oraios/serena serena-mcp-server --help",
  },
];

// Optional tools are advisory: present => PASS, absent => WARN. They never
// escalate to FAIL/BLOCK, so they cannot fail the base doctor (P7 posture).
function optionalToolLevel(tool) {
  return tool.installed ? "PASS" : "WARN";
}

function colorize(text, colorCode) {
  if (!process.stdout.isTTY || process.env.NO_COLOR) return text;
  return `\x1b[${colorCode}m${text}\x1b[0m`;
}

function commandExists(cmd) {
  try {
    execSync(`command -v ${cmd}`, { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

function detectSystemInstaller() {
  if (commandExists("brew")) return { ok: true, installer: "brew", sudo: false };
  if (commandExists("apt-get")) return { ok: true, installer: "apt-get", sudo: true };
  if (commandExists("dnf")) return { ok: true, installer: "dnf", sudo: true };
  if (commandExists("pacman")) return { ok: true, installer: "pacman", sudo: true };
  if (commandExists("apk")) return { ok: true, installer: "apk", sudo: true };
  return { ok: false };
}

function buildInstallCmd(installer, pkg, sudo) {
  const prefix = sudo ? "sudo " : "";
  switch (installer) {
    case "brew": return `brew install ${pkg}`;
    case "apt-get": return `${prefix}apt-get install -y ${pkg}`;
    case "dnf": return `${prefix}dnf install -y ${pkg}`;
    case "pacman": return `${prefix}pacman -S --noconfirm ${pkg}`;
    case "apk": return `${prefix}apk add ${pkg}`;
    default: return null;
  }
}

function runCmd(cmd, label) {
  console.log(`  $ ${cmd}`);
  const result = spawnSync("sh", ["-c", cmd], { stdio: "inherit" });
  if (result.status !== 0) {
    console.error(`  FAIL: ${label} (exit ${result.status})`);
    return false;
  }
  return true;
}

function installDep(dep) {
  if (dep.installKind === "skip") return true;

  if (dep.installKind === "npm") {
    if (!commandExists("npm")) {
      console.error(`  npm not found. Install Node.js first, then: npm i -g ${dep.npmPackage}`);
      return false;
    }
    if (!runCmd(`npm install -g ${dep.npmPackage}`, dep.key)) return false;
    if (dep.postInstall) {
      return runCmd(dep.postInstall.join(" "), `${dep.key} post-install`);
    }
    return true;
  }

  if (dep.installKind === "system") {
    const sys = detectSystemInstaller();
    if (!sys.ok) {
      const hint = process.platform === "darwin"
        ? `\n  Install Homebrew first: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
        : "";
      console.error(`  No supported package manager found. Install ${dep.systemPackage} manually.${hint}`);
      return false;
    }
    const cmd = buildInstallCmd(sys.installer, dep.systemPackage, sys.sudo);
    return runCmd(cmd, dep.key);
  }

  return false;
}

function checkDeps() {
  return DEPS.map((dep) => ({
    ...dep,
    installed: commandExists(dep.command),
  }));
}

function printStatus(results) {
  const prereqs = results.filter((r) => r.prerequisite);
  const deps = results.filter((r) => !r.prerequisite);

  if (prereqs.length > 0) {
    console.log("\nPrerequisite:");
    for (const r of prereqs) {
      if (r.installed) {
        console.log(`  ${colorize("✓", "32")} ${r.key.padEnd(8)} ${r.description}`);
      } else {
        console.log(`  ${colorize("⚠", "33")} ${r.key.padEnd(8)} ${r.description} — ${colorize("not found", "33")}`);
        if (r.installHint) {
          console.log(`             Install: ${r.installHint}`);
        }
      }
    }
  }

  console.log("\nDependencies:");
  for (const r of deps) {
    const icon = r.installed
      ? colorize("✓", "32")
      : (r.required ? colorize("✗", "31") : colorize("○", "33"));
    const tag = r.required ? "[required]" : "[optional]";
    console.log(`  ${icon} ${r.key.padEnd(8)} ${tag} ${r.description}`);
  }
  console.log("");
}

function inspectOptionalTools() {
  return OPTIONAL_TOOLS.map((tool) => ({
    ...tool,
    installed: tool.commands.some((c) => commandExists(c)),
  }));
}

function printOptionalToolsStatus(tools) {
  console.log("Deterministic substrate (optional):");
  let warnings = 0;
  for (const tool of tools) {
    const level = optionalToolLevel(tool);
    if (level === "PASS") {
      console.log(`  ${colorize("✓", "32")} ${tool.key.padEnd(10)} PASS  [${tool.policy}] ${tool.role}`);
    } else {
      warnings++;
      console.log(`  ${colorize("⚠", "33")} ${tool.key.padEnd(10)} WARN  [${tool.policy}] ${tool.role} — not installed`);
      console.log(`             Install: ${tool.install}`);
    }
  }
  if (warnings > 0) {
    console.log(`             ${warnings} optional tool(s) absent — base operation unaffected; add only when measured (P7).`);
  }
  console.log("");
  // Optional-tool absence is WARN, never FAIL: base doctor must not fail on it.
  return { warnings, failed: false };
}

function inspectContext7Status(homeDir) {
  const skillPath = path.join(homeDir, ".claude", "skills", "find-docs", "SKILL.md");
  const rulePath = path.join(homeDir, ".claude", "rules", "context7.md");
  const binaryInstalled = commandExists("ctx7");

  let version = null;
  if (binaryInstalled) {
    try {
      version = execSync("ctx7 --version", { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] })
        .trim()
        .split("\n")[0];
    } catch {
      version = null;
    }
  }

  return {
    binaryInstalled,
    version,
    skillInstalled: fs.existsSync(skillPath),
    ruleInstalled: fs.existsSync(rulePath),
  };
}

function printContext7DoctorStatus(status) {
  console.log("\nContext7 Integration:");
  console.log(
    `  ${status.binaryInstalled ? colorize("✓", "32") : colorize("○", "33")} ctx7 binary       ${
      status.binaryInstalled ? (status.version || "installed") : "not installed (optional)"
    }`,
  );
  console.log(
    `  ${status.skillInstalled ? colorize("✓", "32") : colorize("○", "33")} Context7 skill     ${
      status.skillInstalled ? "find-docs installed" : "not installed"
    }`,
  );
  console.log(
    `  ${status.ruleInstalled ? colorize("✓", "32") : colorize("○", "33")} Context7 rule      ${
      status.ruleInstalled ? "context7.md installed" : "not installed"
    }`,
  );

  const fullyInstalled = status.binaryInstalled && status.skillInstalled && status.ruleInstalled;
  const partiallyInstalled =
    status.binaryInstalled || status.skillInstalled || status.ruleInstalled;

  if (fullyInstalled) {
    console.log("             Context7 CLI and Claude integration are fully installed.");
    console.log("");
    return { failed: false };
  }

  if (partiallyInstalled) {
    console.log("             Context7 is partially installed (optional — not a failure).");
    console.log("             Complete it: run sober setup and opt into Context7, or run:");
    console.log("                  npm install -g ctx7");
    console.log("                  ctx7 setup --cli --claude");
    console.log("");
    // Context7 is optional; a partial state is advisory and must not fail doctor (P-spine).
    return { failed: false };
  }

  console.log("             Optional. To install:");
  console.log("                  npm install -g ctx7");
  console.log("                  ctx7 setup --cli --claude");
  console.log("");
  return { failed: false };
}

function runSetup() {
  console.log(`Sober v${pkg.version} - Setup`);

  const results = checkDeps();
  const missing = results.filter((r) => r.required && !r.installed);

  if (missing.length > 0) {
    console.log(`\nInstalling ${missing.length} missing dependency(ies)...\n`);

    for (const dep of missing) {
      console.log(`[${dep.key}] ${dep.description}`);
      if (!installDep(dep)) {
        // continue to install others
      } else {
        console.log(`  Done.\n`);
      }
    }

    const after = checkDeps();
    printStatus(after);

    const stillMissing = after.filter((r) => r.required && !r.installed);
    if (stillMissing.length > 0) {
      console.error(`${stillMissing.length} required dep(s) still missing.`);
      return 1;
    }
  } else {
    console.log("\nAll dependencies installed.");
    printStatus(results);
  }

  // Run install.sh with the optional-tool offers (Context7 / deterministic toolkit).
  if (!runInstallScript(true)) {
    return 1;
  }

  console.log("Setup complete.");
  return 0;
}

// `sober install`: apply the policy files only — no dependency install and no
// optional-tool prompts. Tool setup is the separate responsibility of `sober setup`.
function runInstall() {
  console.log(`Sober v${pkg.version} - Install`);
  if (!runInstallScript(false)) {
    return 1;
  }
  console.log("Install complete. Run 'sober setup' to add deps + optional tools.");
  return 0;
}

function runInstallScript(withOffers) {
  const scriptPath = path.resolve(__dirname, "..", "install.sh");
  if (!fs.existsSync(scriptPath)) {
    return true;
  }
  console.log("Configuring Sober...\n");
  const result = spawnSync("bash", [scriptPath], {
    stdio: "inherit",
    env: {
      ...process.env,
      SOBER_SETUP_WRAPPER: "1",
      SOBER_WITH_OFFERS: withOffers ? "1" : "0",
    },
  });
  if (result.status !== 0) {
    console.error("Config setup had issues. Run 'bash install.sh' manually if needed.");
    return false;
  }
  return true;
}

// Verify the hooks referenced in the installed ~/.claude/settings.json actually
// exist on disk — catches the "settings points at a hook that was never
// installed" gap (e.g. a Stop hook erroring at runtime while doctor said OK).
function hookCommandToManagedRef(command, homeDir) {
  // Hooks may live under ~/.claude (legacy/user) or ~/.sober (Sober's own home).
  // Scan all tokens, not just the first, so wrapper forms like
  // `bash ~/.sober/scripts/hooks/x.sh` are validated too.
  for (const token of command.trim().split(/\s+/)) {
    const expanded = token
      .replace(/^~(?=\/)/, homeDir)
      .replace(/^\$HOME(?=\/)/, homeDir);
    for (const root of [".claude", ".sober"]) {
      const rootPath = path.join(homeDir, root) + path.sep;
      if (expanded.startsWith(rootPath)) {
        return {
          command,
          absolute: expanded,
          relative: path.relative(path.join(homeDir, root), expanded),
        };
      }
    }
  }
  return null;
}

function inspectInstalledHooks(homeDir) {
  const settingsPath = path.join(homeDir, ".claude", "settings.json");
  if (!fs.existsSync(settingsPath)) return { checked: false };
  let settings;
  try {
    settings = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
  } catch {
    return { checked: true, invalid: true };
  }
  const refs = new Map();
  const walk = (node) => {
    if (!node || typeof node !== "object") return;
    if (Array.isArray(node)) return node.forEach(walk);
    for (const [k, v] of Object.entries(node)) {
      if (k === "command" && typeof v === "string") {
        const ref = hookCommandToManagedRef(v, homeDir);
        if (ref) refs.set(ref.absolute, ref);
      } else {
        walk(v);
      }
    }
  };
  walk(settings.hooks || {});
  const allRefs = [...refs.values()];
  const missing = allRefs.filter((r) => !fs.existsSync(r.absolute)).map((r) => r.relative);
  const unexpected = allRefs
    .filter((r) => !r.relative.startsWith(`scripts${path.sep}hooks${path.sep}`))
    .map((r) => r.relative);
  return { checked: true, refs: allRefs.map((r) => r.relative), missing, unexpected };
}

function printInstalledHooksStatus(status) {
  console.log("Installed hooks (~/.claude):");
  if (!status.checked) {
    console.log(`  ${colorize("○", "33")} ~/.claude/settings.json not found — run sober setup`);
    console.log("");
    return { failed: false };
  }
  if (status.invalid) {
    console.log(`  ${colorize("✗", "31")} ~/.claude/settings.json invalid JSON — re-run sober setup`);
    console.log("");
    return { failed: true };
  }
  if (status.missing.length === 0 && status.unexpected.length === 0) {
    console.log(`  ${colorize("✓", "32")} all ${status.refs.length} referenced hook(s) present on disk`);
    console.log("");
    return { failed: false };
  }
  if (status.missing.length > 0) {
    console.log(`  ${colorize("✗", "31")} ${status.missing.length} referenced hook(s) missing: ${status.missing.join(", ")}`);
    console.log("             settings.json points at hooks not on disk — they error at runtime.");
  }
  if (status.unexpected.length > 0) {
    console.log(`  ${colorize("✗", "31")} stale or unmanaged hook path(s): ${status.unexpected.join(", ")}`);
    console.log("             Sober v2 hooks should live under ~/.sober/scripts/hooks/ or ~/.sober/scripts/codex-hooks/.");
  }
  console.log("             Fix: run sober setup (installs/refreshes ~/.claude and overwrites stale settings).");
  console.log("");
  return { failed: true };
}


function inspectCodexHooks(homeDir) {
  const hooksPath = path.join(homeDir, ".codex", "hooks.json");
  if (!fs.existsSync(hooksPath)) return { checked: false };
  let config;
  try {
    config = JSON.parse(fs.readFileSync(hooksPath, "utf8"));
  } catch {
    return { checked: true, invalid: true };
  }
  const refs = new Map();
  const walk = (node) => {
    if (!node || typeof node !== "object") return;
    if (Array.isArray(node)) return node.forEach(walk);
    for (const [k, v] of Object.entries(node)) {
      if (k === "command" && typeof v === "string") {
        const ref = hookCommandToManagedRef(v, homeDir);
        if (ref && v.includes("/.sober/scripts/")) refs.set(ref.absolute, ref);
      } else {
        walk(v);
      }
    }
  };
  walk(config.hooks || {});
  const allRefs = [...refs.values()];
  const missing = allRefs.filter((r) => !fs.existsSync(r.absolute)).map((r) => r.relative);
  const expected = [
    path.join("scripts", "hooks", "critical-action-check.sh"),
    path.join("scripts", "hooks", "verify-gate.sh"),
    path.join("scripts", "hooks", "post-edit-format.sh"),
    path.join("scripts", "hooks", "compact-suggest.sh"),
    path.join("scripts", "hooks", "session-start.sh"),
    path.join("scripts", "hooks", "handoff-write.sh"),
    path.join("scripts", "codex-hooks", "tool-failure-log.sh"),
  ];
  const present = new Set(allRefs.map((r) => r.relative));
  const absentExpected = expected.filter((r) => !present.has(r));
  return { checked: true, refs: allRefs.map((r) => r.relative), missing, absentExpected };
}

function printCodexHooksStatus(status) {
  console.log("Installed hooks (~/.codex/hooks.json):");
  if (!status.checked) {
    console.log(`  ${colorize("○", "33")} not found — run sober setup to enable Codex lifecycle hooks`);
    console.log("");
    return { failed: true };
  }
  if (status.invalid) {
    console.log(`  ${colorize("✗", "31")} invalid JSON — re-run sober setup`);
    console.log("");
    return { failed: true };
  }
  if (status.missing.length === 0 && status.absentExpected.length === 0) {
    console.log(`  ${colorize("✓", "32")} all ${status.refs.length} Sober hook reference(s) present on disk`);
    console.log("");
    return { failed: false };
  }
  if (status.absentExpected.length > 0) {
    console.log(`  ${colorize("✗", "31")} missing Sober hook reference(s): ${status.absentExpected.join(", ")}`);
  }
  if (status.missing.length > 0) {
    console.log(`  ${colorize("✗", "31")} referenced hook(s) missing on disk: ${status.missing.join(", ")}`);
  }
  console.log("             Fix: run sober setup to refresh ~/.codex/hooks.json and ~/.sober/scripts.");
  console.log("");
  return { failed: true };
}

function inspectCodexRules(homeDir) {
  const rulePath = path.join(homeDir, ".codex", "rules", "sober-critical-actions.rules");
  if (!fs.existsSync(rulePath) && !isSymlink(rulePath)) return { checked: true, missing: true };
  const soberHome = path.join(homeDir, ".sober");
  const symlink = isSymlink(rulePath);
  const badLink = symlink && !isSoberSymlink(rulePath, soberHome);
  let targetMissing = false;
  if (symlink) {
    const target = fs.readlinkSync(rulePath);
    const absoluteTarget = path.isAbsolute(target) ? target : path.resolve(path.dirname(rulePath), target);
    targetMissing = !fs.existsSync(absoluteTarget);
  }
  return { checked: true, missing: false, badLink, targetMissing };
}

function printCodexRulesStatus(status) {
  console.log("Installed rules (~/.codex/rules):");
  if (status.missing) {
    console.log(`  ${colorize("✗", "31")} sober-critical-actions.rules not installed`);
    console.log("             Fix: run sober setup to enable Codex exec-policy safety rules.");
    console.log("");
    return { failed: true };
  }
  if (status.badLink || status.targetMissing) {
    console.log(`  ${colorize("✗", "31")} sober-critical-actions.rules is not a valid Sober rule link`);
    console.log("             Fix: run sober setup.");
    console.log("");
    return { failed: true };
  }
  console.log(`  ${colorize("✓", "32")} sober-critical-actions.rules installed`);
  console.log("");
  return { failed: false };
}

function runDoctor() {
  console.log(`Sober v${pkg.version} - Doctor`);

  const homeDir = process.env.HOME || process.env.USERPROFILE || "";
  const results = checkDeps();
  printStatus(results);
  const optionalTools = inspectOptionalTools();
  printOptionalToolsStatus(optionalTools);
  const hooksDoctor = printInstalledHooksStatus(inspectInstalledHooks(homeDir));
  const codexHooksDoctor = printCodexHooksStatus(inspectCodexHooks(homeDir));
  const codexRulesDoctor = printCodexRulesStatus(inspectCodexRules(homeDir));
  const context7Status = inspectContext7Status(homeDir);
  const context7Doctor = printContext7DoctorStatus(context7Status);

  const missing = results.filter((r) => r.required && !r.installed);
  if (missing.length > 0 || context7Doctor.failed || hooksDoctor.failed || codexHooksDoctor.failed || codexRulesDoctor.failed) {
    console.log(`Fix: sober setup`);
    return 1;
  }

  console.log(colorize("All required checks passed.", "32"));
  return 0;
}

function renderTemplate(text, vars) {
  return text.replace(/\{\{(\w+)\}\}/g, (m, k) => (k in vars ? vars[k] : m));
}

function runTemplate(args) {
  const templateDir = path.resolve(__dirname, "..", "project-template");
  const spinePath = path.resolve(__dirname, "..", "AGENTS.md");
  const targetDir = path.resolve(args.find((a) => !a.startsWith("-")) || ".");
  const withSgconfig = args.includes("--with-sgconfig");
  const force = args.includes("--force");

  if (!fs.existsSync(spinePath) || !fs.existsSync(templateDir)) {
    console.error("Sober templates not found in this package.");
    return 1;
  }

  fs.mkdirSync(targetDir, { recursive: true });
  const vars = {
    PROJECT: path.basename(targetDir) || "project",
    SPINE: fs.readFileSync(spinePath, "utf8").trim(),
  };

  const outputs = [
    ["AGENTS.md.tmpl", "AGENTS.md"],
    ["HANDOFF.md.tmpl", "HANDOFF.md"],
  ];
  if (withSgconfig) outputs.push(["sgconfig.yml.tmpl", "sgconfig.yml"]);

  let written = 0;
  for (const [src, dest] of outputs) {
    const srcPath = path.join(templateDir, src);
    const destPath = path.join(targetDir, dest);
    if (!fs.existsSync(srcPath)) continue;
    if (fs.existsSync(destPath) && !force) {
      console.log(`  skip (exists): ${dest}`);
      continue;
    }
    fs.writeFileSync(destPath, renderTemplate(fs.readFileSync(srcPath, "utf8"), vars));
    console.log(`  wrote: ${dest}`);
    written++;
  }

  // CLAUDE.md is a symlink to the single-source spine (AGENTS.md), not a copy.
  const claudeLink = path.join(targetDir, "CLAUDE.md");
  if (fs.existsSync(claudeLink) || isSymlink(claudeLink)) {
    if (force) fs.rmSync(claudeLink, { force: true });
  }
  if (!fs.existsSync(claudeLink) && !isSymlink(claudeLink)) {
    fs.symlinkSync("AGENTS.md", claudeLink);
    console.log("  linked: CLAUDE.md → AGENTS.md");
    written++;
  } else {
    console.log("  skip (exists): CLAUDE.md");
  }

  console.log(`Sober template: ${written} file(s) into ${targetDir}`);
  return 0;
}

function isSymlink(p) {
  try {
    return fs.lstatSync(p).isSymbolicLink();
  } catch {
    return false;
  }
}

// True only when p is a symlink whose target lives under ~/.sober — i.e. one
// Sober created. User-owned symlinks (pointing elsewhere) are never touched.
function isSoberSymlink(p, soberHome) {
  if (!isSymlink(p)) return false;
  try {
    return fs.readlinkSync(p).startsWith(soberHome + path.sep) || fs.readlinkSync(p) === soberHome;
  } catch {
    return false;
  }
}

// Remove the Sober managed block from a real file. Returns true if it changed.
// If the file is left empty, it is removed.
function stripSoberBlock(filePath) {
  let text;
  try {
    text = fs.readFileSync(filePath, "utf8");
  } catch {
    return false;
  }
  const stripped = text.replace(/<!-- SOBER:START -->[\s\S]*?<!-- SOBER:END -->\n?/g, "");
  if (stripped === text) return false;
  if (stripped.trim() === "") {
    fs.rmSync(filePath, { force: true });
  } else {
    fs.writeFileSync(filePath, stripped);
  }
  return true;
}

// Reverse `sober install` additively: drop only Sober-owned symlinks, strip the
// Sober block from real spine files, remove Sober's hooks from settings.json, and
// delete the single home (~/.sober). Everything the user owns is left in place.
function runUninstall() {
  const home = process.env.HOME || process.env.USERPROFILE || "";
  if (!home) {
    console.error("Cannot resolve home directory.");
    return 1;
  }
  const soberHome = path.join(home, ".sober");
  let removed = 0;
  const drop = (p) => {
    if (isSoberSymlink(p, soberHome)) {
      fs.rmSync(p, { force: true });
      removed++;
    }
  };

  for (const skill of MANAGED_SKILLS) {
    drop(path.join(home, ".claude", "skills", skill));
    drop(path.join(home, ".agents", "skills", skill));
  }

  // Spine entrypoints: unlink a Sober symlink, else strip the Sober block.
  for (const sp of [
    path.join(home, ".claude", "CLAUDE.md"),
    path.join(home, ".claude", "AGENTS.md"),
    path.join(home, ".codex", "AGENTS.md"),
  ]) {
    if (isSoberSymlink(sp, soberHome)) {
      fs.rmSync(sp, { force: true });
      removed++;
    } else if (fs.existsSync(sp) && !isSymlink(sp)) {
      if (stripSoberBlock(sp)) removed++;
    }
  }

  // Per-file Sober symlinks in commands/rules, and stale whole-dir symlinks.
  for (const name of ["commands", "rules"]) {
    const dir = path.join(home, ".claude", name);
    if (fs.existsSync(dir) && !isSymlink(dir)) {
      for (const f of fs.readdirSync(dir)) drop(path.join(dir, f));
    }
  }
  for (const d of ["scripts", "commands", "agents"]) drop(path.join(home, ".claude", d));

  // settings.json / hooks.json: remove only Sober's hooks (preserve user config).
  const settingsPath = path.join(home, ".claude", "settings.json");
  if (fs.existsSync(settingsPath)) {
    try {
      const cleaned = unmergeSoberSettings(JSON.parse(fs.readFileSync(settingsPath, "utf8")));
      fs.writeFileSync(settingsPath, `${JSON.stringify(cleaned, null, 2)}
`);
    } catch {
      /* leave a malformed settings.json untouched */
    }
  }
  const codexHooksPath = path.join(home, ".codex", "hooks.json");
  if (fs.existsSync(codexHooksPath)) {
    try {
      const cleaned = unmergeCodexHooks(JSON.parse(fs.readFileSync(codexHooksPath, "utf8")));
      fs.writeFileSync(codexHooksPath, `${JSON.stringify(cleaned, null, 2)}
`);
    } catch {
      /* leave a malformed hooks.json untouched */
    }
  }
  drop(path.join(home, ".codex", "rules", "sober-critical-actions.rules"));

  if (fs.existsSync(soberHome)) {
    fs.rmSync(soberHome, { recursive: true, force: true });
    console.log(`  removed ${soberHome}`);
  }
  console.log(`Sober uninstalled — ${removed} item(s) removed; Sober hooks stripped from Claude settings and Codex hooks.`);
  console.log("Left in place (yours): settings.json, settings.local.json, rules/language.md, ~/.claude.json, skills/learned");
  return 0;
}

function printHelp() {
  console.log(`Sober v${pkg.version}

Usage:
  sober install          Apply Sober's policy files to ~/.sober and link the runtimes (config only)
  sober setup            install + dependencies + optional tools (Context7, deterministic toolkit)
  sober doctor           Check dependency, deterministic-substrate, and Context7 status
  sober uninstall        Remove Sober's runtime symlinks and ~/.sober
  sober template [dir]   Generate project AGENTS.md/CLAUDE.md/HANDOFF.md (--with-sgconfig, --force)
  sober --help           Show this help
  sober --version        Show version
`);
}

function runCli(argv) {
  const cmd = argv[0] || "setup";

  if (cmd === "--help" || cmd === "-h" || cmd === "help") {
    printHelp();
    return 0;
  }

  if (cmd === "--version" || cmd === "-v" || cmd === "version") {
    console.log(pkg.version);
    return 0;
  }

  if (process.platform === "win32") {
    console.error("Sober requires macOS/Linux. Windows users: use WSL.");
    return 1;
  }

  switch (cmd) {
    case "install":
      return runInstall();
    case "setup":
      return runSetup();
    case "doctor":
      return runDoctor();
    case "uninstall":
      return runUninstall();
    case "template":
      return runTemplate(argv.slice(1));
    default:
      console.error(`Unknown command: ${cmd}\nRun 'sober --help' for usage.`);
      return 2;
  }
}

module.exports = {
  runCli,
  runUninstall,
  MANAGED_SKILLS,
  DEPS,
  OPTIONAL_TOOLS,
  inspectOptionalTools,
  optionalToolLevel,
  printOptionalToolsStatus,
  inspectInstalledHooks,
};
