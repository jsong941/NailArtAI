import SwiftUI
import UIKit

struct CropImageView: View {
    let image: UIImage

    // Navigation
    @Environment(\.dismiss) private var dismiss
    @State private var croppedImage: UIImage? = nil
    @State private var proceed = false

    // Layout
    @State private var containerSize: CGSize = .zero
    @State private var cropRect: CGRect = .zero

    // One GestureState per corner + move (each auto-resets when finger lifts)
    @GestureState private var tlDrag: CGSize = .zero
    @GestureState private var trDrag: CGSize = .zero
    @GestureState private var blDrag: CGSize = .zero
    @GestureState private var brDrag: CGSize = .zero
    @GestureState private var moveDrag: CGSize = .zero

    private let minCropSize: CGFloat = 60
    private let handleHitSize: CGFloat = 44   // Apple minimum touch target

    // MARK: - Geometry

    /// Where the image is rendered on screen (scaledToFit inside containerSize)
    private var imageRect: CGRect {
        guard containerSize.width > 0, image.size.width > 0, image.size.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }
        let imgAspect = image.size.width / image.size.height
        let boxAspect = containerSize.width / containerSize.height
        let d: CGSize = imgAspect > boxAspect
            ? CGSize(width: containerSize.width, height: containerSize.width / imgAspect)
            : CGSize(width: containerSize.height * imgAspect, height: containerSize.height)
        return CGRect(x: (containerSize.width - d.width) / 2,
                      y: (containerSize.height - d.height) / 2,
                      width: d.width, height: d.height)
    }

    /// cropRect with any live corner/move drag applied, clamped to image bounds
    private var visualCropRect: CGRect {
        var r = cropRect
        // TL — origin shifts right/down, size shrinks
        r.origin.x    += tlDrag.width;  r.size.width  -= tlDrag.width
        r.origin.y    += tlDrag.height; r.size.height -= tlDrag.height
        // TR — top shifts, right edge moves
        r.origin.y    += trDrag.height; r.size.height -= trDrag.height
        r.size.width  += trDrag.width
        // BL — left shifts, bottom edge moves
        r.origin.x    += blDrag.width;  r.size.width  -= blDrag.width
        r.size.height += blDrag.height
        // BR — right and bottom edges move
        r.size.width  += brDrag.width;  r.size.height += brDrag.height
        // Move — whole rect shifts
        r.origin.x += moveDrag.width;   r.origin.y    += moveDrag.height
        return clamp(r)
    }

    // MARK: - Body

    var body: some View {
        // Top-level GeometryReader with ignoresSafeArea so geo.size == the space
        // the image actually renders in — keeps containerSize in sync.
        GeometryReader { geo in
        ZStack {
            Color.black

            // ── Fixed image ────────────────────────────────────────────────
            Image(uiImage: image)
                .resizable()
                .scaledToFit()

            // ── Dimmed overlay with crop-rect hole ─────────────────────────
            Path { p in
                p.addRect(CGRect(origin: .zero, size: geo.size))
                p.addRect(visualCropRect)
            }
            .fill(Color.black.opacity(0.52), style: FillStyle(eoFill: true))
            .allowsHitTesting(false)

            // ── Crop border ────────────────────────────────────────────────
            Rectangle()
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                .frame(width: visualCropRect.width, height: visualCropRect.height)
                .position(x: visualCropRect.midX, y: visualCropRect.midY)
                .allowsHitTesting(false)

            // ── Rule-of-thirds grid ────────────────────────────────────────
            Canvas { ctx, _ in
                let r = visualCropRect
                let color = GraphicsContext.Shading.color(.white.opacity(0.25))
                let style = StrokeStyle(lineWidth: 0.5)
                for i in 1...2 {
                    var v = Path()
                    v.move(to: CGPoint(x: r.minX + r.width * CGFloat(i) / 3, y: r.minY))
                    v.addLine(to: CGPoint(x: r.minX + r.width * CGFloat(i) / 3, y: r.maxY))
                    ctx.stroke(v, with: color, style: style)

                    var h = Path()
                    h.move(to: CGPoint(x: r.minX, y: r.minY + r.height * CGFloat(i) / 3))
                    h.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * CGFloat(i) / 3))
                    ctx.stroke(h, with: color, style: style)
                }
            }
            .allowsHitTesting(false)

            // ── Interior move handle ───────────────────────────────────────
            let vr = visualCropRect
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: max(0, vr.width - handleHitSize * 2),
                       height: max(0, vr.height - handleHitSize * 2))
                .position(x: vr.midX, y: vr.midY)
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .updating($moveDrag) { v, s, _ in s = v.translation }
                        .onEnded { v in
                            var r = cropRect
                            r.origin.x += v.translation.width
                            r.origin.y += v.translation.height
                            cropRect = clamp(r)
                        }
                )

            // ── Corner handles ─────────────────────────────────────────────
            // Top-Left
            cornerHandle(.tl, at: CGPoint(x: vr.minX, y: vr.minY))
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .updating($tlDrag) { v, s, _ in s = v.translation }
                        .onEnded { v in
                            var r = cropRect
                            r.origin.x += v.translation.width;  r.size.width  -= v.translation.width
                            r.origin.y += v.translation.height; r.size.height -= v.translation.height
                            cropRect = clamp(r)
                        }
                )

            // Top-Right
            cornerHandle(.tr, at: CGPoint(x: vr.maxX, y: vr.minY))
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .updating($trDrag) { v, s, _ in s = v.translation }
                        .onEnded { v in
                            var r = cropRect
                            r.origin.y += v.translation.height; r.size.height -= v.translation.height
                            r.size.width += v.translation.width
                            cropRect = clamp(r)
                        }
                )

            // Bottom-Left
            cornerHandle(.bl, at: CGPoint(x: vr.minX, y: vr.maxY))
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .updating($blDrag) { v, s, _ in s = v.translation }
                        .onEnded { v in
                            var r = cropRect
                            r.origin.x += v.translation.width; r.size.width  -= v.translation.width
                            r.size.height += v.translation.height
                            cropRect = clamp(r)
                        }
                )

            // Bottom-Right
            cornerHandle(.br, at: CGPoint(x: vr.maxX, y: vr.maxY))
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .updating($brDrag) { v, s, _ in s = v.translation }
                        .onEnded { v in
                            var r = cropRect
                            r.size.width  += v.translation.width
                            r.size.height += v.translation.height
                            cropRect = clamp(r)
                        }
                )

            // ── Top bar + hint ─────────────────────────────────────────────
            VStack(spacing: 0) {
                ZStack {
                    Text("Crop Photo")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)

                    HStack {
                        Button("Cancel") { dismiss() }
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Spacer()
                        Button("Use Photo") { performCrop() }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appAccent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)

                Spacer()

                VStack(spacing: 6) {
                    Text("Crop to the area you want to design")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                    Text("Drag corners to resize · drag inside to move")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 52)
            }
        }   // end ZStack
        .onAppear {
            containerSize = geo.size   // geo is from the outer GeometryReader
            cropRect = imageRect       // imageRect now uses the correct containerSize
        }
        } // end GeometryReader
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $proceed) {
            if let img = croppedImage { ColorSelectionView(image: img) }
        }
    }

    // MARK: - Corner Handle View

    private enum Corner { case tl, tr, bl, br }

    @ViewBuilder
    private func cornerHandle(_ corner: Corner, at pos: CGPoint) -> some View {
        ZStack {
            // Oversized transparent hit area
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: handleHitSize, height: handleHitSize)

            // Gold L-shape
            Canvas { ctx, size in
                let cx = size.width / 2, cy = size.height / 2
                let len: CGFloat = 14
                var p = Path()
                switch corner {
                case .tl:
                    p.move(to: CGPoint(x: cx + len, y: cy))
                    p.addLine(to: CGPoint(x: cx, y: cy))
                    p.addLine(to: CGPoint(x: cx, y: cy + len))
                case .tr:
                    p.move(to: CGPoint(x: cx - len, y: cy))
                    p.addLine(to: CGPoint(x: cx, y: cy))
                    p.addLine(to: CGPoint(x: cx, y: cy + len))
                case .bl:
                    p.move(to: CGPoint(x: cx + len, y: cy))
                    p.addLine(to: CGPoint(x: cx, y: cy))
                    p.addLine(to: CGPoint(x: cx, y: cy - len))
                case .br:
                    p.move(to: CGPoint(x: cx - len, y: cy))
                    p.addLine(to: CGPoint(x: cx, y: cy))
                    p.addLine(to: CGPoint(x: cx, y: cy - len))
                }
                ctx.stroke(p,
                           with: .color(Color.appAccent),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
            .frame(width: handleHitSize, height: handleHitSize)
        }
        .position(pos)
    }

    // MARK: - Constraint

    private func clamp(_ rect: CGRect) -> CGRect {
        var r = rect
        let b = imageRect

        r.size.width  = max(minCropSize, r.size.width)
        r.size.height = max(minCropSize, r.size.height)

        // Keep origin inside image
        r.origin.x = min(max(b.minX, r.origin.x), b.maxX - r.size.width)
        r.origin.y = min(max(b.minY, r.origin.y), b.maxY - r.size.height)

        // Keep right/bottom edges inside image
        r.size.width  = min(r.size.width,  b.maxX - r.origin.x)
        r.size.height = min(r.size.height, b.maxY - r.origin.y)

        return r
    }

    // MARK: - Crop

    private func performCrop() {
        guard containerSize.width > 0, imageRect.width > 0 else {
            croppedImage = image; proceed = true; return
        }

        let cr = clamp(cropRect)
        let ir = imageRect

        // Screen-point → image-pixel scale factors
        let sx = image.size.width  / ir.width
        let sy = image.size.height / ir.height

        let pixelCrop = CGRect(
            x:      (cr.minX - ir.minX) * sx,
            y:      (cr.minY - ir.minY) * sy,
            width:  cr.width  * sx,
            height: cr.height * sy
        )

        // Render using UIImage.draw so orientation metadata is respected
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1   // work in image pixels, not screen points
        let renderer = UIGraphicsImageRenderer(size: pixelCrop.size, format: format)

        croppedImage = renderer.image { ctx in
            ctx.cgContext.translateBy(x: -pixelCrop.origin.x, y: -pixelCrop.origin.y)
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        proceed = true
    }
}
