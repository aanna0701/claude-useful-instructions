#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const skillsRoot = path.join(repoRoot, "skills");
const outputRoot = path.join(repoRoot, ".agents", "skills");
const codexRoot = path.join(repoRoot, ".codex", "generated");

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function readText(filePath) {
  return fs.readFileSync(filePath, "utf8");
}

function writeText(filePath, content) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, content, "utf8");
}

function listDirectories(dirPath) {
  return fs
    .readdirSync(dirPath, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
}

function parseFrontmatter(sourceText) {
  if (!sourceText.startsWith("---\n")) {
    throw new Error("Missing YAML frontmatter block");
  }

  const end = sourceText.indexOf("\n---\n", 4);
  if (end === -1) {
    throw new Error("Unterminated YAML frontmatter block");
  }

  const rawFrontmatter = sourceText.slice(4, end);
  const body = sourceText.slice(end + 5);
  const attributes = {};
  const lines = rawFrontmatter.split("\n");

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (!line.trim()) {
      continue;
    }

    const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!match) {
      throw new Error(`Unsupported frontmatter line: ${line}`);
    }

    const [, key, remainder] = match;

    if (remainder === ">") {
      const blockLines = [];
      index += 1;
      while (index < lines.length && (/^\s+/.test(lines[index]) || lines[index] === "")) {
        const blockLine = lines[index].replace(/^\s{2}/, "").trim();
        if (blockLine) {
          blockLines.push(blockLine);
        }
        index += 1;
      }
      index -= 1;
      attributes[key] = blockLines.join(" ").trim();
      continue;
    }

    attributes[key] = remainder.trim().replace(/^["']|["']$/g, "");
  }

  return { attributes, body };
}

function yamlEscape(value) {
  return JSON.stringify(value);
}

function collectReferenceFiles(skillDir) {
  const referencesDir = path.join(skillDir, "references");
  if (!fs.existsSync(referencesDir)) {
    return [];
  }

  const results = [];

  function walk(currentDir) {
    for (const entry of fs.readdirSync(currentDir, { withFileTypes: true })) {
      const absolutePath = path.join(currentDir, entry.name);
      if (entry.isDirectory()) {
        walk(absolutePath);
        continue;
      }

      results.push(path.relative(skillDir, absolutePath).replace(/\\/g, "/"));
    }
  }

  walk(referencesDir);
  return results.sort();
}

function buildGeneratedSkill(sourcePath, relativeSourcePath) {
  const sourceText = readText(sourcePath);
  const { body } = parseFrontmatter(sourceText);
  const generatedNotice = [
    "<!-- AUTO-GENERATED FILE. DO NOT EDIT DIRECTLY. -->",
    `<!-- Source: ${relativeSourcePath} -->`,
    "",
  ].join("\n");

  return `${generatedNotice}${body}`;
}

function buildOpenAiYaml(metadata) {
  return [
    `name: ${yamlEscape(metadata.name)}`,
    `description: ${yamlEscape(metadata.description)}`,
    `source: ${yamlEscape(metadata.source)}`,
    `generated_from: ${yamlEscape(metadata.generatedFrom)}`,
    "codex_generation:",
    "  mode: \"auto-only\"",
    "  manual_override_supported: false",
    "",
  ].join("\n");
}

function collectCommandNames() {
  const commandsDir = path.join(repoRoot, "commands");
  return fs
    .readdirSync(commandsDir, { withFileTypes: true })
    .filter((entry) => entry.isFile() && entry.name.endsWith(".md"))
    .map((entry) => entry.name.replace(/\.md$/, ""))
    .sort();
}

function main() {
  ensureDir(outputRoot);
  ensureDir(codexRoot);

  const manifest = {
    policy: {
      mode: "auto-only",
      manualOverrides: false,
      unsupportedKinds: ["commands", "hooks", "rules"],
    },
    skills: [],
    unsupported: {
      commands: collectCommandNames(),
    },
  };

  for (const skillName of listDirectories(skillsRoot)) {
    const skillDir = path.join(skillsRoot, skillName);
    const sourcePath = path.join(skillDir, "SKILL.md");
    if (!fs.existsSync(sourcePath)) {
      continue;
    }

    const sourceText = readText(sourcePath);
    const { attributes } = parseFrontmatter(sourceText);
    const relativeSourcePath = path.relative(repoRoot, sourcePath).replace(/\\/g, "/");
    const generatedDir = path.join(outputRoot, skillName);

    const generatedSkill = buildGeneratedSkill(sourcePath, relativeSourcePath);
    writeText(path.join(generatedDir, "SKILL.md"), generatedSkill);
    writeText(
      path.join(generatedDir, "agents", "openai.yaml"),
      buildOpenAiYaml({
        name: attributes.name || skillName,
        description: attributes.description || "",
        source: relativeSourcePath,
        generatedFrom: `skills/${skillName}`,
      }),
    );

    manifest.skills.push({
      name: attributes.name || skillName,
      description: attributes.description || "",
      source: relativeSourcePath,
      generatedSkill: path.relative(repoRoot, path.join(generatedDir, "SKILL.md")).replace(/\\/g, "/"),
      generatedMetadata: path
        .relative(repoRoot, path.join(generatedDir, "agents", "openai.yaml"))
        .replace(/\\/g, "/"),
      references: collectReferenceFiles(skillDir),
    });
  }

  manifest.skills.sort((left, right) => left.name.localeCompare(right.name));
  writeText(path.join(codexRoot, "skills-manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);

  const readme = [
    "# Generated Codex Artifacts",
    "",
    "This directory is generated by `npm run build:codex`.",
    "",
    "- Source of truth: `skills/`",
    "- Generated skills: `.agents/skills/`",
    "- Manual overrides: not supported in this version",
    "- Unsupported kinds remain listed in `skills-manifest.json` until a safe mapping exists",
    "",
  ].join("\n");
  writeText(path.join(codexRoot, "README.md"), readme);

  process.stdout.write(`Generated ${manifest.skills.length} Codex skill artifacts.\n`);
}

main();
