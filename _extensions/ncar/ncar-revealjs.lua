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

Colors, type and layout live in ncar-revealjs.scss; the fonts and logos,
which need url()s relative to their files, in ncar-revealjs.css, attached
here (with the autofit script) as an HTML dependency (Quarto copies it with its resources into
<deck>_files/libs/, or inlines everything under `embed-resources: true`).

The waves are inline SVG drawn in slide pixels (the theme fixes the slide at
1600x900), ported from \ncar@curve & co. in beamerouterthemeNCAR.sty.
]]

if not FORMAT:match("revealjs") then
  return {}
end

local VERSION = "2.1.0"
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
local function n(v) return string.format("%.1f", v) end

-- S-curve from the top edge at x (fraction of the width) to the bottom.
-- Every shape continues straight up and down past the slide (by E) and the
-- field to the left, so letterboxed screens show no cut edge.
local E = 1200
local function curve(x)
  return string.format("C %s %s %s %s %s %s",
    n((x - 0.02) * W), n(0.38 * H), n((x + 0.16) * W), n(0.55 * H), n((x + 0.10) * W), n(H))
end
local function curve_back(x)
  return string.format("C %s %s %s %s %s %s",
    n((x + 0.16) * W), n(0.55 * H), n((x - 0.02) * W), n(0.38 * H), n(x * W), "0")
end
-- down the curve at x, from above the slide to below it
local function down(x)
  return string.format("L %s 0 %s L %s %d", n(x * W), curve(x), n((x + 0.10) * W), H + E)
end
local function up(x)
  return string.format("L %s %d L %s %d %s L %s %d", n((x + 0.10) * W), H + E, n((x + 0.10) * W), H,
    curve_back(x), n(x * W), -E)
end

local function field(x, fill)
  return string.format('<path d="M %d %d L %d %d L %s %d %s Z" fill="%s"/>',
    -E, H + E, -E, -E, n(x * W), -E, down(x), fill)
end
local function band(x0, x1, fill, opacity)
  return string.format('<path d="M %s %d %s %s Z" fill="%s" fill-opacity="%s"/>',
    n(x0 * W), -E, down(x0), up(x1), fill, opacity)
end
local function line(x, stroke)
  return string.format('<path d="M %s %d %s" fill="none" stroke="%s" stroke-width="1.6"/>',
    n(x * W), -E, down(x), stroke)
end

local function svg(body)
  return string.format('<svg class="ncar-waves" viewBox="0 0 %d %d" '
    .. 'preserveAspectRatio="none" aria-hidden="true" focusable="false">%s</svg>', W, H, body)
end

-- title and closing slides without a photo; section dividers further right
local function waves(c, at)
  return svg(band(at, at + 0.08, c.secondary, 0.18) .. band(at + 0.08, at + 0.18, c.secondary, 0.10)
    .. line(at + 0.04, c.secondary) .. line(at + 0.14, c.secondary))
end

-- title slide with `titlegraphic:`: the photo fills the right 52%, and the
-- opaque field (curve at 0.56) and a translucent band cover its left edge.
-- A plain <img> behind the svg, not an svg <image>: pandoc's embed-resources
-- inlines the former only.
local function photo_waves(c, fieldcolor, src)
  local x = 0.56
  return string.format('<img class="ncar-title-photo-img" src="%s" alt="">', src)
    .. svg(band(x, x + 0.04, fieldcolor, 0.55) .. field(x, fieldcolor)
      .. line(0.59, c.secondary) .. line(0.625, c.secondary))
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

  add_dependency()
  quarto.doc.include_text("in-header", string.format(
    "<script>document.documentElement.classList.add('ncar-brand-%s','ncar-title-%s'%s)</script>",
    brand == "ucar" and "ucar" or "ncar", light and "light" or "dark",
    opts.autofit == "false" and ",'ncar-no-autofit'" or ""))

  -- title slide: brand field (or white), waves or the photo
  title_slide_attributes(meta, { ["data-background-color"] = titlefield })
  local tg = meta["titlegraphic"]
  local art = tg and photo_waves(c, titlefield, pandoc.utils.stringify(tg)) or waves(c, 0.66)
  meta["ncar-title-art"] = pandoc.RawInline("html", art)
  meta["ncar-title-class"] = light and "" or " ncar-field"

  local out = pandoc.Blocks({})
  local i, blocks, section = 1, doc.blocks, 0
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
      out:insert(html(waves(c, 0.72)))
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
      out:insert(html(waves(c, 0.66)))
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
    end
  end
  doc.blocks = out
  return doc
end
