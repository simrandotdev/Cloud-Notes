//
//  CRUDView.swift
//  Cloud Notes
//
//  Created by Simran Preet Narang on 2022-11-09.
//

import SwiftUI
import CloudKit
import Combine

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
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchItems()
    }
    
    func addButtonPressed() {
        guard !text.isEmpty else { return }
        addItem(name: text)
    }
    
    private func addItem(name: String) {

        do {
            let record = CKRecord(recordType: "Fruit")
            record["name"] = name
            
            // Attaching Image
            guard let image = UIImage(named: "twitter"),
                  let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("\(name).jpg"),
                  let data = image.jpegData(compressionQuality: 1.0)
            else { return }
            
            try data.write(to: url)
            let asset = CKAsset(fileURL: url)
            record["image"] = asset
            
            saveItem(model: .init(record: record))
        } catch {
            print("❌ Error in \(#function) ", error)
        }
        
        // Saving it.
        
    }
    
    private func saveItem(model: FruitModel) {
        
        CloudKitUtility.save(model)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("✅ Successfully saved")
                case .failure(let error):
                    print("❌ Error in \(#function) ", error)
                }
            } receiveValue: { [weak self] record in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    self?.text = ""
                    self?.fetchItems()
                }
            }
            .store(in: &cancellables)
    }
    
    
    func fetchItems() {
        
        let predicate = NSPredicate(value: true)
        CloudKitUtility
            .fetch(recordType: "Fruit", predicate: predicate)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (items: [FruitModel]) in
                self?.fruits = items
            })
            .store(in: &cancellables)
    }
    
    func updateItem(fruit: FruitModel) {
        let record = fruit.record
        record["name"] = fruit.name + "*"
        
        let updatedFruit = FruitModel(record: record)
        
        saveItem(model: updatedFruit)
    }
    
    func delete(indexSet: IndexSet) {
        
        CloudKitUtility.delete(indexSet: indexSet, from: fruits)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                   break
                case .failure(let error):
                    print("❌ ERROR: \(error)")
                }
                
            } receiveValue: {[weak self] success in
                if success {
                    self?.fetchItems()
                }
            }
            .store(in: &cancellables)

    }
}

struct FruitModel: iCloudModel {
    
    var record: CKRecord
    
    init(record: CKRecord) {
        self.record = record
    }
    
    init(name: String, imageUrl: URL? = nil) {
        let record = CKRecord(recordType: "Fruit")
        record["name"] = name
        if let imageUrl {
            record["image"] = CKAsset(fileURL: imageUrl)
        }
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
