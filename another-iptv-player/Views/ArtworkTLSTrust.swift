import Foundation

/// URU2.COM: lets artwork load from panels whose HTTPS certificate is self-signed,
/// expired or issued for another host name.
///
/// IPTV panels very often serve `stream_icon` / `cover` / `backdrop_path` from their
/// own IP or a bare host with such a certificate. ATS is already off for the app
/// (`NSAllowsArbitraryLoads`), but URLSession still rejects the certificate, so those
/// posters and channel logos never appeared. Only image downloads go through this
/// delegate: panel API calls and playback keep the system's normal validation.
nonisolated final class ArtworkTLSTrustDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    static let shared = ArtworkTLSTrustDelegate()

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

/// Session for one-off artwork downloads outside the image pipeline (Now Playing).
nonisolated enum ArtworkURLSession {
    static let shared: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 40
        return URLSession(configuration: config, delegate: ArtworkTLSTrustDelegate.shared, delegateQueue: nil)
    }()
}
