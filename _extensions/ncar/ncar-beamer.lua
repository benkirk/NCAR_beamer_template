--[[
ncar-beamer.lua -- Markdown sugar for the NCAR beamer theme (beamer output only)

  ## Title {.feature background="photo.jpg"}
      full-bleed photo frame (-> \begin{frame}[ncarbg=photo.jpg])

  ## Thank you! {.closing}
      closing frame on the brand field; the heading becomes the large
      headline and the slide's content sits beneath it

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

-- [text]{.alert} -> \alert{text}
function Span(el)
  if has_class(el, "alert") then
    local out = pandoc.Inlines({ pandoc.RawInline("latex", "\\alert{") })
    out:extend(el.content)
    out:insert(pandoc.RawInline("latex", "}"))
    return out
  end
end

function Pandoc(doc)
  if PANDOC_WRITER_OPTIONS and PANDOC_WRITER_OPTIONS.slide_level then
    slide_level = PANDOC_WRITER_OPTIONS.slide_level
  end

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
    else
      out:insert(blk)
      i = i + 1
    end
  end
  doc.blocks = out
  return doc
end
