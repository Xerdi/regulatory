#!/usr/bin/env bash

#
# %   ${PROJECT_NAME}
# %   Copyright (C) 2023  ${USER}
# %
# %   This program is free software: you can redistribute it and/or modify
# %   it under the terms of the GNU General Public License as published by
# %   the Free Software Foundation, either version 3 of the License, or
# %   (at your option) any later version.
# %
# %   This program is distributed in the hope that it will be useful,
# %   but WITHOUT ANY WARRANTY; without even the implied warranty of
# %   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# %   GNU General Public License for more details.
# %
# %   You should have received a copy of the GNU General Public License
# %   along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#

latexmk -c example1
latexmk -c example2
latexmk -c regulatory

pdflatex example1
bib2gls example1
pdflatex example2
bib2gls example2
pdflatex example1
pdflatex example2
lualatex regulatory
bib2gls regulatory
lualatex regulatory
lualatex regulatory
lualatex regulatory