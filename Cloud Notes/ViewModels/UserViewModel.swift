//
//  UserViewModel.swift
//  Cloud Notes
//
//  Created by Simran Preet Narang on 2022-11-08.
//

import Foundation
import CloudKit
import Combine

class UserViewModel: ObservableObject {
 
    @Published var isSignedIntoiCloud = false
    @Published var username: String = ""
    @Published var error: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        getiCloudStatus()
        requestPermission()
    }
    
    private func getiCloudStatus() {
        CloudKitUtility.getiCloudStatus()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.error = "❌ " + error.localizedDescription
                }
            } receiveValue: { [weak self] success in
                self?.isSignedIntoiCloud = success
            }
            .store(in: &cancellables)
    }
    
    
    func requestPermission() {
        CKContainer.default().requestApplicationPermission([.userDiscoverability]) { [weak self] status, error in
            if let error{
                print("❌ ERROR: COULD NOT REQUEST PERMISSION", error.localizedDescription)
                return
            }
            
            switch status {
            case .initialState:
                self?.error = "❌ Trying to get persmission"
            case .couldNotComplete:
                self?.error = "❌ Could not complete the permission request"
            case .denied:
                self?.error = "❌ Permission denied to fetch any user info from iCloud"
            case .granted:
                self?.fetchiCloudUserRecordID()
            @unknown default:
                self?.error = "❌ " + CloudKitError.iCloudAccountUnknown.localizedDescription
            }
        }
    }
    
    func fetchiCloudUserRecordID() {
        CKContainer.default().fetchUserRecordID { [weak self] recordID, error in
            if let error{
                print("❌ ERROR: COULD NOT FETCH iCloud USER RECORD ID", error.localizedDescription)
                return
            }
            
            if let recordID {
                self?.discoveriCloudUser(id: recordID)
            }
        }
    }
    
    func discoveriCloudUser(id: CKRecord.ID) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { [weak self] identity, error in
            if let error{
                print("❌ ERROR: COULD NOT GET iCloud USER", error.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                if let name = identity?.nameComponents?.givenName {
                    self?.username = name
                }
            }
        }
    }
}


enum CloudKitError: LocalizedError {
    case iCloudAccountNotFound
    case iCloudAccountNotDetermined
    case iCloudAccountRestricted
    case iCloudAccountUnknown
}
