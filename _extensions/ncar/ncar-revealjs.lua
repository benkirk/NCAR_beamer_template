--[[
ncar-revealjs.lua -- the NCAR theme's slide furniture for revealjs (HTML) output

The same Markdown as the beamer theme (ncar-beamer.lua):

  # Section
  One paragraph right after the divider heading.
      NCAR Blue divider with the brand waves, a "SECTION n" eyebrow, and the
      paragraph as its subtitle

  ## Thank you! {.closing}
      closing slide on the brand field, the heading as a large headline

  ## Title {.feature background-image="photo.jpg"}
      full-bleed photo (pandoc makes it the slide background; the CSS adds
      the translucent title band and drops the logo)

  ## Title {.brand-dark}
      content slide on Space, white text, the white-reversed logo (HTML only;
      pptx and beamer draw an ordinary slide)

  metadata `themeoptions: [brand=ucar, title=light]`, `titlegraphic:`,
  `fineprint:`, `institute:` -- as for beamer; HTML also reads `autofit=false`

Overflowing content slides shrink their body text to fit (ncar-revealjs.js);
{.no-autofit} or {.scrollable} on a slide opts out.

  ## Title {.center scale="1.4"}
      per-slide layout of the body (everything but the title, notes and
      footnotes), each control independent: .hcenter centers the body block
      across (its text stays left-aligned), .vcenter centers it between the
      title rule and the floor, .center does both (NOT Quarto's .center,
      which moves the title too), scale="S" sizes its text, tables and code
      by S, and .fill grows it until it just fits (HTML only)

Colors, type and layout live in ncar-revealjs.scss; the fonts and logos,
which need url()s relative to their files, in ncar-revealjs.css, attached
here (with the autofit script) as an HTML dependency (Quarto copies it with its resources into
<deck>_files/libs/, or inlines everything under `embed-resources: true`).

The waves are inline SVG drawn in slide pixels (the theme fixes the slide at
1600x900) from the same fitted curves as beamerouterthemeNCAR.sty (see
tools/fit-waves.py); `themeoptions: [waves=false]` drops them from content
slides.
]]

if not FORMAT:match("revealjs") then
  return {}
end

local VERSION = "2.6.0"
local W, H = 1600, 900

-- Brand Guide pp. 17-19; roles as in ncar_branding.sty
local SPACE = "#011837"
local BRANDS = {
  ncar = { primary = "#0057C2", primary_text = "#FFFFFF", secondary = "#42C0FF" },
  ucar = { primary = "#00A2B4", primary_text = SPACE, secondary = "#34E1F4" },
}

local slide_level = 2

local function has_class(el, cls)
  for _, c in ipairs(el.classes) do
    if c == cls then return true end
  end
  return false
end

local function html(s) return pandoc.RawBlock("html", s) end

local function is_slide_break(blk)
  return (blk.t == "Header" and blk.level <= slide_level) or blk.t == "HorizontalRule"
end

-- Slide footnotes: a paragraph that starts with † (or ‡) is an aside.  Every
-- one on a content slide, columns included, moves to the slide's foot, in order, under
-- one short rule (scss); its marker hangs in the margin in the accent color.
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

-- the footnote paragraphs of one slide's blocks, removed from where they stood
local function take_footnotes(blocks)
  local found = pandoc.List({})
  local kept = pandoc.Blocks({})
  local filter = { Para = function(p) if footnote_marker(p) then found:insert(p); return {} end end }
  for _, b in ipairs(blocks) do
    if b.t == "Div" and has_class(b, "notes") then
      kept:insert(b)
    elseif footnote_marker(b) then
      found:insert(b)
    else
      kept:insert(pandoc.walk_block(b, filter))
    end
  end
  return kept, found
end

local function dagger(p)
  local inl = pandoc.Inlines({ pandoc.RawInline("html",
    '<span class="ncar-dagger">' .. footnote_marker(p) .. "</span>") })
  inl:extend(strip_marker(p.content))
  return pandoc.Para(inl)
end

-- Per-slide layout controls.  The body is wrapped in a Div here, before the
-- footnote hoist (which reaches into it), and becomes raw tags afterwards
-- (unwrap_layout), since pandoc turns a Div that starts with a heading into a
-- <section>.  The classes go on the slide; the script and the scss act on them.
local LAYOUT_CLASSES = { hcenter = true, vcenter = true, center = true, fill = true }

local function take_layout(blk)
  local h, v, fill, found = false, false, false, false
  local kept = pandoc.List({})
  for _, c in ipairs(blk.classes) do
    if LAYOUT_CLASSES[c] then
      found = true
      h = h or c == "hcenter" or c == "center"
      v = v or c == "vcenter" or c == "center"
      fill = fill or c == "fill"
    else
      kept:insert(c)
    end
  end
  local scale = blk.attributes["scale"]
  if scale then
    blk.attributes["scale"] = nil
    found = true
    if not tonumber(scale) then
      quarto.log.warning("ncar-revealjs: scale=\"" .. scale .. "\" is not a number; ignored")
      scale = nil
    end
  end
  if not found then return nil end
  blk.classes = kept
  return { h = h, v = v, fill = fill, scale = scale }
end

local function wrap_layout(blocks)
  local out, i = pandoc.Blocks({}), 1
  while i <= #blocks do
    local blk = blocks[i]
    out:insert(blk)
    i = i + 1
    local lay = blk.t == "Header" and blk.level == slide_level
      and not has_class(blk, "feature") and not has_class(blk, "closing") and take_layout(blk)
    if lay then
      blk.classes:insert("ncar-layout")
      if lay.h then blk.classes:insert("ncar-hcenter") end
      if lay.v then blk.classes:insert("ncar-vcenter") end
      if lay.fill then blk.classes:insert("ncar-fill") end
      if lay.scale then blk.attributes["data-ncar-scale"] = lay.scale end
      local body, notes = pandoc.Blocks({}), pandoc.Blocks({})
      while i <= #blocks and not is_slide_break(blocks[i]) do
        local b = blocks[i]
        if b.t == "Div" and has_class(b, "notes") then notes:insert(b) else body:insert(b) end
        i = i + 1
      end
      out:insert(pandoc.Div(body, pandoc.Attr("", { "ncar-body" })))
      out:extend(notes)
    end
  end
  return out
end

local function unwrap_layout(blocks)
  local out = pandoc.Blocks({})
  for _, b in ipairs(blocks) do
    if b.t == "Div" and has_class(b, "ncar-body") then
      out:insert(html('<div class="ncar-body">'))
      out:extend(b.content)
      out:insert(html("</div>"))
    else
      out:insert(b)
    end
  end
  return out
end

-- raw tags, not a Div (see the feature body); before the notes, after the body.
-- Content slides only, as in ncar-beamer.lua: a feature slide's text sits on
-- its panel, and the floor of a closing slide is the brand field.
local function hoist_footnotes(blocks)
  local out, i = pandoc.Blocks({}), 1
  while i <= #blocks do
    local blk = blocks[i]
    out:insert(blk)
    i = i + 1
    if blk.t == "Header" and blk.level == slide_level
        and not has_class(blk, "feature") and not has_class(blk, "closing") then
      local slide = pandoc.Blocks({})
      while i <= #blocks and not is_slide_break(blocks[i]) do
        slide:insert(blocks[i])
        i = i + 1
      end
      local kept, notes = take_footnotes(slide)
      if #notes > 0 then
        local body, tail = pandoc.Blocks({}), pandoc.Blocks({})
        for _, b in ipairs(kept) do
          if b.t == "Div" and has_class(b, "notes") then tail:insert(b) else body:insert(b) end
        end
        out:extend(body)
        out:insert(html('<div class="ncar-footnotes">'))
        for _, p in ipairs(notes) do out:insert(dagger(p)) end
        out:insert(html("</div>"))
        out:extend(tail)
      else
        out:extend(kept)
      end
    end
  end
  return out
end

-- A percentage height resolves against the whole 900-px slide here, so the
-- beamer recipe for a full-width screenshot, {height="72%"}, runs past the
-- bottom.  Map it onto the content height instead: 72% is the 600-px cap the
-- diagrams get, a smaller percentage is proportionally smaller, and nothing
-- exceeds the cap.  Any style the author set is kept.
local CAP, FULL = 600, 72
function Image(el)
  local pct = tonumber((el.attributes.height or ""):match("^([%d.]+)%%$"))
  if not pct then return nil end
  local px = math.min(CAP, CAP * pct / FULL)
  local style = el.attributes.style or ""
  if style ~= "" and not style:match(";%s*$") then style = style .. ";" end
  el.attributes.height = nil
  el.attributes.style = string.format(
    "%s max-height: calc(%.0fpx * var(--ncar-fit, 1)); width: auto;", style, px):gsub("^ ", "")
  return el
end

-- themeoptions: a list or a comma-separated string of key=value
local function theme_options(meta)
  local opts, to = {}, meta["themeoptions"]
  if not to then return opts end
  local items = pandoc.utils.type(to) == "List" and to or { to }
  for _, it in ipairs(items) do
    for kv in pandoc.utils.stringify(it):gmatch("[^,%s]+") do
      local k, v = kv:match("^([^=]+)=(.*)$")
      if k then opts[k] = v else opts[kv] = "true" end
    end
  end
  return opts
end

---------------------------------------------------------------------------
-- brand waves (y runs down here, up in TikZ)
---------------------------------------------------------------------------
-- The brand's three wave lines (tools/fit-waves.py): each is two cubics
-- from the top edge to the bottom edge, as {x, y} fractions of the slide
-- (y down): start, ctrl, ctrl, peak, ctrl, ctrl, end.
local WAVES = {
  { {0.4862, 0.0000}, {0.5087, 0.1976}, {0.6068, 0.4965}, {0.6068, 0.6766}, {0.6068, 0.8741}, {0.5756, 0.9681}, {0.5674, 1.0000} },
  { {0.5138, 0.0000}, {0.5402, 0.1583}, {0.6570, 0.4747}, {0.6570, 0.6423}, {0.6570, 0.8307}, {0.6286, 0.9166}, {0.6000, 1.0000} },
  { {0.5427, 0.0000}, {0.5762, 0.1381}, {0.7073, 0.4410}, {0.7073, 0.6182}, {0.7073, 0.8242}, {0.6639, 0.9245}, {0.6320, 1.0000} },
}
-- where the waves sit on each slide type: the shift of the cover art, whose
-- line 1 starts at 0.49 of the width (the same numbers as the beamer theme)
local SHIFT = { title = 0.20, section = 0.26, content = 0.27 }
local LIGHT_GRAY = "#F1F0EE"

local function n(v) return string.format("%.1f", v) end
local function P(k, i, dx)
  local p = WAVES[k][i]
  return (p[1] + dx) * W, p[2] * H
end
-- x where the tangent at endpoint i (towards control point j) reaches y
local function along(k, i, j, dx, y)
  local xe, ye = P(k, i, dx)
  local xc, yc = P(k, j, dx)
  return xe + (xc - xe) * (y - ye) / (yc - ye)
end
local function pt(x, y) return n(x) .. " " .. n(y) end
local function seg(k, dx, a, b, c)  -- cubic to point c through controls a, b
  return string.format("C %s %s %s", pt(P(k, a, dx)), pt(P(k, b, dx)), pt(P(k, c, dx)))
end

-- Every shape continues past the slide and the field to the left, so
-- letterboxed screens show no cut edge.  Past each end a line follows its
-- tangent for L px, then eases to vertical over M more (the tangents differ,
-- so a longer run would let the lines cross, which the brand forbids) and
-- runs straight on to E.
local E, L, M = 1200, 100, 160
-- past endpoint i (tangent towards control point j), in direction dir:
-- the end of the straight run, the easing control point, and the far end
local function ext(k, i, j, dx, dir)
  local xe, ye = P(k, i, dx)
  local xc, yc = P(k, j, dx)
  local slope = (xc - xe) / (yc - ye)
  local near = pt(xe + slope * dir * L, ye + dir * L)
  local xfar = xe + slope * dir * (L + M)
  return near, pt(xfar, ye + dir * (L + M)), pt(xfar, ye + dir * E)
end
local function top(k, dx) local _, _, far = ext(k, 1, 2, dx, -1) return far end
local function bottom(k, dx) local _, _, far = ext(k, 7, 6, dx, 1) return far end
-- line k from above the slide to below it, and back up
local function down(k, dx)
  local tnear, tc, tfar = ext(k, 1, 2, dx, -1)
  local bnear, bc, bfar = ext(k, 7, 6, dx, 1)
  return string.format("L %s C %s %s %s L %s %s %s L %s C %s %s %s", tfar, tc, tc, tnear,
    pt(P(k, 1, dx)), seg(k, dx, 2, 3, 4), seg(k, dx, 5, 6, 7), bnear, bc, bc, bfar)
end
local function up(k, dx)
  local tnear, tc, tfar = ext(k, 1, 2, dx, -1)
  local bnear, bc, bfar = ext(k, 7, 6, dx, 1)
  return string.format("L %s C %s %s %s L %s %s %s L %s C %s %s %s", bfar, bc, bc, bnear,
    pt(P(k, 7, dx)), seg(k, dx, 6, 5, 4), seg(k, dx, 3, 2, 1), tnear, tc, tc, tfar)
end

-- the slide left of line k
local function field(k, dx, fill)
  return string.format('<path d="M %d %d L %d %d %s Z" fill="%s"/>',
    -E, H + E, -E, -E, down(k, dx), fill)
end
-- between lines k and m
local function band(k, m, dx, fill, opacity)
  return string.format('<path d="M %s %s %s Z" fill="%s" fill-opacity="%s"/>',
    top(k, dx), down(k, dx), up(m, dx), fill, opacity)
end
local function lines(dx, stroke)
  local out = {}
  for k = 1, 3 do
    out[k] = string.format('<path d="M %s %s" fill="none" stroke="%s" stroke-width="2.4"/>',
      top(k, dx), down(k, dx), stroke)
  end
  return table.concat(out)
end

local function svg(body)
  return string.format('<svg class="ncar-waves" viewBox="0 0 %d %d" '
    .. 'preserveAspectRatio="none" aria-hidden="true" focusable="false">%s</svg>', W, H, body)
end

-- title and closing slides without a photo, and section dividers: the lines
-- with the brand's translucent bands between them (Brand Guide p24)
local function waves(c, dx)
  return svg(band(1, 2, dx, c.secondary, 0.18) .. band(2, 3, dx, c.secondary, 0.10)
    .. lines(dx, c.secondary))
end

-- title slide with `titlegraphic:`, as the brand's cover: the photo fills the
-- right 52%; the opaque field runs to line 2 and a translucent band to line 3.
-- A plain <img> behind the svg, not an svg <image>: pandoc's embed-resources
-- inlines the former only.
local function photo_waves(c, fieldcolor, src)
  return string.format('<img class="ncar-title-photo-img" src="%s" alt="">', src)
    .. svg(field(2, 0, fieldcolor) .. band(2, 3, 0, fieldcolor, 0.65) .. lines(0, c.secondary))
end

-- content slides: the faint lines of the brand's content slides (p26)
local function content_waves()
  return svg(lines(SHIFT.content, LIGHT_GRAY))
end

---------------------------------------------------------------------------
-- document setup
---------------------------------------------------------------------------
local function add_dependency()
  local res = {}
  for _, f in ipairs({ "Regular", "Italic", "SemiBold", "Bold", "BoldItalic" }) do
    table.insert(res, { name = "Poppins-" .. f .. ".ttf",
      path = "ncar-assets/fonts/Poppins/Poppins-" .. f .. ".ttf" })
  end
  for _, f in ipairs({ "NSF-NCAR_Logo_FullColor_RGB.png", "NSF-NCAR_Logo_Color-White_RGB.png",
                       "UCAR-Logo_Color_RGB.svg", "UCAR-Logo_White_RGB.svg" }) do
    table.insert(res, { name = f, path = "ncar-assets/web/" .. f })
  end
  quarto.doc.add_html_dependency({
    name = "ncar-revealjs",
    version = VERSION,
    stylesheets = { "ncar-revealjs.css" },
    scripts = { "ncar-revealjs.js" },
    resources = res,
  })
end

-- merge key/values into the title-slide-attributes map, keeping the user's
local function title_slide_attributes(meta, kv)
  local tsa = meta["title-slide-attributes"] or {}
  for k, v in pairs(kv) do
    if tsa[k] == nil then tsa[k] = v end
  end
  meta["title-slide-attributes"] = tsa
end

function Pandoc(doc)
  if PANDOC_WRITER_OPTIONS and PANDOC_WRITER_OPTIONS.slide_level then
    slide_level = PANDOC_WRITER_OPTIONS.slide_level
  end
  local meta = doc.meta
  local opts = theme_options(meta)

  local brand = opts.brand or "ncar"
  if brand == "ncarucar" then
    quarto.log.warning("ncar-revealjs: no web copy of the NSF NCAR-UCAR lockup yet; "
      .. "using the NSF NCAR logo (brand=ncarucar)")
  elseif not BRANDS[brand] then
    quarto.log.warning("ncar-revealjs: unknown brand=" .. brand .. "; using brand=ncar")
    brand = "ncar"
  end
  local c = BRANDS[brand] or BRANDS.ncar
  local light = (opts.title == "light")
  local titlefield = light and "#FFFFFF" or c.primary
  local content_art = opts.waves ~= "false" and content_waves() or nil

  add_dependency()
  quarto.doc.include_text("in-header", string.format(
    "<script>document.documentElement.classList.add('ncar-brand-%s','ncar-title-%s'%s)</script>",
    brand == "ucar" and "ucar" or "ncar", light and "light" or "dark",
    opts.autofit == "false" and ",'ncar-no-autofit'" or ""))

  -- title slide: brand field (or white), waves or the photo
  title_slide_attributes(meta, { ["data-background-color"] = titlefield })
  local tg = meta["titlegraphic"]
  local art = tg and photo_waves(c, titlefield, pandoc.utils.stringify(tg)) or waves(c, SHIFT.title)
  meta["ncar-title-art"] = pandoc.RawInline("html", art)
  meta["ncar-title-class"] = light and "" or " ncar-field"

  local out = pandoc.Blocks({})
  local i, blocks, section = 1, wrap_layout(doc.blocks), 0
  while i <= #blocks do
    local blk = blocks[i]
    if blk.t == "Header" and blk.level == 1 and slide_level > 1 then
      blk.classes:extend({ "ncar-section", "ncar-field" })
      blk.attributes["data-background-color"] = c.primary
      if not has_class(blk, "unnumbered") then
        section = section + 1
        blk.attributes["data-ncar-section"] = tostring(section)
      end
      out:insert(blk)
      out:insert(html(waves(c, SHIFT.section)))
      i = i + 1
      -- paragraphs alone between the divider and the next slide: the subtitle
      local j, paras = i, pandoc.List({})
      while j <= #blocks and (blocks[j].t == "Para" or blocks[j].t == "Plain") do
        paras:insert(blocks[j])
        j = j + 1
      end
      if #paras > 0 and (j > #blocks or is_slide_break(blocks[j])) then
        out:insert(pandoc.Div(paras, pandoc.Attr("", { "ncar-subtitle" })))
        i = j
      end
    elseif blk.t == "Header" and blk.level == slide_level and has_class(blk, "closing") then
      blk.attributes["data-background-color"] = titlefield
      if not light then blk.classes:insert("ncar-field") end
      out:insert(blk)
      out:insert(html(waves(c, SHIFT.title)))
      i = i + 1
    elseif blk.t == "Header" and blk.level == slide_level and has_class(blk, "feature") then
      -- the body goes on a translucent panel over the photo; Space under the
      -- photo so reveal flags the slide dark (white slide number), and a
      -- missing photo is not white-on-white
      if not blk.attributes["data-background-color"] and not blk.attributes["background-color"] then
        blk.attributes["data-background-color"] = SPACE
      end
      out:insert(blk)
      i = i + 1
      local body, notes = pandoc.Blocks({}), pandoc.Blocks({})
      while i <= #blocks and not is_slide_break(blocks[i]) do
        local b = blocks[i]
        if b.t == "Div" and has_class(b, "notes") then notes:insert(b) else body:insert(b) end
        i = i + 1
      end
      -- raw tags, not a Div: pandoc turns a Div that starts with a heading
      -- into a <section>, which reveal would count as a slide of its own
      if #body > 0 then
        out:insert(html('<div class="ncar-feature-body">'))
        out:extend(body)
        out:insert(html('</div>'))
      end
      out:extend(notes)
    elseif blk.t == "Header" and blk.level == slide_level and has_class(blk, "brand-dark") then
      blk.attributes["data-background-color"] = SPACE
      blk.classes:insert("ncar-field")
      out:insert(blk)
      i = i + 1
    else
      out:insert(blk)
      i = i + 1
      -- (not over a slide's own background image: the waves sit above
      -- reveal's background layer)
      if content_art and blk.t == "Header" and blk.level == slide_level
          and not blk.attributes["background"] and not blk.attributes["background-image"]
          and not blk.attributes["data-background-image"] then
        out:insert(html(content_art))
      end
    end
  end
  doc.blocks = unwrap_layout(hoist_footnotes(out))
  return doc
end
