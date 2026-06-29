import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const sensitivePatterns: Array<[string, RegExp]> = [
  ["auth material", /(^|\/)(auth|tokens?|credentials?|provider|account)\b/i],
  ["environment secret", /(^|\/)\.env(\.|$)|\.env$/i],
  ["SOPS or age secret", /\.(sops|age)(\.|$)|(^|\/)\.sops(\/|$)/i],
  ["SSH or certificate material", /(^|\/)(\.ssh|ssh)(\/|$)|\.(pem|key|p12|crt|cer)$/i],
  ["runtime secret path", /^\/run\/(secrets|agenix)(\/|$)/i],
  ["secret directory", /(^|\/)secrets?(\/|$)/i],
];

function classifyPath(filePath: string): string[] {
  return sensitivePatterns
    .filter(([, pattern]) => pattern.test(filePath))
    .map(([label]) => label);
}

async function diffPaths(pi: ExtensionAPI, cwd: string): Promise<string[]> {
  const result = await pi.exec("git", ["status", "--short"], { cwd });
  if (result.code !== 0) return [];
  return result.stdout
    .split(/\r?\n/)
    .filter(Boolean)
    .map((line) => line.slice(3).trim())
    .map((file) => (file.includes(" -> ") ? file.split(" -> ").pop() ?? file : file))
    .map((file) => file.replace(/^"|"$/g, ""));
}

function renderReport(paths: string[]): string {
  if (paths.length === 0) return "No paths supplied or changed paths detected.";

  const rows = paths.map((filePath) => {
    const labels = classifyPath(filePath);
    return `${labels.length > 0 ? "SHARP" : "ok"} ${filePath}${
      labels.length > 0 ? ` (${labels.join(", ")})` : ""
    }`;
  });

  const sharpCount = rows.filter((row) => row.startsWith("SHARP ")).length;
  return [`Sensitive path review: ${sharpCount}/${paths.length} sharp`, ...rows].join("\n");
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("secret-path-tripwire", {
    description: "Classify secret-looking paths in the current diff without reading file contents",
    handler: async (_args, ctx) => {
      const paths = await diffPaths(pi, ctx.cwd);
      ctx.ui.notify(renderReport(paths), "info");
    },
  });

  pi.registerTool({
    name: "classify_sensitive_paths",
    label: "Classify Sensitive Paths",
    description: "Classify supplied or changed paths for secret-handling risk without opening files",
    parameters: Type.Object({
      paths: Type.Optional(
        Type.Array(Type.String(), {
          description: "Paths to classify. If omitted, current git diff paths are used.",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const paths = params.paths && params.paths.length > 0 ? params.paths : await diffPaths(pi, ctx.cwd);
      return { content: [{ type: "text", text: renderReport(paths) }] };
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    try {
      const paths = await diffPaths(pi, ctx.cwd);
      const sharpCount = paths.filter((filePath) => classifyPath(filePath).length > 0).length;
      if (sharpCount > 0) ctx.ui.setStatus("secrets", `${sharpCount} sharp changed path(s)`);
    } catch {
      // The tripwire is advisory and must not block startup.
    }
  });
}
