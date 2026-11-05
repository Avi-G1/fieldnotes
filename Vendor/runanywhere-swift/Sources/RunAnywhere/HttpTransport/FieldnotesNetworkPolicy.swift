import Foundation

enum FieldnotesLocalOnlyHTTPPolicy {
    static let modelHost = "huggingface.co"
    static let modelPath = "/bartowski/Qwen2.5-3B-Instruct-GGUF/resolve/main/Qwen2.5-3B-Instruct-Q4_K_M.gguf"

    static func allows(method: String, url: URL, hasBody: Bool) -> Bool {
        guard !hasBody,
              url.scheme?.lowercased() == "https",
              url.host?.lowercased() == modelHost,
              url.path == modelPath,
              url.user == nil,
              url.password == nil,
              url.port == nil else { return false }
        let verb = method.uppercased()
        return verb == "GET" || verb == "HEAD"
    }

    static func allowsRedirect(from originalURL: URL?, to targetURL: URL?) -> Bool {
        guard let originalURL,
              (allows(method: "GET", url: originalURL, hasBody: false)
                || allows(method: "HEAD", url: originalURL, hasBody: false)),
              let targetURL,
              targetURL.scheme?.lowercased() == "https",
              targetURL.user == nil,
              targetURL.password == nil else { return false }
        let host = targetURL.host?.lowercased() ?? ""
        return host == modelHost || host.hasSuffix(".huggingface.co") || host == "xethub.hf.co" || host.hasSuffix(".xethub.hf.co")
    }
}
