import Foundation
import Supabase

struct SupabaseClientProvider {
    let client: SupabaseClient

    init(baseURL: URL, anonKey: String) {
        client = SupabaseClient(supabaseURL: baseURL, supabaseKey: anonKey)
    }
}
