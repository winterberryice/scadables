// ==========================================
// Adapter do wieszaka łazienkowego
// Bathroom Hook Holder - Adapter Base Plate
// ==========================================
//
// Problem: mała powierzchnia klejenia → wieszak się odkłeja
// Rozwiązanie: duża podstawa w kształcie "toru żużlowego" (stadium)
//              z gniazdem snap-fit na okrągłą pastylkę wieszaka
//
// Druk: płasko na stole, gniazdem do góry
// Montaż: tylna płaska strona klejona do kafelka
//         pastylka wieszaka wciskana do gniazda (klika)
// ==========================================

/* [Pastylka wieszaka / Hook disc] */
disc_d = 50;   // Średnica pastylki [mm]
disc_h = 6;    // Grubość pastylki [mm] (informacyjnie)

/* [Kształt podstawy / Base plate shape] */
// Kształt: dwa półkola połączone prostokątem ("tor żużlowy")
base_r     = 32;   // Promień półkola [mm]  (musi być >= disc_d/2 + groove_wall)
base_len   = 45;   // Odległość między środkami półkol [mm]
base_thick = 3.5;  // Grubość tylnej ścianki (przy kafelku) [mm]

/* [Gniazdo snap-fit / Snap groove] */
groove_clr  = 0.4;  // Luz gniazda - 0=ciasno (tylko tarcie), 0.4=snap normalnie [mm]
groove_dep  = 4.5;  // Głębokość gniazda – pastylka siedzi tu [mm]
groove_wall = 5.0;  // Min. grubość ścianki wokół gniazda [mm]

snap_h   = 1.2;  // Wysokość zaczepu snap-fit [mm]
snap_lip = 0.6;  // Wysunięcie zaczepu – mniejszy = łatwiejszy wklik [mm]

/* [Render] */
$fn = 128;

// === Wyliczone ===
groove_d    = disc_d + 2 * groove_clr;
total_thick = base_thick + groove_dep;

echo(str("Wymiary zewnętrzne: ", 2*base_r, " x ", 2*base_r + base_len, " x ", total_thick, " mm"));
echo(str("Średnica gniazda: ", groove_d, " mm"));
echo(str("Grubość ścianki gniazda: ", base_r - groove_d/2, " mm"));

// === Moduły ===

// Kształt "toru żużlowego" – hull() na dwóch walcach
module stadium(r, len, h) {
    hull() {
        translate([ len/2, 0, 0]) cylinder(r=r, h=h);
        translate([-len/2, 0, 0]) cylinder(r=r, h=h);
    }
}

// Gniazdo snap-fit:
//   - główna komora (pastylka siedzi swobodnie)
//   - zaczep przy wejściu: stożek zbieżny → wąski pier. → stożek rozbieżny
//     → pastylka wciska się, minimalnie ugina ścianki i "klika" w dół
module snap_groove() {
    translate([0, 0, base_thick]) {

        // Główna komora – pastylka siedzi tutaj
        cylinder(d=groove_d, h=groove_dep + 0.01);

        // Zaczep snap-fit przy wejściu (od strony Z = total_thick)
        // Profil w przekroju: ↘ minimum ↗  (jak ząb)
        translate([0, 0, groove_dep - 2*snap_h]) {
            cylinder(d1=groove_d,
                     d2=groove_d - 2*snap_lip,
                     h=snap_h);
            translate([0, 0, snap_h])
                cylinder(d1=groove_d - 2*snap_lip,
                         d2=groove_d,
                         h=snap_h);
        }
    }
}

// === Złożenie ===
difference() {
    stadium(base_r, base_len, total_thick);
    snap_groove();
}
