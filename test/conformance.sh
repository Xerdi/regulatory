#!/bin/sh
# Builds every case of the PDF conformance matrix and validates it with veraPDF.
#
# A case is one example document, declared with one \DocumentMetadata on the
# commandline, validated against one or more veraPDF flavours. The document
# itself only says \IfDocumentMetadataTF{}{\DocumentMetadata{}}, so a bare build
# is unaffected by any of this.
#
# Expectations:
#   pass   the flavour has to validate
#   fail   the flavour has to NOT validate; a negative case that proves the
#          harness measures what it claims to measure
#   xfail  known to fail on a defect of this package; turn it into pass once the
#          defect is fixed, do not skip it
set -eu

# The suite builds in a directory of its own, so the sources are addressed from
# where this script lives rather than from the working directory.
HERE=$(cd "$(dirname "$0")" && pwd)

COMPILER=${COMPILER:-lualatex --interaction=nonstopmode --shell-escape -cnf-line TEXMFHOME=..}
BIB2GLS=${BIB2GLS:-bib2gls}
# Pinned by digest: a floating tag would move the conformance claim along with
# the validator without anyone noticing.
VERAPDF_IMAGE=${VERAPDF_IMAGE:-verapdf/cli@sha256:d5ee329657cf9bc4b2400392dd54c7d0a0ce9980ff6fa2da5590eebeec007cdb}
# The manual reads this table, so it is kept in the repository: veraPDF is not
# available on CI, and a conformance claim nobody can reproduce is worth nothing.
CONFORMANCE_TABLE=${CONFORMANCE_TABLE:-$HERE/conformance.tex}

TAGGED='testphase={phase-III,title}'

# name | document | \DocumentMetadata options | flavour:expectation,...
#
# The documents differ in what they embed, which is what the A-standards care
# about: md-example embeds nothing, example1-nl embeds a bib file (not a PDF),
# example2-nl embeds another PDF. sign-example embeds nothing either but carries
# two signature fields, which is a kind of annotation the standards make their own
# demands of.
#
# The A-4 case is deliberately untagged. With testphase=phase-III latex-lab hangs
# latex-list-css.html and latex-align-css.html on the catalog as associated
# files, and both A-2 and A-4 require every embedded file to be a PDF/A itself.
# A tagged document can therefore only be A-4f or A-3, which allow any file type,
# and never A-2a or A-4.
CASES="
a2b|md-example|pdfstandard=A-2b|2b:pass
a4|md-example|pdfstandard=A-4|4:pass
a4f-ua2|example2-nl|pdfstandard=A-4f,pdfstandard=UA-2,$TAGGED|4f:pass,ua2:pass
a3a-ua1|example2-nl|pdfstandard=A-3a,pdfstandard=UA-1,$TAGGED|3a:pass,ua1:pass
a3b|example1-nl|pdfstandard=A-3b|3b:xfail
a2b-embedded-nonpdf|example1-nl|pdfstandard=A-2b|2b:fail
a2b-signed|sign-example|pdfstandard=A-2b|2b:xfail
"

# Everything that can change a verdict: the package, the documents, and the matrix
# itself. The hash of it travels with the table, so staleness can be established
# without a validator and without building anything.
inputs_hash() {
    LC_ALL=C cat "$HERE"/../src/*.dtx "$HERE"/../src/*.def "$HERE"/../src/*.ins \
                 "$HERE"/example1.tex "$HERE"/example2.tex "$HERE"/example.md \
                 "$HERE"/example1-nl.tex "$HERE"/example1-en.tex \
                 "$HERE"/example2-nl.tex "$HERE"/example2-en.tex \
                 "$HERE"/md-example.tex "$HERE"/sign-example.tex \
                 "$HERE"/example1.bib "$HERE"/example2.bib \
                 "$HERE"/conformance.sh 2>/dev/null |
    sha256sum | cut -d' ' -f1
}

case "${1:-}" in
    --hash)
        inputs_hash
        exit 0
        ;;
    --check-stale)
        # Cheap: no Docker, no LaTeX, no rebuild. Meant for a pre-commit hook.
        want=$(inputs_hash)
        have=$(sed -n 's/^% inputs //p' "$CONFORMANCE_TABLE" 2>/dev/null)
        [ "$want" = "$have" ] && exit 0
        echo "conformance: $CONFORMANCE_TABLE does not match the current sources" >&2
        exit 1
        ;;
esac

command -v docker >/dev/null 2>&1 || {
    echo "conformance: docker is needed for veraPDF" >&2
    exit 1
}

status=0
results=""
rows=""

for case in $CASES; do
    name=$(echo "$case" | cut -d'|' -f1)
    doc=$(echo "$case" | cut -d'|' -f2)
    meta=$(echo "$case" | cut -d'|' -f3)
    checks=$(echo "$case" | cut -d'|' -f4)
    # One prefix for everything a flavour build writes, so cleaning is unambiguous.
    job="conf-$doc-$name"

    echo "== $name: $doc with \\DocumentMetadata{$meta}"
    # Every jobname needs its own bib2gls run: \GlsXtrLoadResources writes
    # <jobname>.glstex, so reusing the one of the bare build breaks the
    # glossary of a flavour build.
    $COMPILER -jobname="$job" "\\DocumentMetadata{$meta}\\input{$doc}" >"$job.build.log" 2>&1 || true
    $BIB2GLS "$job" >>"$job.build.log" 2>&1 || true
    $COMPILER -jobname="$job" "\\DocumentMetadata{$meta}\\input{$doc}" >>"$job.build.log" 2>&1 || true
    $COMPILER -jobname="$job" "\\DocumentMetadata{$meta}\\input{$doc}" >>"$job.build.log" 2>&1 || true

    if [ ! -f "$job.pdf" ]; then
        echo "   BUILD FAILED, see $job.build.log"
        results="$results\n$name\t-\tBUILD FAILED"
        status=1
        continue
    fi

    for check in $(echo "$checks" | tr ',' ' '); do
        flavour=${check%%:*}
        expected=${check##*:}
        # As the calling user: the container only reads, and anything it does
        # create in the mounted directory would otherwise belong to root and be
        # undeletable by the build.
        # A home directory is named as well: without one the JVM resolves
        # user.home to `?' and veraPDF writes its configuration to a directory
        # of that name in the build directory.
        report=$(docker run --rm --user "$(id -u):$(id -g)" \
                     -e HOME=/tmp -e _JAVA_OPTIONS=-Duser.home=/tmp \
                     -v "$PWD":/w -w /w "$VERAPDF_IMAGE" \
                     -f "$flavour" --format text -v "$job.pdf" 2>&1 || true)
        # The verdict is looked for rather than read off the first line: the JVM
        # announces _JAVA_OPTIONS on stderr before veraPDF says anything.
        verdict=$(echo "$report" | grep -Eo '^(PASS|FAIL)' | head -1)
        rules=$(echo "$report" | sed -n 's/^  *FAIL \(.*\)$/\1/p' | tr '\n' ' ')

        case "$expected:$verdict" in
            pass:PASS|fail:FAIL|xfail:FAIL) outcome="ok" ;;
            xfail:PASS) outcome="XPASS (fixed? make it pass)" ; status=1 ;;
            *) outcome="UNEXPECTED" ; status=1 ;;
        esac
        printf '   %-4s expected %-5s got %-4s  %s\n' "$flavour" "$expected" "$verdict" "$outcome"
        [ -n "$rules" ] && printf '        failed rules: %s\n' "$rules"
        results="$results\n$name\t$flavour\t$expected\t$verdict\t$outcome\t$rules"
        row=$(printf '\\conformancerow{%s}{%s}{%s}{%s}{%s}{%s}' \
                     "$name" "$doc" "$flavour" "$expected" "$verdict" "$(echo $rules)")
        rows="$rows$row
"
    done
done

# The version of the validator belongs with the verdicts: another version is
# another measurement.
version=$(docker run --rm "$VERAPDF_IMAGE" --version 2>/dev/null \
          | sed -n 's/.*veraPDF \([0-9.]*\).*/\1/p' | head -1)
{
    echo "% Generated by test/conformance.sh. Do not edit; run make conformance."
    echo "% inputs $(inputs_hash)"
    printf '%s\n' "\\conformancevalidator{${version:-unknown}}{$VERAPDF_IMAGE}"
    printf '%s\n' "$rows" | sed '/^$/d'
} > "$CONFORMANCE_TABLE"
echo
echo "== wrote $CONFORMANCE_TABLE"

echo
echo "== summary"
printf '%b\n' "$results" | sed '/^$/d' | column -t -s "$(printf '\t')"
exit $status
