#!/usr/bin/env node
//MISE description="Supply runtime model metadata to agent disclosure hooks"
//MISE raw=true
//MISE quiet=true
//USAGE arg "<agent>" help="Agent hook protocol" {
//USAGE   choices "codex" "cursor" "claude" "copilot"
//USAGE }
//USAGE flag "--event <event>" help="Event for hosts that omit hook_event_name" {
//USAGE   choices "sessionStart" "postToolUse" "userPromptTransformed"
//USAGE }

import process from 'node:process';
import { Buffer } from 'node:buffer';
import { execFileSync } from 'node:child_process';
import {
  closeSync,
  fstatSync,
  openSync,
  readFileSync,
  readSync,
  realpathSync,
  statSync,
} from 'node:fs';
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
  transformedPrompt?: string;
  agent_id?: string;
  turn_id?: string;
  prompt_id?: string;
  tool_use_id?: string;
  transcript_path?: string;
  agent_transcript_path?: string;
  model?: string;
  model_id?: string;
  to_model?: string;
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
    'Preserve reported model IDs verbatim. tool_version identifies the client/runtime, not a model snapshot. ' +
    'Transcript matches identify the response that issued the specified tool call; other events report the selected model. ' +
    'Metadata applies only to its supplied session, agent and call scope; do not inherit the parent model. ' +
    'Do not reuse it after a model switch without fresh metadata. ' +
    'An unavailable hook field means this hook did not observe it; it does not override explicit runtime metadata ' +
    'supplied elsewhere for the same current session and agent. ' +
    'Use unavailable only when no scoped runtime evidence supplies the value; do not substitute config defaults or another installation.',
  ].join('\n');
};

const hookScope = (input: HookInput) => {
  const scope: Record<string, string> = {};
  for (
    const key of ['session_id', 'agent_id', 'turn_id', 'prompt_id', 'generation_id', 'tool_use_id']
  ) {
    const value = textValue(input[key]);
    if (value) scope[key] = value;
  }
  const session = textValue(input.conversation_id ?? input.sessionId);
  if (!scope.session_id && session) scope.session_id = session;
  const agent = textValue(input.agentId);
  if (!scope.agent_id && agent) scope.agent_id = agent;
  const tool = textValue(input.toolCallId);
  if (!scope.tool_use_id && tool) scope.tool_use_id = tool;
  return scope;
};

// Inspect only this process's ancestors. A CLI found on PATH might be a different
// installation from the one running the session (especially in Codex Desktop).
const cliVersion = (tool: 'codex' | 'claude' | 'copilot') => {
  const platform = process.platform;
  if (platform === 'win32') return undefined;
  let pid = process.ppid;
  for (let depth = 0; pid > 1 && depth < 8; depth++) {
    let executable;
    const currentPid = pid;
    try {
      const row = execFileSync('/bin/ps', ['-p', String(pid), '-o', 'ppid=,comm='], {
        encoding: 'utf8',
        timeout: 300,
        stdio: ['ignore', 'pipe', 'ignore'],
      }).trim().match(/^(\d+)\s+(.+)$/);
      if (!row) break;
      pid = Number(row[1]);
      executable = row[2];
      if (platform === 'linux') {
        // Linux ps may abbreviate comm; /proc gives the actual executable.
        executable = realpathSync('/proc/' + currentPid + '/exe');
      }
      const name = basename(executable);
      const isCli = name === tool ||
        (tool === 'claude' && /[/\\]claude[/\\]versions[/\\]/.test(executable));
      if (!isAbsolute(executable) || !isCli) continue;
      const output = execFileSync(executable, ['--version'], {
        encoding: 'utf8',
        timeout: 1500,
        maxBuffer: 4096,
        stdio: ['ignore', 'pipe', 'ignore'],
      });
      return textValue(output.match(/\b\d+\.\d+\.\d+(?:[-+][\w.-]+)?\b/)?.[0]);
    } catch {
      // Hooks must still supply the model when process inspection is unavailable.
      if (!executable) break;
    }
  }
};

// Codex

const codexHookOutput = (input: HookInput) => {
  const event = input.hook_event_name;
  const context = disclosureContext({
    tool: 'Codex',
    model: input.model_id ?? input.model,
    version: cliVersion('codex'),
    scope: hookScope(input),
    source: String(event ?? 'sessionStart') + ' hook',
  });
  return { hookSpecificOutput: { hookEventName: event, additionalContext: context } };
};

// Cursor

const cursorHookOutput = (input: HookInput) => {
  const context = disclosureContext({
    tool: 'Cursor',
    model: input.hook_event_name === 'PostModelSwitch'
      ? input.to_model
      : input.model_id ?? input.model,
    version: input.cursor_version,
    scope: hookScope(input),
    source: String(input.hook_event_name ?? 'sessionStart') + ' hook',
  });
  return {
    ...(input.hook_event_name === 'beforeSubmitPrompt' ? { continue: true } : {}),
    additional_context: context,
  };
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
    let fd;
    try {
      fd = openSync(file, 'r');
      const size = fstatSync(fd).size;
      const offset = Math.max(0, size - 4 * 1024 * 1024);
      const buffer = Buffer.alloc(size - offset);
      const count = readSync(fd, buffer, 0, buffer.length, offset);
      let tail = buffer.subarray(0, count).toString('utf8');
      if (offset) tail = tail.slice(tail.indexOf('\n') + 1);
      const lines = tail.split('\n');
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
    } finally {
      if (fd !== undefined) closeSync(fd);
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
    model: event === 'PostModelSwitch' ? input.to_model : observed.model ?? input.model,
    version: observed.version ?? cliVersion('claude'),
    scope: hookScope(input),
    source: observed.source ??
      (input.tool_use_id
        ? event + ' hook; matching transcript response unavailable'
        : String(event ?? 'sessionStart') + ' hook'),
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
  let fd;
  try {
    fd = openSync(file, 'r');
    const size = statSync(file).size;
    if (size > 16 * 1024 * 1024) return {};
    const buffer = Buffer.alloc(size);
    const count = readSync(fd, buffer, 0, size, 0);
    const result: CopilotObservation = {};
    const tool = textValue(input.toolCallId ?? input.tool_use_id);
    let response: CopilotObservation | undefined;
    for (const line of buffer.subarray(0, count).toString('utf8').split('\n')) {
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
      } else if (event.type === 'session.model_change') {
        result.model = textValue(event.data?.newModel);
      } else if (
        event.type === 'assistant.message' && tool &&
        Array.isArray(event.data?.toolRequests) &&
        event.data.toolRequests.some((request) => request.toolCallId === tool)
      ) {
        response = {
          model: textValue(event.data.model),
          source: 'Copilot transcript response matched by toolCallId',
        };
      }
    }
    return { ...result, ...response };
  } catch {
    return {};
  } finally {
    if (fd !== undefined) closeSync(fd);
  }
};

const copilotHookOutput = (input: HookInput) => {
  const observed = copilotMetadata(input);
  const context = disclosureContext({
    tool: 'GitHub Copilot',
    model: observed.model,
    version: cliVersion('copilot'),
    recordedVersion: observed.recordedVersion,
    scope: hookScope(input),
    source: observed.source ?? 'matching Copilot session log selection',
  });
  if (input.hook_event_name === 'userPromptTransformed') {
    if (typeof input.transformedPrompt !== 'string') return {};
    return { modifiedTransformedPrompt: input.transformedPrompt + '\n\n' + context };
  }
  return { additionalContext: context };
};

try {
  const input = JSON.parse(readFileSync(0, 'utf8')) as HookInput;
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new Error('Invalid hook input');
  }
  input.hook_event_name ??= process.env.usage_event;
  let output;
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
  process.stdout.write(JSON.stringify(output) + '\n');
} catch {
  // Metadata collection must never block a prompt or tool call.
  process.stdout.write('{}\n');
}
