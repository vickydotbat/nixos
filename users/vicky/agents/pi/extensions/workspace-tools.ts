import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const instructionFiles = [
  "AGENTS.md",
  "CLAUDE.md",
  ".cursor/rules",
  ".github/copilot-instructions.md",
];

const toolingFiles = [
  "flake.nix",
  ".envrc",
  "Makefile",
  "package.json",
  "go.mod",
  "Cargo.toml",
  "pyproject.toml",
  "devenv.nix",
  "shell.nix",
  "devshell.nix",
];

const ignoredDirs = new Set([
  ".cache",
  ".direnv",
  ".git",
  ".worktrees",
  "node_modules",
  "result",
]);

async function exists(filePath: string): Promise<boolean> {
  try {
    await stat(filePath);
    return true;
  } catch {
    return false;
  }
}

async function findRepoRoot(pi: ExtensionAPI, cwd: string): Promise<string> {
  const result = await pi.exec("git", ["rev-parse", "--show-toplevel"], { cwd });
  return result.code === 0 && result.stdout.trim() ? result.stdout.trim() : cwd;
}

async function findNearest(cwd: string, names: string[]): Promise<string[]> {
  const found: string[] = [];
  let current = cwd;

  while (true) {
    for (const name of names) {
      const candidate = path.join(current, name);
      if (await exists(candidate)) {
        found.push(candidate);
      }
    }

    if (found.length > 0) return found;

    const parent = path.dirname(current);
    if (parent === current) return [];
    current = parent;
  }
}

async function listTopLevelFiles(root: string): Promise<string[]> {
  const entries = await readdir(root, { withFileTypes: true });
  return entries
    .filter((entry) => !ignoredDirs.has(entry.name))
    .map((entry) => entry.name)
    .sort();
}

async function readPackageScripts(root: string): Promise<string[]> {
  const packagePath = path.join(root, "package.json");
  if (!(await exists(packagePath))) return [];

  const raw = await readFile(packagePath, "utf8");
  const parsed = JSON.parse(raw) as { scripts?: Record<string, string> };
  return Object.keys(parsed.scripts ?? {}).sort();
}

async function readMakeTargets(root: string): Promise<string[]> {
  const makePath = path.join(root, "Makefile");
  if (!(await exists(makePath))) return [];

  const raw = await readFile(makePath, "utf8");
  const targets = new Set<string>();
  for (const line of raw.split(/\r?\n/)) {
    if (!line || line.startsWith("\t") || line.startsWith("#") || line.includes(":=")) continue;
    const match = line.match(/^([A-Za-z0-9_.-]+):(?:\s|$)/);
    if (match) targets.add(match[1]);
  }
  return [...targets].sort();
}

async function detectSolutionFiles(root: string): Promise<string[]> {
  const dirs = [root, path.join(root, "src")];
  const files: string[] = [];

  for (const dir of dirs) {
    if (!(await exists(dir))) continue;
    const entries = await readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.isFile() && /\.(sln|slnx)$/i.test(entry.name)) {
        files.push(path.relative(root, path.join(dir, entry.name)));
      }
    }
  }

  return files.sort();
}

async function gitSummary(pi: ExtensionAPI, cwd: string): Promise<string[]> {
  const commands: Array<[string, string[]]> = [
    ["branch", ["branch", "--show-current"]],
    ["status", ["status", "--short"]],
  ];

  const lines: string[] = [];
  for (const [label, args] of commands) {
    const result = await pi.exec("git", args, { cwd });
    if (result.code !== 0) continue;
    if (label === "branch") lines.push(`Branch: ${result.stdout.trim() || "(detached)"}`);
    if (label === "status") {
      const count = result.stdout.split(/\r?\n/).filter(Boolean).length;
      lines.push(`Dirty paths: ${count}`);
    }
  }
  return lines;
}

function formatRelative(root: string, files: string[]): string[] {
  return files.map((file) => path.relative(root, file) || path.basename(file));
}

function likelySharpPaths(files: string[]): string[] {
  return files.filter((file) =>
    /(^|\/)(secrets?|auth|tokens?|credentials?|\.env|\.sops|generated|dist|build|coverage|workspace|releases?|deploy|infra|node_modules|result)(\/|$)|\.(sops|age|key|pem|p12|crt|mod|hak|tlk|zst|zip|tar|gz)$/i.test(
      file,
    ),
  );
}

async function buildWorkspaceMap(pi: ExtensionAPI, cwd: string): Promise<string> {
  const root = await findRepoRoot(pi, cwd);
  const [instructions, topFiles, packageScripts, makeTargets, solutionFiles, gitLines] =
    await Promise.all([
      findNearest(cwd, instructionFiles),
      listTopLevelFiles(root),
      readPackageScripts(root).catch(() => []),
      readMakeTargets(root).catch(() => []),
      detectSolutionFiles(root).catch(() => []),
      gitSummary(pi, root).catch(() => []),
    ]);

  const presentTooling = toolingFiles.filter((file) => topFiles.includes(file));
  const sharp = likelySharpPaths(topFiles).slice(0, 12);

  const lines = [
    `Repository: ${path.basename(root)} (${root})`,
    ...gitLines,
    "",
    `Instructions: ${
      instructions.length > 0 ? formatRelative(root, instructions).join(", ") : "none found"
    }`,
    `Tooling: ${presentTooling.length > 0 ? presentTooling.join(", ") : "none detected"}`,
    `Make targets: ${makeTargets.length > 0 ? makeTargets.join(", ") : "none detected"}`,
    `Package scripts: ${packageScripts.length > 0 ? packageScripts.join(", ") : "none detected"}`,
    `Solutions: ${solutionFiles.length > 0 ? solutionFiles.join(", ") : "none detected"}`,
    `Sharp paths: ${sharp.length > 0 ? sharp.join(", ") : "none obvious at top level"}`,
  ];

  return lines.join("\n");
}

async function changedFiles(pi: ExtensionAPI, cwd: string): Promise<string[]> {
  const result = await pi.exec("git", ["status", "--short"], { cwd });
  if (result.code !== 0) return [];
  return result.stdout
    .split(/\r?\n/)
    .filter(Boolean)
    .map((line) => line.slice(3).trim())
    .map((file) => (file.includes(" -> ") ? file.split(" -> ").pop() ?? file : file))
    .map((file) => file.replace(/^"|"$/g, ""));
}

async function suggestVerification(pi: ExtensionAPI, cwd: string): Promise<string> {
  const root = await findRepoRoot(pi, cwd);
  const files = await changedFiles(pi, root);
  const topFiles = await listTopLevelFiles(root);
  const packageScripts = await readPackageScripts(root).catch(() => []);
  const makeTargets = await readMakeTargets(root).catch(() => []);
  const suggestions = new Set<string>();

  if (makeTargets.includes("check")) suggestions.add("make check");
  if (topFiles.includes("flake.nix")) suggestions.add("nix flake check");
  if (packageScripts.includes("check")) suggestions.add("npm run check");
  else if (packageScripts.includes("test")) suggestions.add("npm test");
  if (topFiles.includes("go.mod")) suggestions.add("go test ./...");
  if (files.some((file) => file.endsWith(".cs"))) suggestions.add("dotnet test");
  if (files.some((file) => file.endsWith(".sh"))) suggestions.add("shellcheck <changed scripts>");

  const sharp = likelySharpPaths(files);
  const lines = [
    `Changed files: ${files.length}`,
    `Suggested checks: ${suggestions.size > 0 ? [...suggestions].join("; ") : "none inferred"}`,
  ];
  if (sharp.length > 0) {
    lines.push(`Boundary review advised for: ${sharp.slice(0, 12).join(", ")}`);
  }

  return lines.join("\n");
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("workspace-context-status", {
    description: "Show a read-only map of the current repository and task tooling",
    handler: async (_args, ctx) => {
      const report = await buildWorkspaceMap(pi, ctx.cwd);
      ctx.ui.notify(report, "info");
    },
  });

  pi.registerCommand("verification-suggest", {
    description: "Suggest checks for the current diff without running them",
    handler: async (_args, ctx) => {
      const report = await suggestVerification(pi, ctx.cwd);
      ctx.ui.notify(report, "info");
    },
  });

  pi.registerTool({
    name: "workspace_context_status",
    label: "Workspace Context Status",
    description: "Read-only map of repository instructions, tooling, checks, and sharp paths",
    parameters: Type.Object({}),
    async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
      const text = await buildWorkspaceMap(pi, ctx.cwd);
      return { content: [{ type: "text", text }] };
    },
  });

  pi.registerTool({
    name: "verification_suggest",
    label: "Verification Suggest",
    description: "Suggest likely validation commands for the current diff without running them",
    parameters: Type.Object({}),
    async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
      const text = await suggestVerification(pi, ctx.cwd);
      return { content: [{ type: "text", text }] };
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    try {
      const root = await findRepoRoot(pi, ctx.cwd);
      const gitLines = await gitSummary(pi, root);
      ctx.ui.setStatus("workspace", gitLines.join(" | ") || "Workspace ready");
    } catch {
      ctx.ui.setStatus("workspace", "Workspace status unavailable");
    }
  });
}
