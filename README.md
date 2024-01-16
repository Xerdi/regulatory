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

Afterward execute `update-texmf` with root permissions.
It can be validated by the output of: `kpsewhich -var-value TEXMFAUXTREES`.
## Documentation
The documentation is available in Dutch and English and will be included in every release.
See the [releases page](https://github.com/Xerdi/regulatory/releases) for the PDF files.

For more information on building all documentation, see [Makefile](Makefile) and [doc/Makefile](doc/Makefile) in this project.

## License
This project is licensed under the LPPL version 1.3c and maintained by Erik Nijenhuis.
See [LICENSE.txt](LICENSE.txt) for more information.
