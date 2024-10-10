//
//  OL_examinationApp.swift
//  OL examination
//
//  Created by Sherwin Josh A. Aquino on 10/2/24.
//

import SwiftUI

@main
struct Proctorly: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            GetStartedView()
                .environmentObject(authViewModel) // Injecting AuthViewModel here
        }
    }
}
