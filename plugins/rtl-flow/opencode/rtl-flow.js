// rtl-flow for OpenCode: the same agents, commands, skill and rules as the Claude Code plugin.
//
// Nothing about the workflow is defined here. Agents and commands are registered from agents/*.md and
// commands/*.md, the skill from skills/rtl-design-flow/SKILL.md, and every tool call is judged by the
// same hooks/flow_hook.py that Claude Code runs; this file only translates between the two tool formats.
// Connected by `python rtlflow.py install-opencode`, which generates a small loader for this module.
import { execFile } from "node:child_process"
import { mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs"
import { homedir } from "node:os"
import { basename, dirname, join, resolve } from "node:path"
import { fileURLToPath } from "node:url"

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..")
const SKILL = join(ROOT, "skills", "rtl-design-flow")
const HOOK = join(ROOT, "hooks", "flow_hook.py")
const NS = "rtl-flow:"
const ROLES = new Set(["spec-author", "architect", "rtl-engineer", "tb-engineer", "debugger"])
const WRITE_TOOLS = new Set(["write", "edit", "multiedit", "patch", "apply_patch"])

function frontMatter(text) {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?/)
  const fields = {}
  for (const line of (m ? m[1] : "").split(/\r?\n/)) {
    const f = line.match(/^([\w-]+):\s*(.*)$/)
    if (f) fields[f[1]] = f[2].replace(/^"(.*)"$/, "$1")
  }
  return { fields, body: m ? text.slice(m[0].length) : text }
}

function markdownFiles(dir) {
  return readdirSync(dir).filter((f) => f.endsWith(".md")).map((f) => ({
    name: basename(f, ".md"),
    ...frontMatter(readFileSync(join(dir, f), "utf8")),
  }))
}

const withSkillPath = (text) => text.replaceAll("$SKILL", SKILL.replaceAll("\\", "/"))

function allow(rules, pattern) {
  const out = typeof rules === "string" ? { "*": rules } : { ...(rules ?? {}) }
  out[pattern] = "allow"
  return out
}

function configHome() {
  return join(process.env.XDG_CONFIG_HOME || join(homedir(), ".config"), "opencode")
}

function publishSkill() {
  const dir = join(configHome(), "skills", "rtl-design-flow")
  mkdirSync(dir, { recursive: true })
  const { fields, body } = frontMatter(readFileSync(join(SKILL, "SKILL.md"), "utf8"))
  writeFileSync(join(dir, "SKILL.md"),
    `---\nname: ${fields.name}\ndescription: ${fields.description}\n---\n\n` +
    `> 本文件在 OpenCode 启动时自动生成。文中的 $SKILL 就是 ${SKILL.replaceAll("\\", "/")}\n\n${withSkillPath(body)}`)
}

function patchedFiles(text) {
  return [...String(text ?? "").matchAll(/^\*\*\* (?:Add|Update|Delete) File: (.+)$/gm)].map((m) => m[1].trim())
}

// One OpenCode tool call as the Claude Code tool calls flow_hook.py understands.
function translate(tool, args) {
  const a = args ?? {}
  const file = a.filePath
  switch (tool) {
    case "bash": return [["Bash", { command: a.command }]]
    case "read": return [["Read", { file_path: file }]]
    case "write": return [["Write", { file_path: file, content: a.content }]]
    case "edit":
      return [["Edit", { file_path: file, old_string: a.oldString, new_string: a.newString, replace_all: a.replaceAll }]]
    case "multiedit":
      return [["MultiEdit", {
        file_path: file,
        edits: (a.edits ?? []).map((e) => ({ old_string: e.oldString, new_string: e.newString, replace_all: e.replaceAll })),
      }]]
    case "patch":
    case "apply_patch":
      // the hook cannot replay a patch: NotebookEdit makes it apply its strictest per-file rules
      return patchedFiles(a.patchText).map((p) => ["NotebookEdit", { file_path: p, old_string: a.patchText, new_string: a.patchText }])
    case "glob": return [["Glob", { pattern: a.pattern, path: a.path }]]
    case "grep": return [["Grep", { pattern: a.pattern, path: a.path }]]
    case "list": return [["Glob", { pattern: "*", path: a.path }]]
    default: return []
  }
}

export function createPlugin(python) {
  function runHook(payload) {
    return new Promise((done) => {
      const child = execFile(python, [HOOK], {
        timeout: 30000, maxBuffer: 4 * 1024 * 1024, encoding: "utf8",
        env: { ...process.env, PYTHONUTF8: "1", PYTHONIOENCODING: "utf-8" },
      }, (err, stdout) => {
        if (err) return done(null)      // same as Claude Code: a broken hook never blocks work
        try { done(stdout.trim() ? JSON.parse(stdout) : null) } catch { done(null) }
      })
      child.stdin.on("error", () => {})
      child.stdin.end(JSON.stringify(payload))
    })
  }

  return async ({ client, directory }) => {
    const agentOf = new Map()
    const parentOf = new Map()

    async function isChild(sessionID) {
      if (!parentOf.has(sessionID)) {
        const r = await client.session.get({ path: { id: sessionID } }).catch(() => null)
        if (!r?.data) return false
        parentOf.set(sessionID, r.data.parentID ?? "")
      }
      return Boolean(parentOf.get(sessionID))
    }

    // flow_hook.py's agent_type: role name for rtl-flow agents, empty for the orchestrator (main session)
    async function agentType(sessionID) {
      const name = agentOf.get(sessionID) ?? ""
      if (ROLES.has(name.split(":").pop())) return name
      return (await isChild(sessionID)) ? name || "general" : ""
    }

    return {
      config: async (cfg) => {
        cfg.agent ??= {}
        cfg.command ??= {}
        cfg.permission ??= {}
        cfg.permission.external_directory = allow(cfg.permission.external_directory, join(ROOT, "*"))
        for (const a of markdownFiles(join(ROOT, "agents"))) {
          cfg.agent[NS + a.name] = { description: a.fields.description, mode: "subagent", prompt: withSkillPath(a.body) }
        }
        for (const c of markdownFiles(join(ROOT, "commands"))) {
          cfg.command[NS + c.name] = { description: c.fields.description, template: withSkillPath(c.body) }
        }
        publishSkill()
      },

      // the plugin types say string, OpenCode 1.2 passes the agent object
      "chat.params": async (input) => { agentOf.set(input.sessionID, input.agent?.name ?? input.agent) },

      "tool.execute.before": async (input, output) => {
        let reason = null
        try {
          for (const [tool_name, tool_input] of translate(input.tool, output.args)) {
            const res = await runHook({
              hook_event_name: "PreToolUse", agent_type: await agentType(input.sessionID),
              tool_name, tool_input, cwd: output.args?.workdir || directory,
            })
            const h = res?.hookSpecificOutput
            if (h?.permissionDecision === "deny") { reason = h.permissionDecisionReason; break }
          }
        } catch (e) {
          console.error(`rtl-flow plugin error (ignored): ${e}`)      // fail open, as the Claude Code hook does
        }
        if (reason) throw new Error(reason)
      },

      "tool.execute.after": async (input, output) => {
        if (WRITE_TOOLS.has(input.tool)) {
          for (const [tool_name, tool_input] of translate(input.tool, input.args)) {
            const res = await runHook({ hook_event_name: "PostToolUse", tool_name, tool_input, cwd: directory })
            const note = res?.hookSpecificOutput?.additionalContext
            if (note) output.output += `\n\n${note}`
          }
        }
        if (input.tool === "task") {
          const res = await runHook({
            hook_event_name: "SubagentStop", agent_type: input.args?.subagent_type ?? "",
            last_assistant_message: output.output, cwd: directory,
          })
          if (res?.decision === "block") {
            output.output += `\n\n${res.reason}\n请用同一个 task_id 让该 agent 继续补齐，不要自己代写。`
          }
        }
      },
    }
  }
}
