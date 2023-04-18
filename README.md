# Regulatory

A LaTeX package which provides macro's for crafting regulatory documents.

## Installation
In order to install this package the `texmf` tree has to be copied to a directory LaTeX will search in.
Consult `tlmgr conf texmf TEXMFHOME` to get any ideas of where that should be.

If it's favored to keep this tree separate from other LaTeX trees one can add a configuration to `/etc/texmf/texmf.d` which adds a TEXMF AUX TREE (Debian and derivatives only).
This can be useful when you need to change the source and/or push changes with Git.

```bash
TEXMFAUXTREES=$HOME/src/regulatory/texmf,
```
*/etc/texmf/texmf.d/01xerdi.cnf*

## Documentation
The documentation has yet to be translated from Dutch to English.
Make sure to install fonts 'Prompt' and 'Jetbrains Mono'.
