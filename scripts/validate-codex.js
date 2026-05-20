#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const skillsRoot = path.join(repoRoot, "skills");
const generatedSkillsRoot = path.join(repoRoot, ".agents", "skills");
const generatedManifestPath = path.join(repoRoot, ".codex", "generated", "skills-manifest.json");

function listDirectories(dirPath) {
  if (!fs.existsSync(dirPath)) {
    return [];
  }

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

  return attributes;
}

function fail(message) {
  process.stderr.write(`${message}\n`);
  process.exitCode = 1;
}

function validateReferences(skillDir, sourceText) {
  const references = [...sourceText.matchAll(/`(references\/[^`]+)`/g)].map((match) => match[1]);
  for (const reference of references) {
    const referencePath = path.join(skillDir, reference);
    if (!fs.existsSync(referencePath)) {
      fail(`Missing referenced file: ${path.relative(repoRoot, referencePath)}`);
    }
  }
}

function validateGeneratedSkills(skillDirs) {
  const generatedSkillDirs = listDirectories(generatedSkillsRoot);
  const sourceSkillSet = new Set(skillDirs);

  for (const generatedSkillName of generatedSkillDirs) {
    if (!sourceSkillSet.has(generatedSkillName)) {
      fail(
        `Legacy generated skill directory detected: .agents/skills/${generatedSkillName}. ` +
          "Run `npm run build:codex` to clean stale generated files.",
      );
      continue;
    }

    const generatedSkillPath = path.join(generatedSkillsRoot, generatedSkillName, "SKILL.md");
    const generatedMetadataPath = path.join(generatedSkillsRoot, generatedSkillName, "agents", "openai.yaml");

    if (!fs.existsSync(generatedSkillPath)) {
      fail(`Missing generated skill file: ${path.relative(repoRoot, generatedSkillPath)}`);
    }

    if (!fs.existsSync(generatedMetadataPath)) {
      fail(`Missing generated metadata file: ${path.relative(repoRoot, generatedMetadataPath)}`);
    }
  }
}

function main() {
  const skillDirs = listDirectories(skillsRoot);

  for (const skillName of skillDirs) {
    const skillDir = path.join(skillsRoot, skillName);
    const sourcePath = path.join(skillDir, "SKILL.md");
    if (!fs.existsSync(sourcePath)) {
      fail(`Missing skill source: skills/${skillName}/SKILL.md`);
      continue;
    }

    const sourceText = fs.readFileSync(sourcePath, "utf8");
    let metadata;
    try {
      metadata = parseFrontmatter(sourceText);
    } catch (error) {
      fail(`Invalid frontmatter in skills/${skillName}/SKILL.md: ${error.message}`);
      continue;
    }

    if (!metadata.name) {
      fail(`Missing frontmatter name in skills/${skillName}/SKILL.md`);
    } else if (metadata.name !== skillName) {
      fail(`Frontmatter name mismatch in skills/${skillName}/SKILL.md: expected "${skillName}", got "${metadata.name}"`);
    }

    if (!metadata.description) {
      fail(`Missing frontmatter description in skills/${skillName}/SKILL.md`);
    }

    validateReferences(skillDir, sourceText);
  }

  if (!fs.existsSync(generatedManifestPath)) {
    fail("Missing generated manifest. Run `npm run build:codex` first.");
  }

  validateGeneratedSkills(skillDirs);

  if (process.exitCode) {
    process.exit(process.exitCode);
  }

  process.stdout.write(`Validated ${skillDirs.length} skills and generated Codex manifest.\n`);
}

main();
