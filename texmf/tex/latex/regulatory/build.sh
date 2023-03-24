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

set -e

sty2dtx --author "Erik Nijenhuis" --description "Xerdi's Regulatory Package" --email erik@xerdi.com -D --version 0.0.1 -i regulatory.ins -O --filebase regulatory < regulatory.sty > regulatory.dtx
lualatex regulatory.dtx
makeindex -s gind.ist regulatory
lualatex regulatory.dtx
