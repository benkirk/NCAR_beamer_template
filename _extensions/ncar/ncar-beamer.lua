--[[
ncar-beamer.lua -- Markdown sugar for the NCAR beamer theme (beamer output only)

  ## Title {.feature background="photo.jpg"}
      full-bleed photo frame (-> \begin{frame}[ncarbg=photo.jpg])

  ## Thank you! {.closing}
      closing frame on the brand field; the heading becomes the large
      headline and the slide's content sits beneath it

  # Section
  One paragraph right after the divider heading.
      the paragraph becomes the divider's subtitle instead of a slide of
      its own (declared in the preamble as \ncarsectionsubtitle{n}{...},
      so no stray block before the section can open an empty frame)

  A paragraph that starts with † (or ‡)
      a slide footnote: every one on the frame, columns included, moves to
      the frame's foot under a short rule (\ncarfootnotes; see
      beamerinnerthemeNCAR.sty)

  metadata `fineprint: "..."`
      small print under the title block, e.g. an NSF funding statement

  metadata `themeoptions: [brand=ucar, title=light, ...]`
      options for \usetheme{NCAR} (see beamerthemeNCAR.sty)

The filter also loads the theme: it puts this extension's directory on
LaTeX's \input@path and defines \ncarassetdir, so the .sty files, logos
and bundled fonts are used in place -- nothing is copied next to the
document.
]]

if not FORMAT:match("beamer") then
  return {}
end

local slide_level = 2

local function add_frameoption(el, opt)
  local cur = el.attributes["frameoptions"]
  el.attributes["frameoptions"] = (cur and cur ~= "") and (cur .. "," .. opt) or opt
end

local function has_class(el, cls)
  for _, c in ipairs(el.classes) do
    if c == cls then return true end
  end
  return false
end

local function latex(s) return pandoc.RawBlock("latex", s) end

local function inlines_to_latex(inlines)
  local doc = pandoc.Pandoc({ pandoc.Plain(inlines) })
  return (pandoc.write(doc, "latex"):gsub("%s+$", ""))
end

local function is_slide_break(blk)
  return (blk.t == "Header" and blk.level <= slide_level) or blk.t == "HorizontalRule"
end

-- slide footnotes: † / ‡ paragraphs, lifted to the frame's foot
local MARKERS = { ["†"] = true, ["‡"] = true }

local function footnote_marker(blk)
  if blk.t ~= "Para" then return nil end
  local x = blk.content[1]
  while x and (x.t == "Emph" or x.t == "Strong" or x.t == "Span") do x = x.content[1] end
  if not (x and x.t == "Str") then return nil end
  local m = x.text:sub(1, 3)  -- both markers are 3 bytes of UTF-8
  return MARKERS[m] and m or nil
end

-- the inlines without their leading marker (and its space); *† text* keeps
-- its emphasis on the text
local function strip_marker(inlines)
  local x, out = inlines[1], pandoc.Inlines({})
  if x.t == "Str" then
    local rest = x.text:sub(4)
    if rest ~= "" then out:insert(pandoc.Str(rest)) end
    for k = 2, #inlines do
      if not (k == 2 and rest == "" and inlines[k].t == "Space") then out:insert(inlines[k]) end
    end
  else
    local c = x:clone()
    c.content = strip_marker(x.content)
    out:insert(c)
    for k = 2, #inlines do out:insert(inlines[k]) end
  end
  return out
end

-- The footnote is a raw block, so pandoc cannot see a Code inline in it when it
-- decides on [fragile]; fine with \texttt, NOT with `listings: true` (\lstinline).
local function footnote_latex(p)
  return "\\ncarfootnote{" .. footnote_marker(p) .. "}{"
    .. inlines_to_latex(strip_marker(p.content)) .. "}"
end

local function hoist_footnotes(blocks)
  local out, i = pandoc.Blocks({}), 1
  while i <= #blocks do
    local blk = blocks[i]
    out:insert(blk)
    i = i + 1
    if blk.t == "Header" and blk.level == slide_level
        and not has_class(blk, "feature") and not has_class(blk, "closing") then
      local body, notes, tail = pandoc.Blocks({}), pandoc.List({}), pandoc.Blocks({})
      local filter = { Para = function(p) if footnote_marker(p) then notes:insert(p); return {} end end }
      while i <= #blocks and not is_slide_break(blocks[i]) do
        local b = blocks[i]
        if b.t == "Div" and has_class(b, "notes") then
          tail:insert(b)
        elseif footnote_marker(b) then
          notes:insert(b)
        else
          body:insert(pandoc.walk_block(b, filter))
        end
        i = i + 1
      end
      if #notes > 0 then
        out:insert(latex("\\ncarfootnotespring"))
        out:extend(body)
        local tex = pandoc.List({ "\\ncarfootnotespring", "\\begin{ncarfootnotes}" })
        for _, p in ipairs(notes) do tex:insert(footnote_latex(p)) end
        tex:insert("\\end{ncarfootnotes}")
        out:insert(latex(table.concat(tex, "\n")))
      else
        out:extend(body)
      end
      out:extend(tail)
    end
  end
  return out
end

local function header_includes(doc)
  local hi = doc.meta["header-includes"]
  if hi == nil then
    hi = pandoc.List({})
  elseif pandoc.utils.type(hi) ~= "List" then
    hi = pandoc.List({ hi })
  end
  return hi
end

local function load_theme(doc)
  local extdir = pandoc.path.directory(quarto.utils.resolve_path("ncar_branding.sty"))
  if not pandoc.path.is_absolute(extdir) then
    extdir = pandoc.path.join({ pandoc.system.get_working_directory(), extdir })
  end
  if extdir:find("[%s%%#]") then
    quarto.log.warning("ncar-beamer: extension path contains spaces or special "
      .. "characters, which LaTeX's \\input@path cannot handle: " .. extdir)
  end
  local opts = {}
  local to = doc.meta["themeoptions"]
  if to then
    if pandoc.utils.type(to) == "List" then
      for _, o in ipairs(to) do table.insert(opts, pandoc.utils.stringify(o)) end
    else
      table.insert(opts, pandoc.utils.stringify(to))
    end
    doc.meta["themeoptions"] = nil -- consumed here; the template would ignore it
  end
  -- Quarto's own `mathfont:` key (\setmathfont in the template, before the
  -- theme loads) wins over the theme's default math font
  if doc.meta["mathfont"] then
    local set = false
    for _, o in ipairs(opts) do
      if o:match("^%s*mathfont%s*=") then set = true end
    end
    if not set then table.insert(opts, "mathfont=keep") end
  end
  local tex = table.concat({
    "\\makeatletter",
    "\\providecommand\\input@path{}",
    "\\edef\\input@path{\\input@path{" .. extdir .. "/}}",
    "\\makeatother",
    "\\def\\ncarassetdir{" .. extdir .. "/ncar-assets/}",
    "\\usetheme[" .. table.concat(opts, ",") .. "]{NCAR}",
    -- Quarto callouts (tcolorbox) in brand colors; Quarto defines its own
    -- after header-includes, hence \AtBeginDocument
    "\\AtBeginDocument{%",
    "  \\colorlet{quarto-callout-color}{DarkBlue}%",
    "  \\colorlet{quarto-callout-note-color}{NCARBlue}%",
    "  \\colorlet{quarto-callout-note-color-frame}{NCARBlue}%",
    "  \\colorlet{quarto-callout-tip-color}{UCARAquaContrast}%",
    "  \\colorlet{quarto-callout-tip-color-frame}{UCARAquaContrast}%",
    "  \\colorlet{quarto-callout-important-color}{DarkBlue}%",
    "  \\colorlet{quarto-callout-important-color-frame}{DarkBlue}%",
    "  \\colorlet{quarto-callout-warning-color}{BrandOrange}%",
    "  \\colorlet{quarto-callout-warning-color-frame}{BrandOrange}%",
    "  \\colorlet{quarto-callout-caution-color}{BrandOrange}%",
    "  \\colorlet{quarto-callout-caution-color-frame}{BrandOrange}}",
  }, "\n")
  local hi = header_includes(doc)
  hi:insert(1, pandoc.Blocks({ latex(tex) }))
  doc.meta["header-includes"] = hi
end

-- Raw HTML blocks (e.g. an editor modeline comment above the YAML) are
-- dropped by the LaTeX writer, but only after pandoc has already opened an
-- empty frame for them.  Drop them up front.  (Only HTML: quarto uses
-- internal raw formats such as `latex-merge' that must survive.)
function RawBlock(el)
  if el.format:match("^html") then
    return {}
  end
end

-- [text]{.alert} -> \alert{text}
function Span(el)
  if has_class(el, "alert") then
    local out = pandoc.Inlines({ pandoc.RawInline("latex", "\\alert{") })
    out:extend(el.content)
    out:insert(pandoc.RawInline("latex", "}"))
    return out
  end
end

-- Images with an absolute size (e.g. mermaid diagrams, which Quarto includes
-- at their natural size and so ignore fig-width) can run off the slide or
-- into the neighboring column.  Wrap them in pandoc's \pandocbounded, which
-- scales the image down to the current \linewidth / \textheight if needed.
-- (\pandocbounded exists since pandoc 3.2.1, i.e. Quarto >= 1.6; see _extension.yml.)
local function bound_sized_images(doc)
  return doc:walk({
    Image = function(img)
      local w, h = img.attributes["width"], img.attributes["height"]
      if not (w or h) then return nil end -- unsized: pandoc bounds these itself
      if (w and w:match("%%$")) or (h and h:match("%%$")) then return nil end -- relative
      local tex = pandoc.write(pandoc.Pandoc({ pandoc.Plain({ img }) }), "latex")
      return pandoc.RawInline("latex", "\\pandocbounded{" .. tex:gsub("%s+$", "") .. "}")
    end,
  })
end

function Pandoc(doc)
  if PANDOC_WRITER_OPTIONS and PANDOC_WRITER_OPTIONS.slide_level then
    slide_level = PANDOC_WRITER_OPTIONS.slide_level
  end

  doc = bound_sized_images(doc)
  load_theme(doc)

  -- title fine print from metadata
  local fp = doc.meta["fineprint"]
  if fp then
    local ty, text = pandoc.utils.type(fp), nil
    if ty == "Inlines" then
      text = inlines_to_latex(fp)
    elseif ty == "Blocks" then
      text = (pandoc.write(pandoc.Pandoc(fp), "latex"):gsub("%s+$", ""))
    else
      text = pandoc.utils.stringify(fp)
    end
    local hi = header_includes(doc)
    hi:insert(pandoc.Blocks({ latex("\\titlefineprint{" .. text .. "}") }))
    doc.meta["header-includes"] = hi
  end

  local out = pandoc.Blocks({})
  local i, blocks = 1, doc.blocks
  local section, subtitles = 0, pandoc.List({})
  while i <= #blocks do
    local blk = blocks[i]
    if blk.t == "Header" and blk.level == slide_level then
      if has_class(blk, "feature") then
        local bg = blk.attributes["background"] or blk.attributes["background-image"]
        if bg then
          add_frameoption(blk, "ncarbg=" .. bg)
          blk.attributes["background"] = nil
          blk.attributes["background-image"] = nil
        end
        out:insert(blk)
        i = i + 1
      elseif has_class(blk, "closing") then
        -- move the heading into the frame body as the closing headline
        local headline = inlines_to_latex(blk.content)
        add_frameoption(blk, "ncarclosing,plain,noframenumbering")
        blk.content = pandoc.Inlines({})
        out:insert(blk)
        out:insert(latex("\\ncarclosingcontent{" .. headline .. "}{%"))
        i = i + 1
        while i <= #blocks and not is_slide_break(blocks[i]) do
          out:insert(blocks[i])
          i = i + 1
        end
        out:insert(latex("}"))
      else
        out:insert(blk)
        i = i + 1
      end
    elseif blk.t == "Header" and blk.level == 1 and slide_level > 1 then
      -- paragraphs alone between a divider and the next slide: the subtitle
      if not has_class(blk, "unnumbered") then section = section + 1 end
      local j, paras = i + 1, pandoc.List({})
      while j <= #blocks and (blocks[j].t == "Para" or blocks[j].t == "Plain") do
        paras:insert(blocks[j])
        j = j + 1
      end
      if #paras > 0 and (j > #blocks or is_slide_break(blocks[j]))
          and not has_class(blk, "unnumbered") then
        local text = pandoc.List({})
        for k, p in ipairs(paras) do
          if k > 1 then text:insert(pandoc.RawInline("latex", "\\par ")) end
          text:extend(p.content)
        end
        subtitles:insert(latex("\\ncarsectionsubtitle{" .. section .. "}{"
          .. inlines_to_latex(text) .. "}"))
        out:insert(blk)
        i = j
      else
        out:insert(blk)
        i = i + 1
      end
    else
      out:insert(blk)
      i = i + 1
    end
  end
  doc.blocks = hoist_footnotes(out)
  if #subtitles > 0 then
    local hi = header_includes(doc)
    hi:insert(pandoc.Blocks(subtitles))
    doc.meta["header-includes"] = hi
  end
  return doc
end
