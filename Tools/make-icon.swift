import AppKit
import Foundation

/// Genera l'icona dell'applicazione in tutti i tagli richiesti da `iconutil`.
///
/// Il soggetto riprende il linguaggio visivo dell'interfaccia: corpo in grafite
/// scuro, tacche di carica verde fosforescente come il display del BT4-1CHN e
/// un arco azzurro/violetto come i controlli dell'app.
///
/// Uso: `swift Tools/make-icon.swift <directory-di-output>`
let entries: [(name: String, px: Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func draw(_ ctx: CGContext, _ s: CGFloat) {
    let rect = CGRect(x: 0, y: 0, width: s, height: s)

    // Corpo in grafite, con angoli smussati alla Apple.
    let corner = s * 0.225
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil))
    ctx.clip()
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: [CGColor(red: 0.115, green: 0.125, blue: 0.148, alpha: 1),
                                   CGColor(red: 0.035, green: 0.039, blue: 0.050, alpha: 1)] as CFArray,
                          locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])

    // Alone caldo in alto a sinistra, per dare profondità.
    let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: [CGColor(red: 0.36, green: 0.95, blue: 0.65, alpha: 0.30),
                                   CGColor(red: 0.36, green: 0.95, blue: 0.65, alpha: 0.0)] as CFArray,
                          locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: s * 0.28, y: s * 0.78), startRadius: 0,
                           endCenter: CGPoint(x: s * 0.28, y: s * 0.78), endRadius: s * 0.75, options: [])

    // Griglia fine, come i pixel del display.
    if s >= 128 {
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.035))
        let step = max(2, s / 42)
        var y = step
        while y < s {
            var x = step
            while x < s {
                ctx.fill(CGRect(x: x, y: y, width: 1.2, height: 1.2))
                x += step
            }
            y += step
        }
    }
    ctx.restoreGState()

    // Batteria: contorno arrotondato con contatto superiore.
    let bw = s * 0.44, bh = s * 0.60
    let bx = (s - bw) / 2, by = (s - bh) / 2 - s * 0.02
    let shell = CGRect(x: bx, y: by, width: bw, height: bh)
    let stroke = max(1.5, s * 0.035)
    let radius = s * 0.075

    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: shell.insetBy(dx: stroke / 2, dy: stroke / 2),
                       cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.setStrokeColor(CGColor(red: 0.36, green: 0.95, blue: 0.65, alpha: 1))
    ctx.setLineWidth(stroke)
    ctx.strokePath()

    // Contatto positivo.
    let capW = bw * 0.34, capH = s * 0.045
    let cap = CGRect(x: (s - capW) / 2, y: shell.maxY + stroke * 0.2, width: capW, height: capH)
    ctx.addPath(CGPath(roundedRect: cap, cornerWidth: capH / 2.6, cornerHeight: capH / 2.6, transform: nil))
    ctx.setFillColor(CGColor(red: 0.36, green: 0.95, blue: 0.65, alpha: 0.9))
    ctx.fillPath()

    // Tacche di carica: tre barre verdi con gradiente, riempimento al 100%.
    let inset = stroke * 2.1
    let inner = shell.insetBy(dx: inset, dy: inset)
    let gap = inner.height * 0.07
    let barH = (inner.height - gap * 2) / 3
    for i in 0..<3 {
        let bar = CGRect(x: inner.minX, y: inner.minY + CGFloat(i) * (barH + gap),
                         width: inner.width, height: barH)
        ctx.saveGState()
        ctx.addPath(CGPath(roundedRect: bar, cornerWidth: barH / 3.2, cornerHeight: barH / 3.2, transform: nil))
        ctx.clip()
        let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [CGColor(red: 0.28, green: 0.98, blue: 0.60, alpha: 1),
                                    CGColor(red: 0.20, green: 0.78, blue: 0.72, alpha: 1)] as CFArray,
                           locations: [0, 1])!
        ctx.drawLinearGradient(g, start: CGPoint(x: bar.minX, y: bar.maxY),
                               end: CGPoint(x: bar.maxX, y: bar.minY), options: [])
        ctx.restoreGState()
    }
    ctx.restoreGState()

    // Arco di stato, riprende i gauge dell'esito.
    let arcR = s * 0.44
    ctx.setLineCap(.round)
    ctx.setLineWidth(max(1.6, s * 0.030))
    ctx.setStrokeColor(CGColor(red: 0.48, green: 0.56, blue: 1.0, alpha: 0.85))
    ctx.addArc(center: CGPoint(x: s / 2, y: s / 2), radius: arcR,
               startAngle: .pi * 0.62, endAngle: .pi * 0.92, clockwise: false)
    ctx.strokePath()
    ctx.setStrokeColor(CGColor(red: 0.66, green: 0.48, blue: 1.0, alpha: 0.75))
    ctx.addArc(center: CGPoint(x: s / 2, y: s / 2), radius: arcR,
               startAngle: .pi * 1.62, endAngle: .pi * 1.92, clockwise: false)
    ctx.strokePath()
}

func render(_ s: Int) -> Data? {
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: s, pixelsHigh: s,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                     isPlanar: false, colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0),
          let ctx = NSGraphicsContext(bitmapImageRep: rep)?.cgContext else { return nil }
    ctx.setShouldAntialias(true)
    draw(ctx, CGFloat(s))
    return rep.representation(using: .png, properties: [:])
}

var written = 0
for entry in entries {
    guard let png = render(entry.px) else { continue }
    let url = URL(fileURLWithPath: "\(outDir)/\(entry.name)")
    try? png.write(to: url)
    written += 1
}
print("icone scritte: \(written) in \(outDir)")

// MARK: - Composizione diretta del file .icns
//
// `iconutil` rifiuta alcuni iconset generati fuori da Xcode, quindi il contenitore
// ICNS viene scritto direttamente: intestazione + blocchi (tipo, lunghezza, PNG).

/// Tipo ICNS assegnato a ciascun taglio, secondo la tabella Apple.
let icnsTypes: [(type: String, file: String)] = [
    ("icp4", "icon_16x16.png"),
    ("ic11", "icon_16x16@2x.png"),
    ("icp5", "icon_32x32.png"),
    ("ic12", "icon_32x32@2x.png"),
    ("ic07", "icon_128x128.png"),
    ("ic13", "icon_128x128@2x.png"),
    ("ic08", "icon_256x256.png"),
    ("ic14", "icon_256x256@2x.png"),
    ("ic09", "icon_512x512.png"),
    ("ic10", "icon_512x512@2x.png")
]

func bigEndian(_ value: UInt32) -> Data {
    var v = value.bigEndian
    return Data(bytes: &v, count: 4)
}

func composeICNS(from dir: String) -> Data? {
    var chunks = Data()
    for item in icnsTypes {
        guard let png = FileManager.default.contents(atPath: "\(dir)/\(item.file)"),
              png.count > 8 else { continue }
        chunks.append(item.type.data(using: .ascii)!)
        chunks.append(bigEndian(UInt32(png.count + 8)))
        chunks.append(png)
    }
    guard !chunks.isEmpty else { return nil }
    var out = Data("icns".utf8)
    out.append(bigEndian(UInt32(chunks.count + 8)))
    out.append(chunks)
    return out
}

if CommandLine.arguments.count > 2 {
    let icnsPath = CommandLine.arguments[2]
    if let icns = composeICNS(from: outDir) {
        try? icns.write(to: URL(fileURLWithPath: icnsPath))
        print("icns scritto: \(icnsPath) (\(icns.count) byte)")
    } else {
        FileHandle.standardError.write(Data("impossibile comporre l'icns\n".utf8))
        exit(1)
    }
}

