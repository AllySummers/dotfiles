import {
  standardCommands,
} from 'https://raw.githubusercontent.com/AllySummers/mise-sync-completions/main/src/presets.ts';
import type { RegistryEntry } from 'https://raw.githubusercontent.com/AllySummers/mise-sync-completions/main/src/shared.ts';

export const tools: Record<string, RegistryEntry> = {
  // Installed via `[tools."http:blacksmith"]`; the binary is `blacksmith`.
  blacksmith: {
    ...standardCommands('blacksmith'),
    aliases: ['http:blacksmith'],
    completionName: 'blacksmith',
  },
};
