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
}
