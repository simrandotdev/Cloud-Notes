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
                        HStack {
                            if let url = fruit.imageURL,
                                let data = try? Data(contentsOf: url),
                               let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                            }
                            Text(fruit.name ?? "No Fruit available")
                        }
                            .onTapGesture {
                                vm.updateItem(fruit: fruit)
                            }
                    }
                    .onDelete { indexSet in
                        vm.delete(indexSet: indexSet)
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
    @Published var fruits: [FruitModel] = []
    
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
        
        // Attaching Image
        guard let image = UIImage(named: "twitter"),
              let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("\(name).jpg"),
              let data = image.jpegData(compressionQuality: 1.0)
        else { return }
        
        do {
            try data.write(to: url)
            let asset = CKAsset(fileURL: url)
            record["image"] = asset
        } catch {
            print("❌ Error in \(#function) ", error)
        }
        
        // Saving it.
        saveItem(record: record)
    }
    
    private func saveItem(record: CKRecord) {
        
        CKContainer.default().publicCloudDatabase.save(record) { [weak self] record, error in
            
            // TODO: Handle errors better
            print("Record: \(record)")
            print("❌ ERROR: \(error)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self?.text = ""
                self?.fetchItems()
            }
            
            
        }
    }
    
    
    func fetchItems() {
        
        let predicate = NSPredicate(value: true)
        CloudKitUtility.fetch(recordType: "Fruit", predicate: predicate) { [weak self] fruits in
            
            DispatchQueue.main.async {
                self?.fruits = fruits
            }
        }
    }
    
    func updateItem(fruit: FruitModel) {
        let record = fruit.record
        record["name"] = fruit.name + "*"
        saveItem(record: record)
    }
    
    func delete(indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let fruit = fruits[index]
        let record = fruit.record
        
        CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) { id, error in
            // TODO: Handle errors better
            print("Record: \(id)")
            print("❌ ERROR: \(error)")
            
            self.fetchItems()
        }
    }
}


struct FruitModel: Hashable {
    let record: CKRecord
    
    init(record: CKRecord) {
        self.record = record
    }
    
    init(name: String, imageUrl: URL? = nil) {
        let record = CKRecord(recordType: "Fruit")
        record["name"] = name
        self.record = record
    }
    
    var name: String {
        return record["name"] as? String ?? ""
    }
    
    var imageURL: URL? {
        let asset = record["image"] as? CKAsset
        return asset?.fileURL
    }
}
