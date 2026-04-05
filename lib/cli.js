"use strict";

const { execSync, spawnSync } = require("node:child_process");
const path = require("node:path");
const fs = require("node:fs");
const pkg = require("../package.json");
const {
  RTK_DOCS_URL,
  attemptRtkInstall,
  getRtkManualInstallHints,
  inspectRtkStatus,
  reconcileManagedRtkHook,
} = require("./rtk");

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
    required: true,
    installKind: "npm",
    npmPackage: "@mixedbread/mgrep",
    postInstall: ["mgrep", "install-claude-code"],
    description: "Fast code search tool",
  },
  {
    key: "tmux",
    command: "tmux",
    required: true,
    installKind: "system",
    systemPackage: "tmux",
    description: "Terminal multiplexer for background agents",
  },
  {
    key: "ctx7",
    command: "ctx7",
    required: false,
    installKind: "skip",
    description: "Official Context7 CLI",
  },
];

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
    console.log("             Context7 is partially installed.");
    console.log("             Fix: run cpmm setup and opt into Context7, or run:");
    console.log("                  npm install -g ctx7");
    console.log("                  ctx7 setup --cli --claude");
    console.log("");
    return { failed: true };
  }

  console.log("             Optional. To install:");
  console.log("                  npm install -g ctx7");
  console.log("                  ctx7 setup --cli --claude");
  console.log("");
  return { failed: false };
}

function printRtkSetupResult(result) {
  if (!result) return;

  console.log("RTK Integration:");
  switch (result.outcome) {
    case "already_installed":
      console.log(`  ${colorize("✓", "32")} rtk      [optional] already installed`);
      break;
    case "installed":
      console.log(`  ${colorize("✓", "32")} rtk      [optional] installed (${result.method})`);
      break;
    default:
      console.log(`  ${colorize("⚠", "33")} rtk      [optional] ${result.message}`);
      for (const line of getRtkManualInstallHints()) {
        console.log(`             ${line}`);
      }
      break;
  }

  console.log("  Optional activation:");
  console.log("             1) rtk init -g --hook-only");
  console.log("             2) Re-run cpmm setup to restore the CPMM-managed hook order + timeout");
  console.log("             3) Re-run: cpmm doctor");
  console.log("");
}

function printRtkReconcileResult(result) {
  if (!result || !result.attempted) return;

  if (result.ok) {
    const suffix = result.changed ? "restored" : "already canonical";
    console.log("RTK Hook Management:");
    console.log(`  ${colorize("✓", "32")} managed hook     ${suffix} (CPMM hook first, RTK timeout 10)`);
    console.log("");
    return;
  }

  console.log("RTK Hook Management:");
  console.log(`  ${colorize("⚠", "33")} managed hook     ${result.message || "unable to restore RTK hook state automatically"}`);
  console.log("             Run: rtk init -g --hook-only");
  console.log("             Then: cpmm setup");
  console.log("");
}

function printRtkDoctorStatus(status) {
  console.log("\nRTK Integration:");
  console.log(
    `  ${status.binaryInstalled ? colorize("✓", "32") : colorize("○", "33")} rtk binary        ${
      status.binaryInstalled ? "installed" : "not installed (optional)"
    }`,
  );

  if (status.failReason === "missing_settings_json") {
    console.log(`  ${colorize("✗", "31")} settings.json      missing (~/.claude/settings.json)`);
    console.log("             Fix: re-run cpmm setup");
    console.log("");
    return { failed: true };
  }

  if (status.failReason === "invalid_settings_json") {
    console.log(`  ${colorize("✗", "31")} settings.json      invalid JSON`);
    console.log("             Fix: repair ~/.claude/settings.json, then re-run cpmm doctor");
    console.log("");
    return { failed: true };
  }

  if (!status.cpmmHookFound) {
    console.log(`  ${colorize("✗", "31")} CPMM hook          critical-action-check.sh missing`);
    console.log("             Fix: re-run cpmm setup");
    console.log("");
    return { failed: true };
  }

  console.log(`  ${colorize("✓", "32")} CPMM hook          critical-action-check.sh detected`);

  if (!status.hookEnabled) {
    console.log(`  ${colorize("○", "33")} RTK hook           not enabled (opt-in)`);
    console.log(`             Enable: rtk init -g --hook-only`);
    console.log(`             Docs: ${RTK_DOCS_URL}`);
    console.log("");
    return { failed: false };
  }

  if (status.orderOk) {
    console.log(`  ${colorize("✓", "32")} Hook order         CPMM safety hook precedes RTK hook`);
  } else {
    console.log(`  ${colorize("✗", "31")} Hook order         RTK hook precedes CPMM safety hook`);
    console.log("             Fix order in ~/.claude/settings.json:");
    console.log("             1) ~/.claude/scripts/hooks/critical-action-check.sh (timeout: 5)");
    console.log("             2) ~/.claude/hooks/rtk-rewrite.sh (timeout: 10)");
  }

  if (status.timeoutOk) {
    console.log(`  ${colorize("✓", "32")} RTK timeout        10`);
  } else {
    const rendered = status.timeoutValue == null ? "missing" : String(status.timeoutValue);
    console.log(`  ${colorize("⚠", "33")} RTK timeout        ${rendered} (recommended: 10)`);
    console.log("             Fix: re-run cpmm setup to restore the managed timeout");
  }

  console.log("");
  return { failed: !status.orderOk };
}

function runSetup() {
  console.log(`CPMM v${pkg.version} - Setup`);
  const settingsPath = path.join(process.env.HOME || process.env.USERPROFILE || "", ".claude", "settings.json");
  const preSetupRtkStatus = inspectRtkStatus(settingsPath);
  const shouldRestoreManagedRtkHook = preSetupRtkStatus.hookEnabled;

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

  const rtkResult = attemptRtkInstall();
  printRtkSetupResult(rtkResult);

  // Run install.sh for config files, language, and Perplexity setup
  if (!runInstallScript()) {
    return 1;
  }

  const rtkReconcile = reconcileManagedRtkHook({
    enabledBeforeSetup: shouldRestoreManagedRtkHook,
    settingsPath,
  });
  printRtkReconcileResult(rtkReconcile);

  console.log("Setup complete.");
  return 0;
}

function runInstallScript() {
  const scriptPath = path.resolve(__dirname, "..", "install.sh");
  if (!fs.existsSync(scriptPath)) {
    return true;
  }
  console.log("Configuring CPMM...\n");
  const result = spawnSync("bash", [scriptPath], {
    stdio: "inherit",
    env: { ...process.env, CPMM_SETUP_WRAPPER: "1" },
  });
  if (result.status !== 0) {
    console.error("Config setup had issues. Run 'bash install.sh' manually if needed.");
    return false;
  }
  return true;
}

function runDoctor() {
  console.log(`CPMM v${pkg.version} - Doctor`);

  const results = checkDeps();
  printStatus(results);
  const context7Status = inspectContext7Status(process.env.HOME || process.env.USERPROFILE || "");
  const context7Doctor = printContext7DoctorStatus(context7Status);

  const rtkStatus = inspectRtkStatus(path.join(process.env.HOME || process.env.USERPROFILE || "", ".claude", "settings.json"));
  const rtkDoctor = printRtkDoctorStatus(rtkStatus);

  const missing = results.filter((r) => r.required && !r.installed);
  if (missing.length > 0 || rtkDoctor.failed || context7Doctor.failed) {
    console.log(`Fix: cpmm setup`);
    return 1;
  }

  console.log(colorize("All required checks passed.", "32"));
  return 0;
}

function printHelp() {
  console.log(`CPMM v${pkg.version}

Usage:
  cpmm setup      Install deps + configure CPMM (language, Perplexity, optional ctx7 + official Context7, optional RTK)
  cpmm doctor     Check dependency, Context7, and RTK status
  cpmm --help     Show this help
  cpmm --version  Show version
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
    console.error("CPMM requires macOS/Linux. Windows users: use WSL.");
    return 1;
  }

  switch (cmd) {
    case "setup":
      return runSetup();
    case "doctor":
      return runDoctor();
    default:
      console.error(`Unknown command: ${cmd}\nRun 'cpmm --help' for usage.`);
      return 2;
  }
}

module.exports = { runCli };
