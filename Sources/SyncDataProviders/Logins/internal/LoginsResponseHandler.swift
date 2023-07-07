//
//  LoginsResponseHandler.swift
//  DuckDuckGo
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


import BrowserServicesKit
import DDGSync
import Foundation
import GRDB

final class LoginsResponseHandler {
    let clientTimestamp: Date?
    let received: [Syncable]
    let secureVault: SecureVault
    let database: Database
    let shouldDeduplicateEntities: Bool

    let receivedByUUID: [String: Syncable]
    let allReceivedIDs: Set<String>

    var credentialsByUUID: [String: SecureVaultModels.WebsiteAccountSyncMetadata] = [:]

    private let decrypt: (String) throws -> String

    init(received: [Syncable], clientTimestamp: Date? = nil, secureVault: SecureVault, database: Database, crypter: Crypting, deduplicateEntities: Bool) throws {
        self.clientTimestamp = clientTimestamp
        self.received = received
        self.secureVault = secureVault
        self.database = database
        self.shouldDeduplicateEntities = deduplicateEntities

        let secretKey = try crypter.fetchSecretKey()
        self.decrypt = { try crypter.base64DecodeAndDecrypt($0, using: secretKey) }

        var syncablesByUUID: [String: Syncable] = [:]
        var allUUIDs: Set<String> = []

        received.forEach { syncable in
            guard let uuid = syncable.uuid else {
                return
            }
            syncablesByUUID[uuid] = syncable
            allUUIDs.insert(uuid)
        }

        self.allReceivedIDs = allUUIDs
        self.receivedByUUID = syncablesByUUID

        credentialsByUUID = try secureVault.websiteCredentialsForSyncIds(allUUIDs, in: database).reduce(into: .init(), { $0[$1.id] = $1 })
    }

    func processReceivedCredentials() throws {
        if received.isEmpty {
            return
        }

        for syncable in received {
            try processEntity(with: syncable)
        }
    }

    // MARK: - Private

    private func processEntity(with syncable: Syncable) throws {
        guard let syncableUUID = syncable.uuid else {
            throw SyncError.accountAlreadyExists // todo
        }

        if shouldDeduplicateEntities, var deduplicatedEntity = try secureVault.deduplicatedCredential(in: database, with: syncable, decryptedUsing: decrypt) {

            let oldUUID = deduplicatedEntity.id
            deduplicatedEntity.id = syncableUUID

            credentialsByUUID.removeValue(forKey: oldUUID)
            credentialsByUUID[syncableUUID] = deduplicatedEntity

        } else if var existingEntity = credentialsByUUID[syncableUUID] {
            let isModifiedAfterSyncTimestamp: Bool = {
                guard let clientTimestamp, let modifiedAt = existingEntity.lastModified else {
                    return false
                }
                return modifiedAt > clientTimestamp
            }()
            if !isModifiedAfterSyncTimestamp {
                if syncable.isDeleted {
                    try secureVault.deleteWebsiteCredentialsMetadata(existingEntity, in: database)
                } else {
                    try existingEntity.update(with: syncable, decryptedUsing: decrypt)
                    existingEntity.lastModified = nil
                    try secureVault.storeWebsiteCredentialsMetadata(existingEntity, clearModifiedAt: true, in: database)
                }
            }

        } else if !syncable.isDeleted {

            let newEntity = try SecureVaultModels.WebsiteAccountSyncMetadata(syncable: syncable, decryptedUsing: decrypt)
            try secureVault.storeWebsiteCredentialsMetadata(newEntity, clearModifiedAt: true, in: database)
            credentialsByUUID[syncableUUID] = newEntity
        }
    }
}

extension SecureVaultModels.WebsiteAccountSyncMetadata {

    init(syncable: Syncable, decryptedUsing decrypt: (String) throws -> String) throws {
        guard let id = syncable.uuid else {
            throw SyncError.accountAlreadyExists
        }

        let title = try syncable.encryptedTitle.flatMap { try decrypt($0) }
        let username = try syncable.encryptedUsername.flatMap { try decrypt($0) }
        let domain = try syncable.encryptedDomain.flatMap { try decrypt($0) }
        let notes = try syncable.encryptedNotes.flatMap { try decrypt($0) }
        let password = try syncable.encryptedPassword.flatMap { try decrypt($0) }

        let account = SecureVaultModels.WebsiteAccount(title: title, username: username, domain: domain, notes: notes)
        let credentials = SecureVaultModels.WebsiteCredentials(account: account, password: password?.data(using: .utf8))
        self.init(id: id, credential: credentials, lastModified: nil)
    }

    mutating func update(with syncable: Syncable, decryptedUsing decrypt: (String) throws -> String) throws {
        if let encryptedDomain = syncable.encryptedDomain {
            credential?.account.domain = try decrypt(encryptedDomain)
        } else {
            credential?.account.domain = nil
        }

        if let encryptedTitle = syncable.encryptedTitle {
            credential?.account.title = try decrypt(encryptedTitle)
        } else {
            credential?.account.title = nil
        }

        if let encryptedNotes = syncable.encryptedNotes {
            credential?.account.notes = try decrypt(encryptedNotes)
        } else {
            credential?.account.notes = nil
        }

        if let encryptedUsername = syncable.encryptedUsername {
            credential?.account.username = try decrypt(encryptedUsername)
        } else {
            credential?.account.username = nil
        }

        if let encryptedPassword = syncable.encryptedPassword {
            credential?.password = try decrypt(encryptedPassword).data(using: .utf8)
        } else {
            credential?.password = nil
        }
    }
}
