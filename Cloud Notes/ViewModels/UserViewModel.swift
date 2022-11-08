//
//  UserViewModel.swift
//  Cloud Notes
//
//  Created by Simran Preet Narang on 2022-11-08.
//

import Foundation
import CloudKit

class UserViewModel: ObservableObject {
 
    @Published var isSignedIntoiCloud = false
    @Published var username: String = ""
    @Published var error: String = ""
    
    init() {
        getiCloudStatus()
        requestPermission()
    }
    
    private func getiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] returnedStatus, returnedError in
            
            if let returnedError{
                print("❌ ERROR: COULD NOT GET ACCOUNT STATUS FROM CLOUDKIT", returnedError.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                switch returnedStatus {
                case .couldNotDetermine:
                    self?.error = "❌ " + CloudKitError.iCloudAccountNotFound.localizedDescription
                    break
                case .available:
                    self?.isSignedIntoiCloud = true
                    break
                case .restricted:
                    self?.error = "❌ " + CloudKitError.iCloudAccountRestricted.localizedDescription
                    break
                case .noAccount:
                    self?.error = "❌ " + CloudKitError.iCloudAccountNotFound.localizedDescription
                    break
                case .temporarilyUnavailable:
                    self?.error = "❌ " + CloudKitError.iCloudAccountUnknown.localizedDescription
                    break
                @unknown default:
                    self?.error = "❌ " + CloudKitError.iCloudAccountUnknown.localizedDescription
                    break
                }
            }
        }
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
