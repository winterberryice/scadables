// ==========================================
// Bathroom Hook Holder - Adapter Base Plate
// ==========================================
//
// Problem:  small adhesive area → hook detaches from tile
// Solution: large stadium-shaped base plate with:
//           - circular pocket  → locates the hook disc (no glue)
//           - retention lip    → holds disc against peel force
//                                without any adhesive on the disc
//
// Orientation: Y = up/down, X = left/right, Z = thickness (into wall)
// Pocket at BOTTOM of stadium → adhesive above has maximum lever arm
//
// Print: flat on bed, pocket opening facing up (Z+)
// Mount: flat back glued to tile
// Disc insertion: tilt disc (bottom edge in first), rotate flat –
//                 top edge slides under the lip and is retained
// Disc removal:   push up on bottom edge to tilt out
// ==========================================

/* [Hook disc] */
disc_d = 50;   // Disc diameter [mm]
disc_h = 6;    // Disc thickness [mm] (informational – disc will protrude ~1.5 mm)

/* [Base plate shape] */
base_r     = 32;   // Semicircle radius [mm]  (must be >= disc_d/2 + pocket_wall)
base_len   = 45;   // Straight section length between semicircle centres [mm]
base_thick = 3.5;  // Back wall thickness (against tile) [mm]

/* [Locating pocket] */
pocket_clr  = 0.4;  // Pocket clearance – disc slides in freely [mm]
pocket_dep  = 4.5;  // Pocket depth [mm]  (disc protrudes = disc_h - pocket_dep)
pocket_wall = 5.0;  // Min. wall thickness around pocket [mm] (reference only)

/* [Retention lip] */
// The lip is a 120° arc ring protruding FORWARD from the adapter face.
// Centred on the top of the disc opening (+Y direction).
// 120° leaves 30° free on each side → easy tilt-in insertion.
//
// Disc insertion: tilt disc (bottom/side edges in first),
//                 rotate flat – top edge slides under the lip.
// Disc removal:   push bottom edge in to tilt disc, top pops out.
//
// Key constraint: lip_protrude MUST be > disc protrusion (= disc_h − pocket_dep)
//   so the lip actually overlaps the disc edge axially.
//   Default: disc protrudes 1.5 mm, lip protrudes 2.5 mm → 1 mm axial overlap.
lip_w        = 2.5;   // Radial overhang inward from pocket wall [mm] – try 2–3.5
lip_protrude = 2.5;   // How far lip sticks out from adapter front face [mm]
lip_chamfer  = 1.2;   // Chamfer size on all lip edges [mm] – smooths entry & look

/* [Render] */
$fn = 128;

// === Derived ===
pocket_d    = disc_d + 2 * pocket_clr;
total_thick = base_thick + pocket_dep;
pocket_y    = -base_len / 2;   // centre of bottom semicircle

_wall       = base_r - pocket_d / 2;
_disc_prot  = disc_h - pocket_dep;       // how much disc sticks out from adapter face
_lip_overlap = lip_protrude - _disc_prot; // how much lip covers disc from the front
echo(str("Overall: ", 2*base_r, " x ", 2*base_r+base_len, " x ", total_thick, " mm"));
echo(str("Pocket dia: ", pocket_d, " mm  |  wall: ", _wall, " mm"));
echo(str("Disc protrusion: ", _disc_prot, " mm  |  Lip protrusion: ", lip_protrude, " mm  |  Axial overlap: ", _lip_overlap, " mm"));
echo(str("Lip inner dia: ", pocket_d - 2*lip_w, " mm  (disc: ", disc_d, " → radial capture: ", lip_w - pocket_clr, " mm/side)"));

// === Modules ===

// Stadium body – vertical orientation (long axis = Y)
module stadium(r, len, h) {
    hull() {
        translate([0,  len/2, 0]) cylinder(r=r, h=h);
        translate([0, -len/2, 0]) cylinder(r=r, h=h);
    }
}

// Cylindrical locating pocket – plain hole, no snap-fit
module pocket() {
    translate([0, pocket_y, base_thick])
        cylinder(d=pocket_d, h=pocket_dep + 0.01);
}

// Retention lip – 120° arc ring protruding from the adapter FRONT FACE.
//
// Built with rotate_extrude(angle=120) so the arc is geometrically clean.
// Arc centred on local +Y (top of disc): starts at 30°, ends at 150° (from +X).
//
// Cross-section (r–z plane) is a chamfered trapezoid:
//
//   ri+ch  ro-ch ro
//      |    /   |
// lp   |   /   ← outer tip, chamfered
//      |  /
// lp-ch ← inner top, chamfered  (disc slides along this face when tilting in)
//      |    |
// ch   |    |
//      \    |  ← inner bottom chamfer → guides disc edge on entry
// 0     ────|
//       ri  ro    (outer face is vertical, flush with pocket wall)
//
// ri = pocket_d/2 − lip_w   (inner radius – disc captured beyond this)
// ro = pocket_d/2            (outer radius – at pocket wall)
module retention_lip() {
    ri = pocket_d/2 - lip_w;
    ro = pocket_d/2;
    lp = lip_protrude;
    ch = lip_chamfer;

    translate([0, pocket_y, total_thick])
        rotate([0, 0, 30])          // shift arc from [0°–120°] → [30°–150°], centred on +Y
            rotate_extrude(angle = 120, $fn = $fn)
                polygon([
                    [ri + ch, 0   ],  // inner bottom – chamfered (disc entry lead-in)
                    [ro,      0   ],  // outer bottom
                    [ro,      lp-ch], // outer face
                    [ro - ch, lp  ],  // outer tip – chamfered (looks smooth from front)
                    [ri,      lp-ch], // inner top  – chamfered (disc contact / slide-in surface)
                    [ri,      ch  ],  // inner face
                ]);
}

// === Assembly ===
union() {
    difference() {
        stadium(base_r, base_len, total_thick);
        pocket();
    }
    retention_lip();
}
