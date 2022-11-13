//
//  CloudKitUtility.swift
//  Cloud Notes
//
//  Created by Simran Preet Narang on 2022-11-13.
//

import Foundation
import CloudKit
import Combine

class CloudKitUtility {
    
    static private func getiCloudStatus( completion: @escaping(Result<Bool, Error>) -> Void ) {
        CKContainer.default().accountStatus { returnedStatus, returnedError in
            
            if let returnedError{
                completion(.failure(returnedError))
                return
            }
            
            DispatchQueue.main.async {
                switch returnedStatus {
                case .couldNotDetermine:
                    completion(.failure(CloudKitError.iCloudAccountNotFound))
                    break
                case .available:
                    completion(.success(true))
                    break
                case .restricted:
                    completion(.failure(CloudKitError.iCloudAccountRestricted))
                    break
                case .noAccount:
                    completion(.failure(CloudKitError.iCloudAccountNotFound))
                    break
                case .temporarilyUnavailable:
                    completion(.failure(CloudKitError.iCloudAccountUnknown))
                    break
                @unknown default:
                    completion(.failure(CloudKitError.iCloudAccountUnknown))
                    break
                }
            }
        }
    }
    
    static func getiCloudStatus() -> Future<Bool, Error> {
        Future { promise in
            CloudKitUtility.getiCloudStatus { result in
                promise(result)
            }
        }
    }
    
    
    
    
    
    
    
    
    static private func requestApplicationPermission(completion: @escaping(Result<Bool, Error>) -> Void) {
        CKContainer.default().requestApplicationPermission([.userDiscoverability]) {status, error in
            if let error{
                print("❌ ERROR: COULD NOT REQUEST PERMISSION", error.localizedDescription)
                return
            }
            
            if status == .granted {
                completion(.success(true))
            } else {
                completion(.failure(CloudKitError.iCloudPermissionNotGranted))
            }
        }
    }
    
    static func requestApplicationPermission() -> Future<Bool, Error>  {
        Future { promise in
            CloudKitUtility.requestApplicationPermission { result in
                promise(result)
            }
        }
    }
    
    
    
    
    
    
    
    
    
    static private func fetchUserRecordID(completion: @escaping(Result<CKRecord.ID, Error>) -> Void) {
        CKContainer.default().fetchUserRecordID { recordID, error in
            if let recordID {
                completion(.success(recordID))
            } else {
                completion(.failure(CloudKitError.iCloudCouldNotFetchUserRecordId))
            }
        }
    }
    
    static private func discoverUserIdentity(id: CKRecord.ID, completion: @escaping(Result<String, Error>) -> Void) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { identity, error in
            if let name = identity?.nameComponents?.givenName {
                completion(.success(name))
            } else {
                completion(.failure(CloudKitError.iCloudCouldNotDiscoverUser))
            }
        }
    }
    
    static private func discoverUserIdentity(completion: @escaping(Result<String, Error>) -> Void) {
        fetchUserRecordID { fetchCompletionResult in
            switch fetchCompletionResult {
            case .success(let recordId):
                CloudKitUtility.discoverUserIdentity(id: recordId, completion: completion)
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    static func discoverUserIdentity() -> Future<String, Error> {
        Future { promise in
            CloudKitUtility.discoverUserIdentity { result in
                promise(result)
            }
        }
    }
    
}
