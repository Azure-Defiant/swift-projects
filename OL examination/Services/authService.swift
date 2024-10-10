//
//  authService.swift
//  OL examination
//
//  Created by Sherwin Josh A. Aquino on 10/5/24.
//

/*import Foundation
import Supabase

enum Secrets{
    static let supabaseURL = "https://eylzbrmtbjwhkmhjgggr.supabase.co"
    static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV5bHpicm10Ymp3aGttaGpnZ2dyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjY4NDQ3ODQsImV4cCI6MjA0MjQyMDc4NH0.lMlARKfwI8RoLcGgJ5CEJmymZOT2_w-FgP89IqLlIe4"
}


final class AuthService{
    static let shared = AuthService()
    
    private let supabase = SupabaseClient(supabaseURL: URL(string: Secrets.supabaseURL)!,supabaseKey: Secrets.supabaseKey).auth
    
    let client: SupabaseClient
}
*/
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
