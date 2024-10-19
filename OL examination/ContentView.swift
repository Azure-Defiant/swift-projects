//
//  ContentView.swift
//  OL examination
//
//  Created by Sherwin Josh A. Aquino on 10/2/24.
//

import SwiftUI
import Foundation
import Combine
import Supabase

struct Role: Codable {
    let id: Int
    let role_name: String
    
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            if authViewModel.isLoggedIn {
                if authViewModel.userRole == "Teacher" {
                    StudentView()
                } else if authViewModel.userRole == "Student" {
                    TeacherView()
                }
            } else if authViewModel.shouldNavigateToRoleSelection {
                RoleView()
            }
        }
    }
}

#Preview {
    ContentView()
}

