//
//  HttpConnectionOptions.swift
//  SignalRClient
//
//  Created by Pawel Kadluczka on 7/7/18.
//  Copyright © 2018 Pawel Kadluczka. All rights reserved.
//

import Foundation

/// HttpConnection configuration options.
public class HttpConnectionOptions {
    /**
      A dictionary containing headers to be included in HTTP requests sent by the client.
     */
    public var headers: [String: String] = [:]

    /**
      A factory for creating access tokens that will be included in HTTP requests sent by the client.

      - note: the factory will be called before each http request and will set the `Authorization` header value to: `Bearer {token-returned-by-factory}` unless
              the returned value is `nil` in which case the `Authorization` header will not be created
     */
    // Keep original function to maintain backward compatibility
    public var _standardAccessTokenProvider: () -> String? = { nil }

    /**
      The access token provider, which can be either synchronous or asynchronous.
      Setting this will override the previous provider.
     */
    public var accessTokenProvider: Any {
        get {
            if let asyncProvider = _asyncAccessTokenProvider {
                return asyncProvider
            }
            return _standardAccessTokenProvider
        }
        set {
            if let syncProvider = newValue as? () -> String? {
                _standardAccessTokenProvider = syncProvider
                _asyncAccessTokenProvider = nil
            } else if let asyncProvider = newValue as? @Sendable () async -> String? {
                _asyncAccessTokenProvider = asyncProvider
                // Create a sync wrapper that returns nil for backward compatibility
                _standardAccessTokenProvider = { nil }
            }
        }
    }

    // Internal storage for the async token provider
    private var _asyncAccessTokenProvider: (@Sendable () async -> String?)?

    /**
     Gets the access token either synchronously or asynchronously.
     */
    @available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func getAccessToken() async -> String? {
        if let asyncProvider = _asyncAccessTokenProvider {
            return await asyncProvider()
        } else {
            return _standardAccessTokenProvider()
        }
    }

    /**
      A factory for creating an HTTP client.
     */
    public var httpClientFactory: (_ options: HttpConnectionOptions) -> HttpClientProtocol = {
        DefaultHttpClient(options: $0)
    }

    /**
      Whether to skip the negotiation request when starting a connection.

      - note: the negotiation request can be skipped only when using the WebSockets transport and cannot be skipped when connecting to SignalR Azure Service
     */
    public var skipNegotiation: Bool {
        get { return skipNegotiationValue }

        @available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
        set { skipNegotiationValue = newValue }
    }

    private var skipNegotiationValue = false

    /**
     The timeout value for individual requests, in seconds.
      */
    public var requestTimeout: TimeInterval = 120

    /**
      The maximum number of bytes to buffer before the receive call fails with an error.

      This value includes the sum of all bytes from continuation frames. Receive calls will fail once the task reaches this limit. (URLSessionWebSocketTask)
     */
    public var maximumWebsocketMessageSize: Int?

    public var authenticationChallengeHandler:
        (
            (
                _ session: URLSession, _ challenge: URLAuthenticationChallenge,
                _ completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
            ) -> Void
        )?

    /**
     The queue to run callbacks on
      */
    public var callbackQueue: DispatchQueue = .init(label: "SignalR.connection.callbackQueue")

    /**
     Initializes an `HttpConnectionOptions`.
     */
    public init() {}

    // Helper method for the HttpConnection class to check if we have an async provider
    @available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func hasAsyncTokenProvider() -> Bool {
        return _asyncAccessTokenProvider != nil
    }
}
