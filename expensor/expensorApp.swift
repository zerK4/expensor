//
//  expensorApp.swift
//  expensor
//
//  Created by Sebastian Pavel on 18.05.2025.
//

import SwiftUI

@main
struct expensorApp: App {
    @StateObject var userSession = UserSession()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(userSession)
                .environmentObject(ReceiptsViewModel(userSession: userSession))
        }
    }
}
