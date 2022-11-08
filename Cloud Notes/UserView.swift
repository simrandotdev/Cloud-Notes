//
//  ContentView.swift
//  Cloud Notes
//
//  Created by Simran Preet Narang on 2022-11-08.
//

import SwiftUI

struct UserView: View {
    
    @StateObject private var vm = UserViewModel()
    
    var body: some View {
        VStack {
            Text("IS SIGNED IN: \(vm.isSignedIntoiCloud.description.uppercased()) with user: \(vm.username)")
            Text(vm.error)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        UserView()
    }
}
