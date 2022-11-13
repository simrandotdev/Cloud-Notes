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
    @Published var permissionStatus = false
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
        
        
        CloudKitUtility.requestApplicationPermission()
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.error = "❌ " + error.localizedDescription
                }
            } receiveValue: {[weak self] success in
                if success {
                    self?.getCurrentUserName()
                }
                self?.permissionStatus = success
            }
            .store(in: &cancellables)

    }
    
    
    func getCurrentUserName() {
        CloudKitUtility.discoverUserIdentity()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.error = "❌ " + error.localizedDescription
                }
            } receiveValue: { [weak self] username in
                DispatchQueue.main.async {
                    self?.username = username
                }
            }
            .store(in: &cancellables)

    }
}


enum CloudKitError: LocalizedError {
    case iCloudAccountNotFound
    case iCloudAccountNotDetermined
    case iCloudAccountRestricted
    case iCloudAccountUnknown
    case iCloudPermissionNotGranted
    case iCloudCouldNotFetchUserRecordId
    case iCloudCouldNotDiscoverUser
}
