#!/usr/bin/env node
//MISE description="Supply runtime model metadata to agent disclosure hooks"
//MISE raw=true
//MISE quiet=true
//USAGE arg "<agent>" help="Agent hook protocol" {
//USAGE   choices "codex" "cursor" "claude" "copilot"
//USAGE }

import process from 'node:process';
import { Buffer } from 'node:buffer';
import { execFileSync } from 'node:child_process';
import { readFileSync, realpathSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { basename, dirname, isAbsolute, join } from 'node:path';

interface HookInput {
  [key: string]: unknown;
  hook_event_name?: string;
  session_id?: string;
  sessionId?: string;
  conversation_id?: string;
  generation_id?: string;
  agentId?: string;
  toolCallId?: string;
  agent_id?: string;
  turn_id?: string;
  prompt_id?: string;
  tool_use_id?: string;
  transcript_path?: string;
  agent_transcript_path?: string;
  model?: string;
  model_id?: string;
  cursor_version?: string;
}
interface Disclosure {
  tool: string;
  model?: string;
  provider?: string;
  version?: string;
  source: string;
  recordedVersion?: string;
  scope?: Record<string, string>;
}

// Agents run agent:disclosure-info, which prints this marker. Hooks stay silent
// for every other tool call so metadata appears only when the model asks for it.
const REQUEST_MARKER = '@@AI_DISCLOSURE_REQUEST@@';

// Require the marker on its own line, so reading or searching files that merely
// mention it (like this one) does not count as a request.
const hasMarkerLine = (value: unknown): boolean => {
  if (typeof value === 'string') {
    if (value.split(/\r?\n/).some((line) => line.trim() === REQUEST_MARKER)) return true;
    // Cursor's tool_output is a JSON string whose stdout has escaped newlines.
    try {
      const parsed: unknown = JSON.parse(value);
      return typeof parsed === 'object' && hasMarkerLine(parsed);
    } catch {
      return false;
    }
  }
  if (value && typeof value === 'object') return Object.values(value).some(hasMarkerLine);
  return false;
};

// Claude and Codex send tool_response, Cursor tool_output, and Copilot toolResult
// (or tool_result for PascalCase events).
const requested = (input: HookInput) =>
  ['tool_response', 'tool_output', 'toolResult', 'tool_result'].some((key) =>
    hasMarkerLine(input[key])
  );

// Shared metadata formatting and CLI inspection

const textValue = (value: unknown): string | undefined => {
  if (typeof value !== 'string') return undefined;
  const text = value.trim();
  if (!text || text.length > 200 || [...text].some((char) => char.charCodeAt(0) < 32)) {
    return undefined;
  }
  return text;
};

const disclosureContext = (
  { tool, model, provider, version, source, recordedVersion, scope }: Disclosure,
) => {
  const selected = textValue(model);
  const resolved = selected && !/^(auto|default|opus|sonnet|haiku)$/i.test(selected);
  const publisher = textValue(provider) ?? (
    /^gpt-|^chatgpt-|^o[1-9](?:-|$)/i.test(selected ?? '')
      ? 'OpenAI'
      : /^claude-/i.test(selected ?? '')
      ? 'Anthropic'
      : /^gemini-/i.test(selected ?? '')
      ? 'Google'
      : 'unavailable'
  );
  return [
    'AI disclosure metadata (' + source + '):',
    JSON.stringify({
      tool,
      provider: resolved ? publisher : 'unavailable',
      model: resolved ? selected : 'unavailable',
      tool_version: textValue(version) ?? 'unavailable',
      ...(scope && Object.keys(scope).length ? { scope } : {}),
      ...(selected && !resolved ? { selection: selected } : {}),
      ...(recordedVersion ? { session_creation_tool_version: recordedVersion } : {}),
    }),
    'Use model IDs verbatim; tool_version is the client/runtime, not a model snapshot. ' +
    'This applies only to the scope above; refresh it after a model switch. ' +
    '"unavailable" means this hook did not observe the value; explicit runtime metadata for the same session and agent still applies.',
  ].join('\n');
};

// Canonical scope keys, each followed by the aliases other hosts use for it.
const SCOPE_KEYS = [
  ['session_id', 'conversation_id', 'sessionId'],
  ['agent_id', 'agentId'],
  ['turn_id'],
  ['prompt_id'],
  ['generation_id'],
  ['tool_use_id', 'toolCallId'],
] as const;

const hookScope = (input: HookInput) => {
  const scope: Record<string, string> = {};
  for (const [key, ...aliases] of SCOPE_KEYS) {
    const value = [key, ...aliases].map((name) => textValue(input[name])).find(Boolean);
    if (value) scope[key] = value;
  }
  return scope;
};

const VERSION_PATTERN = /\b\d+\.\d+\.\d+(?:[-+][\w.-]+)?\b/;

// Inspect only this process's ancestors. A CLI found on PATH might be a different
// installation from the one running the session (especially in Codex Desktop).
function* ancestors() {
  const platform = process.platform;
  if (platform === 'win32') return;
  let pid = process.ppid;
  for (let depth = 0; pid > 1 && depth < 8; depth++) {
    const currentPid = pid;
    let executable: string | undefined;
    try {
      const row = execFileSync('/bin/ps', ['-p', String(pid), '-o', 'ppid=,comm='], {
        encoding: 'utf8',
        timeout: 300,
        stdio: ['ignore', 'pipe', 'ignore'],
      }).trim().match(/^(\d+)\s+(.+)$/);
      if (!row) return;
      pid = Number(row[1]);
      executable = row[2] as string;
      // Linux ps may abbreviate comm; /proc gives the actual executable.
      if (platform === 'linux') executable = realpathSync('/proc/' + currentPid + '/exe');
    } catch {
      // Hooks must still supply the model when process inspection is unavailable.
      if (!executable) return;
    }
    if (isAbsolute(executable)) yield { pid: currentPid, executable };
  }
}

const executableVersion = (executable: string) => {
  try {
    const output = execFileSync(executable, ['--version'], {
      encoding: 'utf8',
      timeout: 1500,
      maxBuffer: 4096,
      stdio: ['ignore', 'pipe', 'ignore'],
    });
    return textValue(output.match(VERSION_PATTERN)?.[0]);
  } catch {
    return undefined;
  }
};

// Codex's rollout log records only the version that created the session.
const codexVersion = () => {
  for (const { executable } of ancestors()) {
    if (basename(executable) === 'codex') return executableVersion(executable);
  }
};

// Codex

const codexHookOutput = (input: HookInput) => {
  const event = input.hook_event_name;
  const context = disclosureContext({
    tool: 'Codex',
    model: input.model_id ?? input.model,
    version: codexVersion(),
    scope: hookScope(input),
    source: String(event ?? 'PostToolUse') + ' hook',
  });
  return { hookSpecificOutput: { hookEventName: event, additionalContext: context } };
};

// Cursor

const cursorHookOutput = (input: HookInput) => {
  const context = disclosureContext({
    tool: 'Cursor',
    model: input.model_id ?? input.model,
    version: input.cursor_version,
    scope: hookScope(input),
    source: String(input.hook_event_name ?? 'postToolUse') + ' hook',
  });
  return { additional_context: context };
};

// Claude Code

interface ClaudeObservation {
  model?: string;
  version?: string;
  source?: string;
}
interface ClaudeTranscriptRecord {
  sessionId?: string;
  version?: unknown;
  message?: { model?: unknown; content?: { type?: string; id?: string }[] };
}
// Match the exact response that issued this tool call. Never use the newest
// message from a different call, session, or parent agent.
const claudeMetadata = async (input: HookInput): Promise<ClaudeObservation> => {
  const toolId = textValue(input.tool_use_id);
  const pathValue = (value: unknown): string | undefined =>
    typeof value === 'string' && isAbsolute(value) && !value.includes('\0') ? value : undefined;
  const transcript = pathValue(input.transcript_path);
  if (!toolId || !transcript) return {};
  let file = transcript;
  if (input.agent_id) {
    const agent = textValue(input.agent_id);
    if (!agent || !/^[\w-]+$/.test(agent)) return {};
    const explicit = pathValue(input.agent_transcript_path);
    // Claude uses this layout for child transcripts (also reported at SubagentStop).
    const child = join(
      dirname(transcript),
      basename(transcript, '.jsonl'),
      'subagents',
      'agent-' + agent + '.jsonl',
    );
    file = explicit || (basename(transcript) === 'agent-' + agent + '.jsonl' ? transcript : child);
  }
  for (let attempt = 0; attempt < 4; attempt++) {
    try {
      const lines = readFileSync(file, 'utf8').split('\n');
      for (let index = lines.length - 1; index >= 0; index--) {
        let record: ClaudeTranscriptRecord;
        try {
          record = JSON.parse(lines[index]);
        } catch {
          continue;
        }
        if (record.sessionId && input.session_id && record.sessionId !== input.session_id) continue;
        if (
          !Array.isArray(record.message?.content) || !record.message.content.some(
            (block) => block.type === 'tool_use' && block.id === toolId,
          )
        ) continue;
        return {
          model: textValue(record.message?.model),
          version: textValue(record.version),
          source: 'Claude transcript response matched by tool_use_id',
        };
      }
    } catch {
      /* The transcript can lag the hook or be unavailable. */
    }
    if (attempt < 3) await new Promise((resolve) => setTimeout(resolve, 25));
  }
  return {};
};

const claudeHookOutput = async (input: HookInput) => {
  const event = input.hook_event_name;
  const observed = await claudeMetadata(input);
  const context = disclosureContext({
    tool: 'Claude Code',
    model: observed.model ?? input.model,
    version: observed.version,
    scope: hookScope(input),
    source: observed.source ??
      String(event ?? 'PostToolUse') + ' hook; matching transcript response unavailable',
  });
  return { hookSpecificOutput: { hookEventName: event, additionalContext: context } };
};

// GitHub Copilot

interface CopilotObservation {
  model?: string;
  source?: string;
  recordedVersion?: string;
}

interface CopilotEvent {
  type?: string;
  data?: {
    sessionId?: string;
    selectedModel?: unknown;
    copilotVersion?: unknown;
    newModel?: unknown;
    model?: unknown;
    toolRequests?: { toolCallId?: string }[];
    usage?: {
      model?: unknown;
      parentToolCallId?: unknown;
      toolCounts?: Record<string, unknown>;
    };
  };
}
// Copilot does not include a model in its documented hook payload. Only inspect
// the exact session named by the hook; never pick another chat by mtime.
const copilotMetadata = (
  input: HookInput,
  root = process.env.COPILOT_HOME || join(homedir(), '.copilot'),
) => {
  const session = textValue(input.sessionId ?? input.session_id);
  if (!session || !/^[\w-]+$/.test(session)) return {};
  const file = join(root, 'session-state', session, 'events.jsonl');
  try {
    const text = readFileSync(file, 'utf8');
    const result: CopilotObservation = {};
    const tool = textValue(input.toolCallId ?? input.tool_use_id);
    const toolName = textValue(input.toolName);
    let response: CopilotObservation | undefined;
    let usage: CopilotObservation | undefined;
    for (const line of text.split('\n')) {
      let event: CopilotEvent;
      try {
        event = JSON.parse(line);
      } catch {
        continue;
      }
      if (event.type === 'session.start' && event.data?.sessionId === session) {
        result.model = textValue(event.data?.selectedModel);
        // This is the version recorded at session creation, not proof of the
        // current executable's version after resuming in another client.
        result.recordedVersion = textValue(event.data?.copilotVersion);
      } else if (event.type === 'session.resume') {
        result.model = textValue(event.data?.selectedModel) ?? result.model;
        usage = undefined;
      } else if (event.type === 'session.model_change') {
        result.model = textValue(event.data?.newModel);
        usage = undefined;
      } else if (
        event.type === 'assistant.message' && tool &&
        Array.isArray(event.data?.toolRequests) &&
        event.data.toolRequests.some((request) => request.toolCallId === tool)
      ) {
        // Some responses record no model; keep the session selection for those.
        const model = textValue(event.data.model);
        response = model
          ? { model, source: 'Copilot transcript response matched by toolCallId' }
          : undefined;
      } else if (
        event.type === 'session.usage_record' && !input.agentId && toolName &&
        !event.data?.usage?.parentToolCallId &&
        Number(event.data?.usage?.toolCounts?.[toolName]) > 0
      ) {
        // Fused (auto) turns append the response only after the phase ends, so the
        // hook cannot match it yet. The request's usage record is already written.
        const model = textValue(event.data?.usage?.model);
        usage = model
          ? { model, source: 'latest root Copilot usage record requesting ' + toolName }
          : undefined;
      }
    }
    return { ...result, ...(response ?? usage) };
  } catch {
    return {};
  }
};

const RUNTIME_PACKAGE = Buffer.from('@github/copilot');
const RUNTIME_VERSION = /^(\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+?)?)BuildCommitId/;

// runtime.node, loaded by copilot-runtime, embeds its package version next to
// its build metadata.
const embeddedRuntimeVersion = (pid: number, executable: string) => {
  const library = join(dirname(executable), 'runtime.node');
  try {
    const started = Date.parse(
      execFileSync('/bin/ps', ['-p', String(pid), '-o', 'lstart='], {
        encoding: 'utf8',
        timeout: 300,
        env: { ...process.env, LC_ALL: 'C' },
        stdio: ['ignore', 'pipe', 'ignore'],
      }).trim(),
    );
    // An app update can replace the file under an older runtime that is still running.
    if (!(statSync(library).mtimeMs < started + 1000)) return undefined;
    const bytes = readFileSync(library);
    for (
      let at = bytes.indexOf(RUNTIME_PACKAGE);
      at !== -1;
      at = bytes.indexOf(RUNTIME_PACKAGE, at + 1)
    ) {
      const start = at + RUNTIME_PACKAGE.length;
      const marker = bytes.subarray(start, start + 64).toString('latin1');
      const version = marker.match(RUNTIME_VERSION)?.[1];
      if (version) return textValue(version);
    }
  } catch {
    // Report unavailable rather than guess.
  }
};

// The CLI is `copilot`; the VS Code and desktop SDKs run `copilot-runtime`, which
// has no --version. Desktop installs it under a versioned cache directory.
const copilotVersion = () => {
  for (const { pid, executable } of ancestors()) {
    const name = basename(executable);
    if (name === 'copilot') return executableVersion(executable);
    if (name !== 'copilot-runtime') continue;
    const versioned = basename(dirname(executable)).match(/^copilot-sdk-runtime-(.+)$/)?.[1];
    if (versioned && VERSION_PATTERN.test(versioned)) return textValue(versioned);
    return embeddedRuntimeVersion(pid, executable);
  }
};

const copilotHookOutput = (input: HookInput) => {
  const root = process.env.COPILOT_HOME || join(homedir(), '.copilot');
  const observed = copilotMetadata(input, root);
  const version = copilotVersion();
  const context = disclosureContext({
    tool: 'GitHub Copilot',
    model: observed.model,
    version,
    recordedVersion: version ? undefined : observed.recordedVersion,
    scope: hookScope(input),
    source: observed.source ?? 'matching Copilot session log selection',
  });
  return { additionalContext: context };
};

try {
  const input = JSON.parse(readFileSync(0, 'utf8')) as HookInput;
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new Error('Invalid hook input');
  }
  let output = {};
  if (requested(input)) {
    switch (process.env.usage_agent) {
      case 'codex':
        output = codexHookOutput(input);
        break;
      case 'cursor':
        output = cursorHookOutput(input);
        break;
      case 'claude':
        output = await claudeHookOutput(input);
        break;
      case 'copilot':
        output = copilotHookOutput(input);
        break;
      default:
        throw new Error('Unknown agent hook protocol');
    }
  }
  process.stdout.write(JSON.stringify(output) + '\n');
} catch {
  // Metadata collection must never block a prompt or tool call.
  process.stdout.write('{}\n');
}
