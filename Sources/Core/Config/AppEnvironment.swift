import Foundation

struct AppEnvironment {
    let appEnv: String
    let supabaseURL: URL
    let supabaseAnonKey: String

    static func current(bundle: Bundle = .main) -> AppEnvironment {
        guard
            let env = bundle.object(forInfoDictionaryKey: "APP_ENV") as? String
        else {
            fatalError("APP_ENV is missing in build config")
        }

        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

        let urlRaw = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        let anonKey = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String

        // xcconfig truncates "https://..." to just the host due to "//" being a comment marker.
        // We store just the hostname and prepend "https://" here.
        if let urlRaw, let anonKey, !anonKey.isEmpty {
            let urlString: String
            if urlRaw.hasPrefix("http") {
                urlString = urlRaw
            } else {
                urlString = "https://\(urlRaw)"
            }
            if let url = URL(string: urlString), url.host != nil {
                return AppEnvironment(appEnv: env, supabaseURL: url, supabaseAnonKey: anonKey)
            }
        }

        if env == "DEBUG" || isRunningTests {
            return AppEnvironment(
                appEnv: env,
                supabaseURL: URL(string: "https://example.supabase.co")!,
                supabaseAnonKey: "debug-placeholder-anon-key"
            )
        }

        fatalError("Supabase environment values are missing")
    }
}
