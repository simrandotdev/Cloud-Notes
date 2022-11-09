//
//  CRUDView.swift
//  Cloud Notes
//
//  Created by Simran Preet Narang on 2022-11-09.
//

import SwiftUI
import CloudKit

struct CRUDView: View {
    
    @StateObject private var vm = CRUDViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                header
                textField
                addButton
                List {
                    Text("Hi")
                }
                .listStyle(.plain)
            }
            .navigationBarHidden(true)
            .navigationViewStyle(.stack)
        }
    }
}

struct CRUDView_Previews: PreviewProvider {
    static var previews: some View {
        CRUDView()
    }
}


extension CRUDView {
    
    private var header: some View {
        Text("Cloudkit CRUD ☁️ ☁️ ☁️")
            .font(.headline)
            .underline()
    }
    
    private var textField: some View {
        TextField("Add something here", text: $vm.text)
            .frame(height: 55)
            .padding(.leading)
            .background(Color.gray.opacity(0.4))
            .cornerRadius(10)
            .padding()
    }
    
    private var addButton: some View {
        Button {
            vm.addButtonPressed()
        } label: {
            Text("Add")
                .fontWeight(.bold)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(Color.pink)
                .cornerRadius(10)
                .padding()
                .font(.headline)
            
                .foregroundColor(.white)
        }
    }
}



// MARK: - ViewModel


class CRUDViewModel: ObservableObject {
     
    @Published var text: String = ""
    
    func addButtonPressed() {
        guard !text.isEmpty else { return }
        addItem(name: text)
    }
    
    private func addItem(name: String) {
        
        let record = CKRecord(recordType: "Fruit")
        record["name"] = name
        saveItem(record: record)
    }
    
    private func saveItem(record: CKRecord) {
        
        CKContainer.default().publicCloudDatabase.save(record) { [weak self] record, error in
            print("Record: \(record)")
            print("❌ ERROR: \(error)")
            
            DispatchQueue.main.async {
                self?.text = ""
            }
        }
    }
}
