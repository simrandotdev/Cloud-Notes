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
                    ForEach(vm.fruits, id:\.self) { fruit in
                        Text(fruit)
                    }
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
    @Published var fruits: [String] = []
    
    init() {
        fetchItems()
    }
    
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
            
            // TODO: Handle errors better
            print("Record: \(record)")
            print("❌ ERROR: \(error)")
            
            DispatchQueue.main.async {
                self?.text = ""
            }
        }
    }
    
    
    func fetchItems() {
        // Create a Query Operation
        let predicate = NSPredicate(value: true)
        let queryOperation = CKQueryOperation(query: .init(recordType: "Fruit", predicate: predicate))
//        queryOperation.query?.sortDescriptors // You can add sort descriptors here as you want
        
        var returnedItems: [String] = []
        
        // This callback is called for each item in the database, so we append into our
        // local property here.
        queryOperation.recordMatchedBlock = { returnedRecordId, returnedResult in
            switch returnedResult {
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                returnedItems.append(name)
                break
            case .failure(let error):
                print("❌ ERROR: recordMatchedBlock: ", error.localizedDescription)
                break
            }
        }
        
        queryOperation.queryResultBlock = { [weak self] result in
            print("RETURNED RESULT: \(result)")
            DispatchQueue.main.async {
                self?.fruits = returnedItems
            }
        }
        
        // Add the Operation to the public cloud database
        CKContainer.default().publicCloudDatabase.add(queryOperation)
    }
    
    private func addOperation(operation: CKDatabaseOperation) {
        
    }
}
