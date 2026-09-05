# Regulatory
![CTAN Version](https://img.shields.io/ctan/v/regulatory)

A LaTeX package which provides macro's for crafting regulatory documents.

## Installation
A fresh clone holds no package files: everything in [tex](tex) is generated from the
sources in [src](src), so run `make generate` first.

In order to install this package the `texmf` tree has to be copied to a directory LaTeX will search in.
Consult `tlmgr conf texmf TEXMFHOME` to get any ideas of where that should be.

If it's favored to keep this tree separate from other LaTeX trees one can add a configuration to `/etc/texmf/texmf.d` which adds a TEXMF AUX TREE (Debian and derivatives only).
This can be useful when you need to change the source and/or push changes with Git.

```bash
TEXMFAUXTREES=$HOME/src/regulatory/texmf,
```
*/etc/texmf/texmf.d/01xerdi.cnf*

Afterward execute `update-texmf` with root permissions.
It can be validated by the output of: `kpsewhich -var-value TEXMFAUXTREES`.
## Sources
The package is written as a set of `.dtx` files in the [src](src) directory:

| File | Generates | Contents |
| --- | --- | --- |
| `regulatory-struct.dtx` | `regulatory.sty`, `regulatory-struct.sty` | the bundle wrapper, the package options, articles, paragraphs and lists |
| `regulatory-defs.dtx` | `regulatory-defs.sty` | the definition lists, in four routes: `bib2gls`, a glossaries file, `\newdefinition` in the document, or written out by hand |
| `regulatory-ref.dtx` | `regulatory-ref.sty` | the `\rref`, `\nref` and `\aref` families, the conjunctions and the language mechanism |
| `regulatory-attachments.dtx` | `regulatory-attachments.sty` | interdocument references and PDF attachments |
| `regulatory-md.dtx` | `regulatory-md.sty` | the Markdown renderers, loaded as soon as `markdown` is |
| `regulatory-html.dtx` | `regulatory.4ht` | the `tex4ht` configuration, for HTML output |

Loading `regulatory` loads the first four modules; each of them can be loaded on its own as well,
where `regulatory-attachments` requires `regulatory-ref`, which requires `regulatory-struct`.
The fourth, `regulatory-md`, is pulled in by a hook whenever the `markdown` package is loaded.

Run `make generate` to write all of them into the [tex](tex) directory with `docstrip`,
or `make build-docs` to generate the package and both manuals.
## Translations
Every language has its own definition file `src/regulatory-<language>.def`, comparable to
the `fc-<language>.def` files of `fmtcount`. Those are written by hand rather than
generated, so a translator never has to open a `.dtx` file: copy
`src/regulatory-english.def` to `src/regulatory-<language>.def`, translate the right hand
side of every `\DeclareTranslation`, and `make generate` puts it next to the package.

The files are literate all the same -- comments in `doc`'s markup, code in
`macrocode` -- so they are printed in the language support chapter of the manual.

## HTML
`tex4ht` carries no configuration for this package, so this one ships its own, generated
from `src/regulatory-html.dtx` into `tex/regulatory.4ht` along with the rest. Without
it a conversion with `make4ht` succeeds and produces a document with no headings and no
sections at all; the manual's *HTML* chapter has the measurements.

## Tests
The example documents live in [test](test). They are the input of the appendix of the
manual, which lists them, refers to their articles and definitions, and attaches their
PDF files, so `make build-docs` builds them along the way.

`make test` runs two suites, both of which need nothing beyond a TeX installation:

```bash
make test              # both of the below
make test-engines      # every example through lualatex and pdflatex
make test-engines ENGINES=lualatex
make test-html         # one example through make4ht
```

The HTML test counts the `<section>` and `<h1>`..`<h6>` elements in the output. Without
`regulatory.4ht` the conversion still succeeds and produces zero of both, so counting them
is the only way to see that the configuration was found and applied.

The examples are built against TeX Live plus the [tex](tex) directory of this project
only, so a personal `texmf` tree cannot make a test pass or fail on its own.

### PDF conformance

`make conformance` builds the same examples once per PDF standard and validates them with
[veraPDF](https://verapdf.org/) in Docker (image pinned by digest, so the validator cannot
shift the claim under you). No extra example files: the standard is declared on the
commandline, and the documents only say `\IfDocumentMetadataTF{}{\DocumentMetadata{}}`, so
a bare build is unaffected.

It writes [test/conformance.tex](test/conformance.tex), which is **kept in the repository**
and read by the manual. veraPDF is not on CI, so the verdicts have to travel with the
sources; the manual's *Tests* chapter explains the cases, the standards that are out of
reach, and why one case has to fail.

A table in git can go stale, so two checks guard it:

* `make conformance-stale` compares a hash of the sources the table was made from against
  the sources as they are. It costs milliseconds -- no Docker, no LaTeX, no rebuild.
* `make conformance-check` rebuilds and revalidates everything and fails on any difference
  in the verdicts themselves. It takes minutes and needs Docker.

`make install-hooks` points `core.hooksPath` at [.githooks](.githooks), whose pre-commit
hook runs the cheap one whenever a package source or an example is staged, and tells you to
run `make conformance` when it trips. Regenerating stays a deliberate act: a hook that takes
minutes is a hook people disable.

## Documentation
The documentation is available in Dutch and English and will be included in every release.
See the [releases page](https://github.com/Xerdi/regulatory/releases) for the PDF files.

For more information on building all documentation, see [Makefile](Makefile) and [doc/Makefile](doc/Makefile) in this project.

## License
This project is licensed under the LPPL version 1.3c and maintained by Erik Nijenhuis.
See [LICENSE.txt](LICENSE.txt) for more information.
