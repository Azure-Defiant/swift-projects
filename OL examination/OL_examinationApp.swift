//
//  OL_examinationApp.swift
//  OL examination
//
//  Created by Sherwin Josh A. Aquino on 10/2/24.
//

import SwiftUI

@main
struct Proctorly: App {
    @StateObject  var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            GetStartedView()
                .environmentObject(authViewModel) // injected the authviewmodel :)
        }
    }
}
