#!/usr/bin/env python3
"""
scrub_reference_docs.py

Make a publishable copy of a pandoc reference document.

A reference .docx is used by pandoc for its style definitions only. The body
text is ignored at render time, but it is still in the file, and these were
built from real manuscripts. This replaces every run of visible text with
Lorem Ipsum and clears the document properties, while leaving styles.xml,
numbering.xml, settings.xml, and the theme byte-identical, because those are
the parts pandoc actually reads.

Usage:
    scrub_reference_docs.py <in.docx> <out.docx>

Paragraph and run structure is preserved, so every style still appears in the
output and still demonstrates its own formatting. Field codes, page numbers,
and footers are left alone.
"""

import re
import shutil
import sys
import zipfile

LOREM = (
    "lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod "
    "tempor incididunt ut labore et dolore magna aliqua ut enim ad minim "
    "veniam quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
    "commodo consequat duis aute irure dolor in reprehenderit in voluptate "
    "velit esse cillum dolore eu fugiat nulla pariatur excepteur sint "
    "occaecat cupidatat non proident sunt in culpa qui officia deserunt "
    "mollit anim id est laborum"
).split()

# Parts pandoc reads for formatting. Never modified.
PRESERVE = {
    "word/styles.xml",
    "word/numbering.xml",
    "word/settings.xml",
    "word/fontTable.xml",
    "word/webSettings.xml",
    "word/theme/theme1.xml",
}


class Lorem:
    """Emit lorem words continuously so repeated calls do not all start at 'lorem'."""

    def __init__(self):
        self.i = 0

    def words(self, n):
        out = []
        for _ in range(max(1, n)):
            out.append(LOREM[self.i % len(LOREM)])
            self.i += 1
        return " ".join(out)

    def like(self, original):
        """Lorem text roughly matching the shape of the original run."""
        s = original.strip()
        if not s:
            return original
        if s.isdigit() or len(s) <= 2:
            return original  # page numbers, single characters, list markers
        n = max(1, len(s.split()))
        text = self.words(n)
        if s[0].isupper():
            text = text[0].upper() + text[1:]
        if s.endswith("."):
            text += "."
        return text


def scrub_document_xml(xml, lorem):
    """Replace visible text and the identifiers that carry real names.

    Three passes, because text is not the only place content hides:

    1. <w:t> run content. Entities such as &gt; are decoded before measuring
       and the replacement is plain lorem, so no escaping is needed. An
       earlier version skipped any run containing an entity, which silently
       left whole sentences in place.
    2. Bookmark names and the hyperlink anchors that point at them. Citation
       cross-references appear here as keys like ref-Cohen1988. Both sides are
       renamed through one mapping so the links still resolve.
    3. Field instruction text, which can carry file paths and citation keys.
    """
    # 1. run text
    def repl_text(m):
        open_tag, body, close = m.group(1), m.group(2), m.group(3)
        plain = (body.replace("&amp;", "&").replace("&lt;", "<")
                     .replace("&gt;", ">").replace("&quot;", '"')
                     .replace("&apos;", "'"))
        return open_tag + lorem.like(plain) + close

    xml = re.sub(r"(<w:t(?:\s[^>]*)?>)([^<]*)(</w:t>)", repl_text, xml)

    # 2. bookmark names and hyperlink anchors, renamed consistently
    names = set(re.findall(r'<w:bookmarkStart[^>]*w:name="([^"]+)"', xml))
    names |= set(re.findall(r'<w:hyperlink[^>]*w:anchor="([^"]+)"', xml))
    mapping = {}
    for i, n in enumerate(sorted(names), start=1):
        # _GoBack and _Toc entries are Word's own and carry nothing.
        mapping[n] = n if n.startswith("_") else "bm%d" % i
    for old, new in mapping.items():
        if old == new:
            continue
        xml = xml.replace('w:name="%s"' % old, 'w:name="%s"' % new)
        xml = xml.replace('w:anchor="%s"' % old, 'w:anchor="%s"' % new)

    # 3. field instruction text
    xml = re.sub(
        r"(<w:instrText(?:\s[^>]*)?>)([^<]*)(</w:instrText>)",
        lambda m: m.group(1) + " PAGE " + m.group(3),
        xml,
    )
    return xml


def scrub_core(xml, label):
    xml = re.sub(r"(<dc:title>)[^<]*(</dc:title>)", r"\g<1>" + label + r"\g<2>", xml)
    for tag in ("dc:creator", "cp:lastModifiedBy", "dc:subject", "cp:keywords",
                "dc:description", "cp:category"):
        xml = re.sub(r"(<%s>)[^<]*(</%s>)" % (tag, tag), r"\1\2", xml)
    return xml


def scrub_app(xml):
    for tag in ("Company", "Manager", "Title", "Subject", "Author"):
        xml = re.sub(r"(<%s>)[^<]*(</%s>)" % (tag, tag), r"\1\2", xml)
    # TitlesOfParts carries the document title as a vector entry.
    xml = re.sub(
        r"(<TitlesOfParts>).*?(</TitlesOfParts>)",
        r"\1\2",
        xml,
        flags=re.S,
    )
    return xml


def scrub_custom(xml):
    return re.sub(r"(<vt:lpwstr>)[^<]+(</vt:lpwstr>)", r"\1\2", xml)


def scrub_rels(xml):
    """Replace external link targets.

    Relationships with TargetMode="External" hold every URL the document linked
    to, which for an academic manuscript is the DOI of every work it cited.
    Internal relationships point at parts of the package and must survive.
    """
    return re.sub(
        r'(<Relationship\b[^>]*?)Target="[^"]*"([^>]*TargetMode="External")',
        r'\1Target="https://example.org/"\2',
        xml,
    )


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    src, dst = sys.argv[1], sys.argv[2]
    label = "Pandoc reference document"
    lorem = Lorem()

    zin = zipfile.ZipFile(src)
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            name = item.filename

            if name in PRESERVE:
                pass
            elif name == "word/document.xml" or re.match(
                r"word/(header|footnotes|endnotes)\d*\.xml$", name
            ):
                data = scrub_document_xml(data.decode("utf8"), lorem).encode("utf8")
            elif name == "docProps/core.xml":
                data = scrub_core(data.decode("utf8"), label).encode("utf8")
            elif name == "docProps/app.xml":
                data = scrub_app(data.decode("utf8")).encode("utf8")
            elif name == "docProps/custom.xml":
                data = scrub_custom(data.decode("utf8")).encode("utf8")
            elif name.endswith(".rels"):
                data = scrub_rels(data.decode("utf8")).encode("utf8")

            zout.writestr(item, data)
    zin.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
