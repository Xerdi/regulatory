--- \subsection{\translation{Markdown syntax extension}{Markdown syntaxuitbreiding}}
---
--- \package{markdown} lets a document add rules to the grammar of its reader. This file adds one, and it
--- exists because of a limit that has no way around it in Markdown itself: an identifier can be attached
--- to a heading and to a bracketed span, and a bracketed span may not contain another span or a link
--- written with brackets. A paragraph that carries a label and cites a definition therefore cannot be
--- written as one span, and the label has to be pushed onto the opening words of the sentence.
---
--- With this extension the identifier stands on its own, before the text it labels:
---
--- \begin{lstlisting}[style=md]
--- 1. {#lid:lorem} Een [persoonsgegeven](#pg) wordt verwerkt, zie <#lid:eerder>.
--- \end{lstlisting}
---
--- What is added is syntax, not typesetting: a renderer decides how a construct that the reader already
--- recognises is set, and no renderer can make the reader recognise something new. The extension is read
--- by \package{markdown} itself, in Lua, before any of that.
---
--- The interface is a table with three fields. Both versions are checked, and \texttt{grammar\_version}
--- for equality rather than for a lower bound, so an update of \package{markdown} that changes its
--- grammar makes this file an error instead of a surprise.
local regulatory_syntax = {
  api_version = 2,
  grammar_version = 4,

--- \texttt{finalize\_grammar} is handed the reader, whose grammar can be added to. The pattern is an
--- identifier between braces, spelled the way Pandoc spells one, and what it produces is a call of a
--- renderer that this bundle defines in \package{regulatory-md}.
---
--- The characters allowed in an identifier are the ones a label of this bundle is made of: letters,
--- digits, and the punctuation that separates a type from a name, \texttt{art:lorem} and
--- \texttt{ex2-lid:lorem}.
  finalize_grammar = function(reader)
    local labelchar = lpeg.R("az", "AZ", "09") + lpeg.S(":.-_")
    local label = lpeg.P("{#") * lpeg.C(labelchar^1) * lpeg.P("}")
      / function(identifier)
          return {"\\markdownRendererRegulatoryLabel{", identifier, "}"}
        end

--- The rule is spliced in front of the one that reads links and emphasis, so that a brace opening an
--- identifier is seen before anything else can claim it. A brace is not a character the reader stops at
--- on its own, which is what the second call says: without it the brace would be swallowed by the run of
--- ordinary text around it and the pattern would never be tried.
---
--- Only \verb|{#| starts the pattern, so a brace anywhere else in the text is left alone.
    reader.insert_pattern("Inline before LinkAndEmph", label, "RegulatoryLabel")
    reader.add_special_character("{")
  end
}

return regulatory_syntax
