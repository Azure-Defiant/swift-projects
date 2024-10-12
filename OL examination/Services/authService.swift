


import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    private let supabaseURL = URL(string: "https://eylzbrmtbjwhkmhjgggr.supabase.co")!
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV5bHpicm10Ymp3aGttaGpnZ2dyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjY4NDQ3ODQsImV4cCI6MjA0MjQyMDc4NH0.lMlARKfwI8RoLcGgJ5CEJmymZOT2_w-FgP89IqLlIe4"

    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
}
