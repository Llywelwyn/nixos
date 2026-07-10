-- stylua: ignore start
local p = {
  none   = "NONE",
  white  = "#ffffff", -- loudest: titles, errors, current match
  fg     = "#e0e0e0", -- normal text
  dim    = "#8a8a8a", -- comments, line numbers, punctuation
  sel    = "#404040", -- visual selection, matchparen
  subtle = "#2c2c2c", -- cursorline, diff line bg
  panel  = "#1e1e1e", -- pmenu, floats, statusline
  bg     = "#121212",
  black  = "#0a0a0a",
}

local function l(name) return { link = name } end

local highlights = {
    -- Core UI
    Normal                   = { fg = p.fg, bg = p.bg },
    NormalNC                 = l("Normal"),
    NormalFloat              = { fg = p.fg, bg = p.panel },
    Visual                   = { fg = p.none, bg = p.sel },
    VisualNOS                = { fg = p.fg, bg = p.none },
    FloatBorder              = { fg = p.dim, bg = p.panel },
    WinSeparator             = { fg = p.subtle },

    -- Cursor / lines
    Cursor                   = { fg = p.bg, bg = p.white },
    CursorIM                 = l("Cursor"),
    lCursor                  = l("Cursor"),
    CursorLine               = { bg = p.subtle },
    ColorColumn              = l("CursorLine"),
    CursorColumn             = l("CursorLine"),
    CursorLineNr             = { fg = p.white, bold = true },

    -- Gutter
    Folded                   = { fg = p.dim, bg = p.none, italic = true },
    LineNr                   = { fg = p.dim, bg = p.none },
    NonText                  = { fg = p.sel, bg = p.none },
    SpecialKey               = l("NonText"),

    -- Menus / popups
    Pmenu                    = { fg = p.fg, bg = p.panel },
    PmenuSel                 = { fg = p.white, bg = p.sel, bold = true },
    PmenuSbar                = { fg = p.none, bg = p.panel },
    PmenuThumb               = { fg = p.none, bg = p.dim },
    WildMenu                 = { fg = p.bg, bg = p.fg, bold = true },
    Terminal                 = l("Pmenu"),

    -- Tabs
    TabLine                  = l("LineNr"),
    TabLineSel               = { fg = p.white, bg = p.none, bold = true },
    TabLineFill              = { fg = p.none, bg = p.black },

    -- Bars
    WinBar                   = { fg = p.fg, bg = p.bg, bold = true },
    WinBarNC                 = { fg = p.dim, bg = p.bg },

    -- Status
    StatusLine               = { fg = p.fg, bg = p.panel },
    StatusLineNC             = { fg = p.dim, bg = p.panel },

    -- Search / match: reverse video is the loudest thing in the scheme
    IncSearch                = { fg = p.bg, bg = p.white, bold = true },
    CurSearch                = l("IncSearch"),
    Search                   = { fg = p.bg, bg = p.dim },
    QuickFixLine             = { fg = p.white, bg = p.subtle, bold = true },
    MatchParen               = { fg = p.white, bg = p.sel, bold = true },

    -- Diff: added = bright/bold, removed = dim/strikethrough, changed = underline
    DiffAdd                  = { fg = p.white, bg = p.subtle, bold = true },
    DiffChange               = { fg = p.none, bg = p.subtle },
    DiffDelete               = { fg = p.dim, bg = p.black, strikethrough = true },
    DiffText                 = { fg = p.bg, bg = p.fg, bold = true },
    DiffAdded                = { fg = p.white, bold = true },
    DiffNewFile              = l("DiffAdded"),
    DiffRemoved              = { fg = p.dim, strikethrough = true },
    DiffChanged              = { fg = p.fg, underline = true },
    DiffFile                 = l("DiffChanged"),
    DiffOldFile              = { fg = p.dim, italic = true },
    DiffLine                 = { fg = p.dim },
    DiffIndexLine            = { fg = p.dim },

    -- Messages
    Title                    = { fg = p.white, bold = true },
    ErrorMsg                 = { fg = p.white, bg = p.none, bold = true, reverse = true },
    WarningMsg               = { fg = p.white, bg = p.none, bold = true },
    Question                 = { fg = p.fg, bg = p.none, italic = true },

    -- Spell
    SpellBad                 = { undercurl = true },
    SpellCap                 = l("SpellBad"),
    SpellLocal               = l("SpellBad"),
    SpellRare                = l("SpellBad"),

    -- Syntax: everything reads at fg; styles carry role, dim recedes.
    Comment                  = { fg = p.dim, bg = p.none, italic = true },
    SpecialComment           = l("Comment"),
    Ignore                   = l("Comment"),
    Todo                     = { fg = p.white, bg = p.none, bold = true, italic = true },
    Constant                 = { fg = p.fg, bg = p.none },
    String                   = { fg = p.white, bg = p.none },
    Character                = l("String"),
    Number                   = { fg = p.white, bg = p.none },
    Float                    = l("Number"),
    Boolean                  = { fg = p.fg, bg = p.none, bold = true },
    Identifier               = { fg = p.fg, bg = p.none },
    Delimiter                = { fg = p.dim, bg = p.none },
    Function                 = { fg = p.white, bg = p.none, bold = true },
    Statement                = { fg = p.fg, bg = p.none, bold = true },
    Conditional              = l("Statement"),
    Repeat                   = l("Statement"),
    Label                    = l("Statement"),
    Exception                = l("Statement"),
    Include                  = l("Statement"),
    Define                   = l("Statement"),
    Tag                      = l("Statement"),
    Operator                 = { fg = p.white, bg = p.none, bold = true },
    Keyword                  = { fg = p.fg, bg = p.none, bold = true },
    PreProc                  = { fg = p.fg, bg = p.none, bold = true, italic = true },
    Macro                    = l("PreProc"),
    PreCondit                = l("PreProc"),
    Type                     = { fg = p.white, bg = p.none, bold = true },
    StorageClass             = l("Type"),
    Structure                = l("Type"),
    Typedef                  = l("Type"),
    Special                  = { fg = p.white, bg = p.none },
    SpecialChar              = { fg = p.white, bg = p.none, bold = true },
    Underlined               = { fg = p.fg, bg = p.none, underline = true },
    Debug                    = { fg = p.dim, bg = p.none },
    Conceal                  = { fg = p.dim, bg = p.none },
    Directory                = { fg = p.white, bg = p.none, bold = true },

    -- Diagnostics: severity by weight + distinct underline shapes
    DiagnosticError          = { fg = p.white, bold = true },
    DiagnosticWarn           = { fg = p.fg },
    DiagnosticInfo           = { fg = p.dim },
    DiagnosticHint           = { fg = p.dim, italic = true },
    DiagnosticUnderlineError = { sp = p.white, undercurl = true },
    DiagnosticUnderlineWarn  = { sp = p.fg, underline = true },
    DiagnosticUnderlineInfo  = { sp = p.dim, underdashed = true },
    DiagnosticUnderlineHint  = { sp = p.dim, underdotted = true },

    -- Lsp UI
    LspInlayHint             = l("Comment"),
    LspCodeLens              = { fg = p.sel },
    LspCodeLensSeparator     = l("LspCodeLens"),
    LspReferenceText         = { fg = p.none, bg = p.subtle },
    LspReferenceRead         = l("LspReferenceText"),
    LspReferenceWrite        = { fg = p.none, bg = p.subtle, underline = true },

    -- Lsp captures
    ["@lsp.typemod.selfKeyword.defaultLibrary"] = { fg = p.fg, bold = true, italic = true },
    ["@lsp.type.parameter"]                     = l("Identifier"),
    ["@lsp.type.variable"]                      = l("Identifier"),
    ["@lsp.typemod.variable.defaultLibrary"]    = l("Identifier"),
    ["@lsp.typemod.enumMember.defaultLibrary"]  = l("Constant"),
    ["@lsp.typemod.variable.readonly"]          = l("Constant"),
    ["@lsp.type.operator"]                      = l("Operator"),
    ["@lsp.type.property"]                      = l("Operator"),
    ["@lsp.type.keyword"]                       = l("Keyword"),
    ["@lsp.type.macro"]                         = l("PreProc"),
    ["@lsp.type.builtinType"]                   = l("Type"),
    ["@lsp.typemod.function.defaultLibrary"]    = l("Function"),
    ["@lsp.typemod.function.global"]            = l("Function"),
    ["@lsp.typemod.method.defaultLibrary"]      = l("Function"),
    ["@lsp.typemod.method.reference"]           = l("Function"),
    ["@lsp.typemod.method.trait"]               = l("Function"),
}
-- stylua: ignore end

if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("hi clear")
  vim.cmd.syntax("reset")
end

vim.o.background = "dark"
vim.o.termguicolors = true
vim.g.colors_name = "mono"

for name, value in pairs(highlights) do
  vim.api.nvim_set_hl(0, name, value)
end
