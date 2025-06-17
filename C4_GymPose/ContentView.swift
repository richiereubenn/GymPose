//
//  ContentView.swift
//  C4_GymPose
//
//  Created by Richie Reuben Hermanto on 17/06/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        BodyDetection()
    }
}

#Preview {
    ContentView()
}

extension Binding {
    @MainActor
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}
