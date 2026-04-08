/**
 * aolun plugin for OpenCode.ai
 *
 * Registers aolun skills directory for OpenCode discovery.
 * Minimal compatibility mode: avoids experimental chat hooks.
 */

import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const normalizePath = (p, homeDir) => {
  if (!p || typeof p !== 'string') return null;
  let normalized = p.trim();
  if (!normalized) return null;

  if (normalized.startsWith('~/')) {
    normalized = path.join(homeDir, normalized.slice(2));
  } else if (normalized === '~') {
    normalized = homeDir;
  }

  return path.resolve(normalized);
};

const createPlugin = async () => {
  const homeDir = os.homedir();
  const skillsDir = path.resolve(__dirname, '../../skills');
  const envConfigDir = normalizePath(process.env.OPENCODE_CONFIG_DIR, homeDir);
  const configDir = envConfigDir || path.join(homeDir, '.config/opencode');

  return {
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];

      if (!config.skills.paths.includes(skillsDir)) {
        config.skills.paths.push(skillsDir);
      }

      const localSkillPath = path.join(configDir, 'skills');
      if (!config.skills.paths.includes(localSkillPath)) {
        config.skills.paths.push(localSkillPath);
      }
    }
  };
};

// Prefer name that matches filename-based plugin loading.
export const AolunPlugin = createPlugin;

// Compatibility alias with superpowers-style naming.
export const SuperpowersPlugin = createPlugin;

export default createPlugin;