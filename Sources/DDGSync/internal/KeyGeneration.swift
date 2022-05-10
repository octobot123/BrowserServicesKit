
import Foundation
import DDGSyncCrypto

struct KeyGeneration: KeyGenerating {

    func createAccountCreationKeys(userId: String, password: String) throws -> AccountCreationKeys {
        var primaryKey = [UInt8](repeating: 0, count: Int(DDGSYNCCRYPTO_PRIMARY_KEY_SIZE.rawValue))
        var secretKey = [UInt8](repeating: 0, count: Int(DDGSYNCCRYPTO_SECRET_KEY_SIZE.rawValue))
        var protectedSymmetricKey = [UInt8](repeating: 0, count: Int(DDGSYNCCRYPTO_PROTECTED_SYMMETRIC_KEY_SIZE.rawValue))
        var passwordHash = [UInt8](repeating: 0, count: Int(DDGSYNCCRYPTO_HASH_SIZE.rawValue))

        guard DDGSYNCCRYPTO_OK == ddgSyncGenerateAccountKeys(&primaryKey, &secretKey, &protectedSymmetricKey, &passwordHash, userId, password) else {
            throw SyncError.failedToCreateAccountKeys
        }

        return AccountCreationKeys(
            primaryKey: primaryKey,
            secretKey: secretKey,
            protectedSymmetricKey: protectedSymmetricKey,
            passwordHash: passwordHash
        )
    }

}
