#!/usr/bin/env python3
"""Generate the aws-mysql diagrams in the lucid style.

Emits two draw.io files matching the house style used by oci-k8s and
oci-resume-app: 1920x1080 canvas, dashed navy region frame, rounded white
cards with a colored 2px stroke, a 52px lucide icon, a 22px bold title and
15px grey subtitles, and 2.5px orthogonal edges with bold 16px labels.

  aws-mysql.drawio           what one apply builds — two availability
                                zones, both engines, a phpMyAdmin box per engine and
                                the two credential secrets
  aws-mysql-failover.drawio  why the two engines behave differently when
                                the writer dies

The Multi-AZ standby is drawn DASHED on purpose. It is a real instance you
pay for that has no row in the console, no endpoint and no way to connect to
it -- and that invisibility is the whole reason people confuse it with a read
replica. A diagram that omits it repeats the mistake; a diagram that draws it
solid overstates how visible it is.
"""

import os
from urllib.parse import quote

HERE = os.path.dirname(os.path.abspath(__file__))

# ==============================================================================
# Palette — one hue per concern so edges and cards read as a single system
# ==============================================================================

NAVY = "#1A2B4A"    # structure: region, VPC, subnets
BLUE = "#336791"    # Aurora — the shared-storage engine
AMBER = "#B5732E"   # RDS — the managed-instance engine
GREEN = "#2F8F4E"   # the client tier: phpMyAdmin
PURPLE = "#7A5CA6"  # secrets
TEAL = "#2E8B8B"    # the shared storage volume
GREY = "#5B6B82"    # subtitle text

BG_AZA = "#F2F7FB"  # availability zone a tint
BG_AZB = "#FDF6EE"  # availability zone b tint

# ==============================================================================
# Lucide icon paths — 24x24 viewBox, stroked (never filled) so the card's
# accent color carries through via the stroke parameter
# ==============================================================================

ICONS = {
    "cloud": '<path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/>',
    "globe": '<circle cx="12" cy="12" r="10"/>'
             '<path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/>'
             '<path d="M2 12h20"/>',
    "database": '<ellipse cx="12" cy="5" rx="9" ry="3"/>'
                '<path d="M3 5V19A9 3 0 0 0 21 19V5"/>'
                '<path d="M3 12A9 3 0 0 0 21 12"/>',
    "server": '<rect width="20" height="8" x="2" y="2" rx="2" ry="2"/>'
              '<rect width="20" height="8" x="2" y="14" rx="2" ry="2"/>'
              '<line x1="6" x2="6.01" y1="6" y2="6"/>'
              '<line x1="6" x2="6.01" y1="18" y2="18"/>',
    "monitor": '<rect width="20" height="14" x="2" y="3" rx="2"/>'
               '<line x1="8" x2="16" y1="21" y2="21"/>'
               '<line x1="12" x2="12" y1="17" y2="21"/>',
    "key": '<path d="m15.5 7.5 2.3 2.3a1 1 0 0 0 1.4 0l2.1-2.1a1 1 0 0 0 '
           '0-1.4L18.9 4"/><path d="m21 2-9.6 9.6"/>'
           '<circle cx="7.5" cy="15.5" r="5.5"/>',
    "swap": '<path d="M8 3 4 7l4 4"/><path d="M4 7h16"/>'
            '<path d="m16 21 4-4-4-4"/><path d="M20 17H4"/>',
    "layers": '<path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 '
              '1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z"/>'
              '<path d="m6.08 9.5-3.5 1.6a1 1 0 0 0 0 1.81l8.6 3.91a2 2 0 0 0 '
              '1.65 0l8.58-3.9a1 1 0 0 0 0-1.83l-3.5-1.59"/>'
              '<path d="m6.08 14.5-3.5 1.6a1 1 0 0 0 0 1.81l8.6 3.91a2 2 0 0 0 '
              '1.65 0l8.58-3.9a1 1 0 0 0 0-1.83l-3.5-1.59"/>',
    "eye-off": '<path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 '
               '13.16 0 0 1-1.67 2.68"/>'
               '<path d="M6.61 6.61A13.5 13.5 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 '
               '0 5.39-1.61"/><path d="m2 2 20 20"/>'
               '<path d="M14.12 14.12a3 3 0 1 1-4.24-4.24"/>',
    "arrow-right": '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>',
    "scissors": '<circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/>'
                '<line x1="20" x2="8.12" y1="4" y2="15.88"/>'
                '<line x1="14.47" x2="20" y1="14.48" y2="20"/>'
                '<line x1="8.12" x2="12" y1="8.12" y2="12"/>',
}


def icon_uri(name, color):
    """Return a draw.io image= data URI for a lucide glyph in `color`."""
    svg = (
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
        'viewBox="0 0 24 24" fill="none" stroke="%s" stroke-width="2" '
        'stroke-linecap="round" stroke-linejoin="round">%s</svg>'
        % (color, ICONS[name])
    )
    return "data:image/svg+xml," + quote(svg, safe="")


def esc(html):
    """Escape an HTML label so it survives inside an XML value attribute."""
    return (html.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace('"', "&quot;"))


class Canvas:
    """Accumulates mxCell fragments for one diagram."""

    def __init__(self, name):
        self.name = name
        self.cells = []
        self.cells.append(
            '<mxCell id="frame" value="" style="rounded=0;fillColor=#FFFFFF;'
            'strokeColor=none;" vertex="1" parent="1">'
            '<mxGeometry x="0" y="0" width="1920" height="1080" as="geometry"/>'
            '</mxCell>'
        )

    def card(self, cid, x, y, w, h, color, icon, title, subs, title_note="",
             dashed=False):
        """Emit a rounded accent-stroked card with icon, title and subtitles.

        Args:
            dashed: Draw the border dashed. Reserved for the Multi-AZ standby,
                which exists and bills but cannot be reached.
        """
        self.cells.append(
            '<mxCell id="%s" value="" style="rounded=1;whiteSpace=wrap;html=1;'
            'fillColor=#FFFFFF;strokeColor=%s;strokeWidth=2;%s" vertex="1" '
            'parent="1"><mxGeometry x="%d" y="%d" width="%d" height="%d" '
            'as="geometry"/></mxCell>'
            % (cid, color, "dashed=1;dashPattern=8 6;" if dashed else "",
               x, y, w, h)
        )
        self.cells.append(
            '<mxCell id="%s_i" value="" style="shape=image;html=1;imageAspect=0;'
            'aspect=fixed;verticalAlign=middle;image=%s" vertex="1" parent="1">'
            '<mxGeometry x="%d" y="%d" width="52" height="52" as="geometry"/>'
            '</mxCell>' % (cid, icon_uri(icon, color), x + 24, y + h // 2 - 26)
        )
        note = ('  <span style="font-size:16px;color:%s">%s</span>'
                % (color, title_note)) if title_note else ""
        body = "".join(
            '<br><span style="font-size:15px;color:%s">%s</span>' % (GREY, s)
            for s in subs
        )
        label = '<b style="font-size:22px">%s</b>%s%s' % (title, note, body)
        self.cells.append(
            '<mxCell id="%s_t" value="%s" style="text;html=1;whiteSpace=wrap;'
            'align=left;verticalAlign=middle;fillColor=none;strokeColor=none;'
            'fontColor=%s;" '
            'vertex="1" parent="1"><mxGeometry x="%d" y="%d" width="%d" '
            'height="%d" as="geometry"/></mxCell>'
            % (cid, esc(label), NAVY, x + 88, y + 10, w - 104, h - 20)
        )

    def container(self, cid, x, y, w, h, color, label, fill="none", fsize=18,
                  dash=False, icon=None):
        """Emit a grouping frame with a top-left label."""
        # Square corners on every frame — a percentage arc balloons on shapes
        # this large and reads as a blob rather than a boundary.
        style = (
            'rounded=0;whiteSpace=wrap;html=1;fillColor=%s;strokeColor=%s;'
            'strokeWidth=%s;fontColor=%s;align=left;verticalAlign=top;'
            'spacingTop=12;spacingLeft=%d;fontStyle=1;fontSize=%d;%s'
            % (fill, color, "2.5" if dash else "2", color,
               58 if icon else 20, fsize,
               "dashed=1;dashPattern=8 6;" if dash else "")
        )
        self.cells.append(
            '<mxCell id="%s" value="%s" style="%s" vertex="1" parent="1">'
            '<mxGeometry x="%d" y="%d" width="%d" height="%d" as="geometry"/>'
            '</mxCell>' % (cid, label, style, x, y, w, h)
        )
        if icon:
            self.cells.append(
                '<mxCell id="%s_i" value="" style="shape=image;html=1;'
                'imageAspect=0;aspect=fixed;verticalAlign=middle;image=%s" '
                'vertex="1" parent="1"><mxGeometry x="%d" y="%d" width="34" '
                'height="34" as="geometry"/></mxCell>'
                % (cid, icon_uri(icon, color), x + 16, y + 14)
            )

    def edge(self, cid, src, dst, label, color, ex, ey, nx, ny, dash=False,
             width="2.5", lpos=None, both=False):
        """Emit a labelled orthogonal edge between two card ids.

        Args:
            lpos: Position of the label along the edge, -1 at the source and 1
                at the target. draw.io centres labels by default, which on a
                long dog-legged edge drops the text wherever the midpoint
                happens to land — often on top of a frame label.
            both: Draw an arrowhead at the source end too, for relationships
                that genuinely run in both directions.
        """
        style = (
            'edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;strokeColor=%s;'
            'strokeWidth=%s;fontColor=%s;fontSize=16;fontStyle=1;'
            'endArrow=classic;%sexitX=%s;exitY=%s;exitDx=0;exitDy=0;entryX=%s;'
            'entryY=%s;entryDx=0;entryDy=0;labelBackgroundColor=#FFFFFF;%s'
            % (color, width, color, "startArrow=classic;" if both else "",
               ex, ey, nx, ny, "dashed=1;" if dash else "")
        )
        geo = ('<mxGeometry x="%s" relative="1" as="geometry"/>' % lpos
               if lpos is not None
               else '<mxGeometry relative="1" as="geometry"/>')
        self.cells.append(
            '<mxCell id="%s" value="%s" style="%s" edge="1" parent="1" '
            'source="%s" target="%s">%s</mxCell>'
            % (cid, label, style, src, dst, geo)
        )

    def note(self, cid, x, y, w, h, text, color=GREY, size=16):
        """Free-floating annotation text.

        whiteSpace=wrap is load-bearing: without it draw.io lays the string out
        on a single line that runs across the canvas and through every card in
        its path.
        """
        self.cells.append(
            '<mxCell id="%s" value="%s" style="text;html=1;whiteSpace=wrap;'
            'align=left;verticalAlign=top;fillColor=none;strokeColor=none;'
            'fontColor=%s;fontSize=%d;fontStyle=2;" vertex="1" parent="1">'
            '<mxGeometry x="%d" y="%d" width="%d" height="%d" as="geometry"/>'
            '</mxCell>' % (cid, esc(text), color, size, x, y, w, h)
        )

    def write(self, path):
        doc = (
            '<mxfile host="app.diagrams.net">'
            '<diagram name="%s">'
            '<mxGraphModel dx="1920" dy="1080" grid="0" gridSize="10" guides="1" '
            'tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" '
            'pageWidth="1920" pageHeight="1080" math="0" shadow="0">'
            '<root><mxCell id="0"/><mxCell id="1" parent="0"/>'
            % self.name
            + "".join(self.cells) +
            '</root></mxGraphModel></diagram></mxfile>'
        )
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(doc)
        print("wrote", path, len(doc), "bytes")


# ==============================================================================
# Diagram 1 — what one apply builds
# ------------------------------------------------------------------------------
# Two availability zones, both engines, and the standby drawn dashed because
# it has no console row and no endpoint. The layout puts Aurora and RDS on
# their own rows so the reader can see that Aurora spans the zones with two
# instances while RDS spans them with three.
# ==============================================================================

def build_arch():
    c = Canvas("aws-mysql")

    c.card("browser", 40, 460, 220, 130, NAVY, "globe",
           "You", ["browser", "phpMyAdmin"])

    c.container("region", 300, 40, 1580, 960, NAVY,
                "AWS Region  —  us-east-2", dash=True, fsize=24, icon="cloud")

    c.container("vpc", 340, 130, 1500, 730, NAVY,
                "VPC  —  rds-vpc  /  10.0.0.0/24", fsize=19)

    c.container("aza", 372, 200, 720, 630, NAVY,
                "rds-subnet-1  —  us-east-2a  /  10.0.0.0/26",
                fill=BG_AZA, fsize=16)
    c.container("azb", 1124, 200, 688, 630, NAVY,
                "rds-subnet-2  —  us-east-2b  /  10.0.0.64/26",
                fill=BG_AZB, fsize=16)

    # Unlike the Postgres build, there are TWO clients -- one phpMyAdmin box
    # per engine, both in subnet 1, each configured with a single PMA_HOST.
    # They are paired with their engine on the row below so the two request
    # paths never cross.
    #
    # Cards are inset from their subnet frames to leave two corridors: a 58px
    # channel on the left for the browser edges, and a 180px channel down the
    # middle wide enough for the inter-zone edge labels.
    c.card("pmaau", 430, 235, 570, 118, GREEN, "monitor",
           "phpmyadmin-aurora", ["t3.medium  ·  PMA_HOST = Aurora"])

    c.card("auw", 430, 385, 570, 118, BLUE, "database",
           "aurora-mysql-instance-1", ["writer  ·  Serverless v2, 0 – 4 ACU"])

    c.card("pmards", 430, 535, 570, 118, GREEN, "monitor",
           "phpmyadmin-rds", ["t3.medium  ·  PMA_HOST = RDS"])

    c.card("rdsp", 430, 685, 570, 118, AMBER, "server",
           "mysql-rds-instance", ["primary  ·  db.t4g.micro, Multi-AZ"])

    c.card("aur", 1180, 385, 570, 118, BLUE, "database",
           "aurora-mysql-instance-2", ["reader  ·  also the failover target"])

    c.card("rdsrep", 1180, 535, 570, 118, AMBER, "database",
           "mysql-rds-replica", ["read replica  ·  own endpoint"])

    c.card("rdssb", 1180, 685, 570, 118, AMBER, "eye-off",
           "Multi-AZ standby", ["no console row, no endpoint"], dashed=True)

    c.card("sec1", 372, 880, 700, 95, PURPLE, "key",
           "aurora-credentials", ["Secrets Manager  ·  generated"])
    c.card("sec2", 1112, 880, 700, 95, PURPLE, "key",
           "mysql-credentials", ["Secrets Manager  ·  generated"])

    c.edge("e1", "browser", "pmaau", "HTTP", NAVY, "1", "0.5", "0", "0.5")
    c.edge("e2", "browser", "pmards", "", NAVY, "1", "0.5", "0", "0.5")
    c.edge("e3", "pmaau", "auw", "", BLUE, "0.5", "1", "0.5", "0")
    c.edge("e4", "pmards", "rdsp", "", AMBER, "0.5", "1", "0.5", "0")
    c.edge("e5", "auw", "aur", "shared storage", TEAL,
           "1", "0.5", "0", "0.5", both=True)
    c.edge("e6", "rdsp", "rdssb", "synchronous", AMBER,
           "1", "0.5", "0", "0.5", dash=True)

    # Sits BELOW the region frame -- inside it, the dashed bottom border runs
    # straight through the text and reads as a strikethrough.
    c.note("n1", 300, 1014, 1100, 30,
           "Every password is generated at apply time and never written to "
           "the repo.")

    c.write(os.path.join(HERE, "aws-mysql.drawio"))


# ==============================================================================
# Diagram 2 — why they behave differently when the writer dies
# ------------------------------------------------------------------------------
# The point of this one is the storage layer. Aurora's instances are compute
# attached to a volume they share, so a failover is a role swap with nothing
# to catch up. RDS instances each hold their own copy, so the standby is a
# mirror you cannot read and the replica is a copy you cannot fail over to.
# ==============================================================================

def build_failover():
    c = Canvas("aws-mysql-failover")

    c.note("title", 60, 40, 900, 40,
           "When the writer dies", color=NAVY, size=30)

    # Cards in each half are narrowed to open a 220px channel between them.
    # The edge labels ("roles swap", "sync mirror") sit in that channel; at the
    # original 40px gap they printed straight over the right-hand card.
    c.container("aurora", 60, 110, 880, 440, BLUE,
                "AURORA  —  one volume, two compute nodes",
                fill=BG_AZA, fsize=19, icon="layers")

    c.card("a_w", 100, 200, 290, 120, BLUE, "database",
           "writer", ["us-east-2a"])
    c.card("a_r", 610, 200, 290, 120, BLUE, "database",
           "reader", ["us-east-2b"])
    c.card("a_vol", 100, 380, 800, 120, TEAL, "layers",
           "shared storage volume", ["both instances read the same data",
                                     "nothing to copy, nothing to catch up"])

    c.edge("ae1", "a_w", "a_vol", "", TEAL, "0.5", "1", "0.25", "0")
    c.edge("ae2", "a_r", "a_vol", "", TEAL, "0.5", "1", "0.75", "0")
    c.edge("ae3", "a_w", "a_r", "roles swap", BLUE,
           "1", "0.5", "0", "0.5", both=True)

    c.note("a_note", 100, 512, 800, 30,
           "The reader becomes the writer. Under 30 seconds, no data to move.")

    c.container("rds", 980, 110, 880, 440, AMBER,
                "RDS  —  three instances, three copies",
                fill=BG_AZB, fsize=19, icon="server")

    c.card("r_p", 1020, 200, 290, 120, AMBER, "server",
           "primary", ["us-east-2a"])
    c.card("r_s", 1530, 200, 290, 120, AMBER, "eye-off",
           "standby", ["us-east-2b"], dashed=True)
    c.card("r_r", 1020, 380, 800, 120, AMBER, "database",
           "read replica", ["its own full copy of the data",
                            "readable, but not a failover target"])

    c.edge("re1", "r_p", "r_s", "sync mirror", AMBER,
           "1", "0.5", "0", "0.5", dash=True)
    c.edge("re2", "r_p", "r_r", "async stream", AMBER,
           "0.5", "1", "0.25", "0")

    c.note("r_note", 1020, 512, 800, 30,
           "Multi-AZ swaps to the standby. The replica only has Promote — and "
           "Promote is permanent.")

    # Card height matches the content: three subtitle lines and a title need
    # about 170px, not the 250 they had, which left each card visibly hollow.
    c.container("ops", 60, 600, 1800, 320, NAVY,
                "THREE BUTTONS, THREE OUTCOMES", fsize=19, icon="swap")

    c.card("op1", 100, 680, 560, 180, BLUE, "swap",
           "Aurora  ·  Failover", [
               "reader and writer trade places",
               "replication never stops",
               "reversible — do it again to swap back",
           ])
    c.card("op2", 700, 680, 520, 180, AMBER, "arrow-right",
           "RDS  ·  Reboot with failover", [
               "standby takes over",
               "endpoint DNS is unchanged",
               "a new standby is rebuilt behind it",
           ])
    c.card("op3", 1260, 680, 560, 180, AMBER, "scissors",
           "RDS  ·  Promote", [
               "replica detaches into its own database",
               "replication never resumes",
               "one-way — there is no un-promote",
           ])

    c.write(os.path.join(HERE, "aws-mysql-failover.drawio"))


if __name__ == "__main__":
    build_arch()
    build_failover()
