import AppKit
import ImageIO

enum GIFDecoder {
    enum DecoderError: Error {
        case unreadable
        case emptyImage
    }

    static func decode(url: URL) throws -> [CursorFrame] {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw DecoderError.unreadable
        }

        let count = CGImageSourceGetCount(source)
        guard count > 0 else {
            throw DecoderError.emptyImage
        }

        return try (0..<count).map { index in
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                throw DecoderError.unreadable
            }

            let duration = frameDuration(source: source, index: index)
            let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            return CursorFrame(image: image, duration: duration)
        }
    }

    private static func frameDuration(source: CGImageSource, index: Int) -> TimeInterval {
        let fallback = 0.08
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
            let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else {
            return fallback
        }

        let unclamped = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let clamped = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval
        let duration = unclamped ?? clamped ?? fallback

        return duration < 0.02 ? fallback : duration
    }
}
