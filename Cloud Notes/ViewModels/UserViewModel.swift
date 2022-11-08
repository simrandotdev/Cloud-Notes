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
    @Published var error: String = ""
    
    init() {
        getiCloudStatus()
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
                    self?.error = CloudKitError.iCloudAccountNotFound.localizedDescription
                    break
                case .available:
                    self?.isSignedIntoiCloud = true
                    break
                case .restricted:
                    self?.error = CloudKitError.iCloudAccountRestricted.localizedDescription
                    break
                case .noAccount:
                    self?.error = CloudKitError.iCloudAccountNotFound.localizedDescription
                    break
                case .temporarilyUnavailable:
                    self?.error = CloudKitError.iCloudAccountUnknown.localizedDescription
                    break
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
