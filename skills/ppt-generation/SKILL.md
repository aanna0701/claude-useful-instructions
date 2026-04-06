---
name: ppt-generation
description: "Fill a pre-formatted PowerPoint template (.potx or .pptx) with content without changing layout or design. Use this skill whenever the user wants to populate an existing PPT template with new content, fill in slides from source documents, or inject text into a base presentation while preserving its visual design. Trigger when: user mentions 'fill template', 'populate slides', 'use this template', 'base PPT', 'template PPT', references a .potx file, or asks to create a presentation from an existing design template. Also trigger when user says things like '이 템플릿에 내용 넣어줘', '베이스 PPT에 채워줘', '템플릿 기반으로 발표자료 만들어줘'. This skill treats the base PPT as an immutable design system — it never modifies formatting, only inserts content."
---

# PPT Fill-from-Template

Populate a base PPT template with concise, technically precise content.
The base PPT is an **immutable design system** — never modify its formatting.

## When to Read This Skill

Read this skill when:
- A .potx or .pptx template file is provided as a base
- The user wants to fill existing slide layouts with new content
- Source material (docs, notes, papers) needs to be converted into slides using a template

## Core Principle

**You are a content injector, not a slide designer.**

The template defines all visual rules: layout positions, fonts, bullet styles, colors, diagram shapes, spacing. Your job is to insert text into designated placeholder slots and nothing else.

## Non-Negotiable Rules

1. **Never change** fonts, font sizes, bullet styles, colors, spacing, alignment, or object positions
2. **Never move, resize, or delete** shapes, text boxes, or images that exist in the template
3. **Only replace** placeholder text or insert content into designated template slots
4. **Follow existing** body font and formatting — inherit all `<a:rPr>` and `<a:pPr>` from the template
5. **Keep content concise**, technical, and presentation-ready — prefer phrases over sentences
6. **One slide = one core message** — never mix multiple arguments on a single slide
7. **Never add** decorative elements, animations, or new shapes

## Workflow

Follow these steps in order. Each step produces an artifact that the next step consumes.

### Step 1: Template Analysis (Guard)

Analyze the template structure. This is the most critical step.

```bash
# 1. Visual inspection
python /mnt/skills/public/pptx/scripts/thumbnail.py template.pptx

# 2. Unpack for XML analysis
# For .potx files: use unzip (the pptx unpack script rejects potx content type)
mkdir -p unpacked
unzip -o template.potx -d unpacked/

# For .pptx files: use the standard unpack tool
python /mnt/skills/public/pptx/scripts/office/unpack.py template.pptx unpacked/
```

For each slideLayout XML, extract:
- Layout name (`matchingName` attribute)
- All placeholders: type, idx, position, size
- Bullet hierarchy: levels, characters, font sizes, bold settings
- Fixed elements: logos, confidential bars, copyright notices
- Background images and relationships

Produce a **template contract** — a structured summary of what can and cannot be touched.

**Template contract must include:**
- List of all layouts and their purposes
- For each layout: which placeholder indices exist and what they're for
- Bullet hierarchy rules (level → character → font size → bold)
- Fixed elements that must never be modified
- Maximum content constraints (estimated from placeholder dimensions)

### Step 2: Slot Extraction

For each slide that needs content, identify the exact placeholder slots.
Estimate max content per slot from placeholder dimensions (cx, cy in EMU) and font sizes from lstStyle.

### Step 3: Source Distillation

Read the reference file [references/writing-rules.md](references/writing-rules.md) for detailed compression and style rules.

Compress source material into slide-ready content:
- Explanatory paragraphs → core claims
- Verbose sentences → noun/verb phrases
- One claim per line
- Preserve technical terms exactly

### Step 4: Slide Message Planning

For each slide, define ONE core message before writing content:

```
Slide N:
  Purpose: [explain problem / present solution / show results / compare methods]
  Core message: [one sentence stating the takeaway]
  Evidence: [2-4 supporting points]
```

Without this step, the result becomes an information dump with no narrative.

### Step 5: Content Generation

Read the reference file [references/writing-rules.md](references/writing-rules.md) for content generation rules by slide type (bullets, tables, figure captions, diagrams).

Generate content respecting the template's bullet hierarchy and constraints.
Follow the template's lstStyle levels exactly — do not invent formatting.

### Step 6: XML Insertion

Insert generated content into the template XML using the Edit tool (str_replace).

**Critical XML rules:**

1. **Preserve all `<a:pPr>` attributes** from the template
2. **Preserve all `<a:rPr>` attributes** — font, size, bold, color must match lstStyle
3. **Each bullet = separate `<a:p>` element** with correct `lvl` attribute
4. **Set language attributes** — `lang="ko-KR"` for Korean, `lang="en-US"` for English
5. **Never concatenate** multiple items into one `<a:t>`
6. **Let formatting inherit** from lstStyle — only set `lvl` to pick the right level

```xml
<!-- Template for a bullet paragraph — lvl determines style from lstStyle -->
<a:p>
  <a:pPr lvl="1"/>
  <a:r>
    <a:rPr lang="en-US" dirty="0"/>
    <a:t>Bullet text here</a:t>
  </a:r>
</a:p>
```

Read the pptx skill's [editing.md](/mnt/skills/public/pptx/editing.md) for XML editing patterns and common pitfalls.

### Step 7: Density Check

After inserting content, verify each slide:

| Check | Threshold | Action if exceeded |
|-------|-----------|-------------------|
| Main bullets (lvl 1) | ≤ 5 | Remove least important or split slide |
| Chars per bullet | ≤ 60 | Compress: remove modifiers, use phrases |
| Title length | ≤ 50 chars | Shorten |

**Overflow resolution priority:**
1. Remove modifiers and hedging
2. Remove duplicate bullets
3. Delete examples
4. Move supporting info to speaker notes
5. Propose splitting into 2 slides — **never force-shrink text**

### Step 8: Format Compliance Review

Final check before output:

- [ ] No font changes from template defaults
- [ ] No spacing/alignment modifications
- [ ] No new shapes or decorative elements
- [ ] All text in designated placeholder indices only
- [ ] Bullet hierarchy matches template lstStyle
- [ ] Language attributes set correctly
- [ ] No leftover placeholder text
- [ ] Consistent terminology across all slides
- [ ] Each slide has exactly one core message

```bash
# Check for leftover placeholder text
python -m markitdown output.pptx | grep -iE "마스터|클릭|{Name}|{Date}|placeholder|Lorem"

# Visual QA
python /mnt/skills/public/pptx/scripts/office/soffice.py --headless --convert-to pdf output.pptx
rm -f slide-*.jpg
pdftoppm -jpeg -r 150 output.pdf slide
ls -1 "$PWD"/slide-*.jpg
```

Visually inspect every slide image for text overflow, empty placeholders, and density issues.

## Working with .potx Files

.potx files are structurally identical to .pptx (both ZIP archives with XML) but have a different content type. Key handling:

1. **Unpack**: Use `unzip` instead of `unpack.py` (which rejects the potx content type)
   ```bash
   mkdir -p unpacked
   unzip -o template.potx -d unpacked/
   ```
2. **Content type fix**: In `[Content_Types].xml`, change `presentationml.template.main+xml` to `presentationml.presentation.main+xml`
   ```python
   with open('unpacked/[Content_Types].xml', 'r') as f:
       content = f.read()
   content = content.replace(
       'presentationml.template.main+xml',
       'presentationml.presentation.main+xml'
   )
   with open('unpacked/[Content_Types].xml', 'w') as f:
       f.write(content)
   ```
3. **Slide layouts**: .potx defines reusable layouts in `ppt/slideLayouts/` — these are the design templates you populate
4. **Adding slides**: Use `add_slide.py` to create new slides from available layouts

### Critical .potx Workflow Order

The order of operations matters — getting this wrong causes `clean.py` to delete your slides:

1. Unzip the .potx
2. Fix content type in `[Content_Types].xml`
3. Use `add_slide.py` to create slides from layouts (this updates both rels and Content_Types)
4. **Add `<p:sldId>` entries to `presentation.xml`** (must happen BEFORE clean.py)
5. Edit slide XML to inject content
6. Run `clean.py` (now it sees the slides are referenced)
7. Run `pack.py`

If you add slides but forget step 4, `clean.py` will treat them as orphans and delete them.

### Slide Content from Layouts

`add_slide.py` creates empty slides — it does NOT copy the layout's placeholder shapes into the slide XML. You must add placeholder shapes manually:

```xml
<!-- Add a placeholder that references layout's idx -->
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="2" name="Title"/>
    <p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>
    <p:nvPr><p:ph type="body" idx="1"/></p:nvPr>
  </p:nvSpPr>
  <p:spPr/>
  <p:txBody>
    <a:bodyPr/>
    <a:lstStyle/>
    <a:p>
      <a:pPr lvl="0"/>
      <a:r>
        <a:rPr lang="en-US" dirty="0"/>
        <a:t>Your title here</a:t>
      </a:r>
    </a:p>
  </p:txBody>
</p:sp>
```

The `idx` must match the layout's placeholder index. The `lvl` attribute on `<a:pPr>` selects which level of the layout's `<a:lstStyle>` to apply — this is how you get the correct bullet character, font size, and bold setting without hardcoding any formatting.

## Assembling Multi-Slide Presentations

When the template has layout definitions but few sample slides:

1. Decide slide count from source material and message plan
2. Use `add_slide.py` to create slides from the appropriate layout
3. Insert each `<p:sldId>` into `<p:sldIdLst>` in presentation.xml
4. Edit each slide's XML to inject content
5. Run `clean.py` then `pack.py`

## Output Artifacts

Every run produces:
1. **filled.pptx** — the final presentation
2. **slide_outline.md** — slide-by-slide summary of core messages
3. **review_report.md** — density check and compliance status

## Absolute Prohibitions

- Changing template fonts or font sizes
- Adjusting letter-spacing or line-spacing
- Resizing or repositioning text boxes or shapes
- Modifying shape positions or diagram structures
- Adding arbitrary color highlights
- Adding animations or transitions
- Inserting decorative elements

## Dependencies

Relies on the base pptx skill tools at `/mnt/skills/public/pptx/`:
- `scripts/office/unpack.py` and `scripts/office/pack.py`
- `scripts/add_slide.py`, `scripts/clean.py`, `scripts/thumbnail.py`
- `scripts/office/soffice.py` for PDF conversion
- `pip install "markitdown[pptx]"` for QA text extraction
- `pdftoppm` for visual QA
