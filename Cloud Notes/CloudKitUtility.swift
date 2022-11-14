//
//  CloudKitUtility.swift
//  Cloud Notes
//
//  Created by Simran Preet Narang on 2022-11-13.
//

import Foundation
import CloudKit
import Combine



protocol iCloudModel: Hashable {
    
    var record: CKRecord { get set }
    
    init(record: CKRecord)
}


class CloudKitUtility {
    
    // MARK: - User Functions
    
    static func getiCloudStatus() -> Future<Bool, Error> {
        Future { promise in
            CloudKitUtility.getiCloudStatus { result in
                promise(result)
            }
        }
    }
    
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
    
/*********************************************************************************/
    
    
    
    
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
    
    /*********************************************************************************/
    
    static func discoverUserIdentity() -> Future<String, Error> {
        Future { promise in
            CloudKitUtility.discoverUserIdentity { result in
                promise(result)
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
    
    static private func discoverUserIdentity(id: CKRecord.ID, completion: @escaping(Result<String, Error>) -> Void) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { identity, error in
            if let name = identity?.nameComponents?.givenName {
                completion(.success(name))
            } else {
                completion(.failure(CloudKitError.iCloudCouldNotDiscoverUser))
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
    
    
    
    
    
    
    /*********************************************************************************/
    /*********************************************************************************/
    /*********************************************************************************/
    /*********************************************************************************/
    
    
    // MARK:- CRUD Functions
    
    // MARK: Fetch function
    
    static func fetch<T: iCloudModel>(recordType: String,
                                                  predicate: NSPredicate = NSPredicate(value: true),
                                                  sortDescriptors: [NSSortDescriptor]? = nil,
                                                  resultsLimit: Int? = nil) -> Future<[T], Never> {
        
        Future { promise in
            CloudKitUtility.fetch(recordType: recordType,
                                  predicate: predicate,
                                  sortDescriptors: sortDescriptors,
                                  resultsLimit: resultsLimit) { items in
                promise(.success(items))
            }
        }
    }
    
    static private func fetch<T: iCloudModel>(recordType: String,
                      predicate: NSPredicate = NSPredicate(value: true),
                      sortDescriptors: [NSSortDescriptor]? = nil,
                      resultsLimit: Int? = nil,
                      completion: @escaping ([T]) -> Void) {
        
        let operation = createOperation(recordType: recordType,
                                        predicate: predicate,
                                        sortDescriptors: sortDescriptors,
                                        resultsLimit: resultsLimit)
        
        // Get items in query
        var returnedItems: [T] = []
        addRecordMatchBlock(operation: operation) { fruit in
            returnedItems.append(fruit)
        }
        
        // Only called when all the returned items are finished
        queryResultBlock(operation: operation) { finished in
            completion(returnedItems)
        }
        
        addOperation(operation: operation)
    }
    
    
    static private func addRecordMatchBlock<T: iCloudModel>(operation: CKQueryOperation, completion: @escaping (_ fruit: T) -> Void) {
        
        operation.recordMatchedBlock = { returnedRecordId, returnedResult in
            switch returnedResult {
            case .success(let record):
                completion(T.init(record: record))
                break
            case .failure(let error):
                print("❌ ERROR: recordMatchedBlock: ", error.localizedDescription)
                break
            }
        }
    }
    
    static private func queryResultBlock(operation: CKQueryOperation, completion: @escaping (_ finished: Bool) -> Void) {
        
        operation.queryResultBlock = { resultCursor in
            
            completion(true)
        }
    }
    
    static private func createOperation(recordType: String,
                                        predicate: NSPredicate = NSPredicate(value: true),
                                        sortDescriptors: [NSSortDescriptor]? = nil,
                                        resultsLimit: Int? = nil) -> CKQueryOperation {
        
        // Create a Query Operation
        let queryOperation = CKQueryOperation(query: .init(recordType: recordType, predicate: predicate))
        
        // You can add sort descriptors here as you want
        queryOperation.query?.sortDescriptors = sortDescriptors
        
        if let resultsLimit {
            queryOperation.resultsLimit = resultsLimit
        }
        
        return queryOperation
    }
    
    
    static func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    
    /*********************************************************************************/
    
    
    // MARK: Save function
    
    static func save<T: iCloudModel>(_ recordModel: T) -> Future<CKRecord, Error> {
        Future { promise in
            CloudKitUtility.save(recordModel, completion: promise)
        }
    }
    
    
    
    static private func save<T: iCloudModel>(_ recordModel: T, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        
        CKContainer.default().publicCloudDatabase.save(recordModel.record) { record, error in
            if let record {
                completion(.success(record))
            } else {
                completion(.failure(CloudKitError.iCloudFailedToSaveRecord))
            }
        }
    }
    
    
    /*********************************************************************************/
    
    // MARK: Delete Function
    
    static func delete<T: iCloudModel>(indexSet: IndexSet,
                                       from records: [T]) -> Future<Bool, Error> {
        Future { promise in
            CloudKitUtility.delete(indexSet: indexSet, from: records, completion: promise)
        }
    }
    
    
    static private func delete<T: iCloudModel>(indexSet: IndexSet,
                                       from records: [T],
                                       completion: @escaping (Result<Bool, Error>) -> Void) {
        
        guard let index = indexSet.first else { return }
        let recordToDelete = records[index]
        let record = recordToDelete.record
        
        CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) { id, error in
            if id != nil {
                completion(.success(true))
            } else {
                completion(.failure(CloudKitError.iCloudFailedToDeleteRecords))
            }
        }
    }
}



// MARK: - Errors


enum CloudKitError: LocalizedError {
    case iCloudAccountNotFound
    case iCloudAccountNotDetermined
    case iCloudAccountRestricted
    case iCloudAccountUnknown
    case iCloudPermissionNotGranted
    case iCloudCouldNotFetchUserRecordId
    case iCloudCouldNotDiscoverUser
    case iCloudFailedToSaveRecord
    case iCloudFailedToDeleteRecords
}
