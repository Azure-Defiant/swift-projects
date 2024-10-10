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

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

