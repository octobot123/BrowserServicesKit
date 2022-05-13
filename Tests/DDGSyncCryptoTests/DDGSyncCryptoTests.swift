
import XCTest
import DDGSyncCrypto
import Clibsodium

class DDGSyncCryptoTests: XCTestCase {

    var primaryKey = [UInt8](repeating: 0, count: Int(DDGSYNCCRYPTO_PRIMARY_KEY_SIZE.rawValue))
    var secretKey = [UInt8](repeating: 0, count: Int(DDGSYNCCRYPTO_SECRET_KEY_SIZE.rawValue))
    var protectedSymmetricKey = [UInt8](repeating: 0, count: Int(DDGSYNCCRYPTO_PROTECTED_SYMMETRIC_KEY_SIZE.rawValue))
    var passwordHash = [UInt8](repeating: 0, count: Int(DDGSYNCCRYPTO_HASH_SIZE.rawValue))

    func testWhenEncryptingDataThenOutputCanBeDecryptedValid() {

        XCTAssertEqual(DDGSYNCCRYPTO_OK, ddgSyncGenerateAccountKeys(&primaryKey,
                                                                  &secretKey,
                                                                  &protectedSymmetricKey,
                                                                  &passwordHash,
                                                                  "UserID",
                                                                  "Password"))

        let message = "🍻" + UUID().uuidString + "↘️" + UUID().uuidString + "😱"

        var encryptedBytes = [UInt8](repeating: 0, count: message.utf8.count + Int(DDGSYNCCRYPTO_ENCRYPTED_EXTRA_BYTES_SIZE.rawValue))
        var rawBytes = Array(message.utf8)

        XCTAssertEqual(DDGSYNCCRYPTO_OK, ddgSyncEncrypt(&encryptedBytes, &rawBytes, UInt64(rawBytes.count), &secretKey))
        assertValidKey(encryptedBytes)

        var decryptedBytes = [UInt8](repeating: 0, count: encryptedBytes.count - Int(DDGSYNCCRYPTO_ENCRYPTED_EXTRA_BYTES_SIZE.rawValue))

        XCTAssertEqual(DDGSYNCCRYPTO_OK, ddgSyncDecrypt(&decryptedBytes, &encryptedBytes, UInt64(encryptedBytes.count), &secretKey))
        XCTAssertEqual(String(data: Data(decryptedBytes), encoding: .utf8), message)

    }

    func testWhenGeneratingAccountKeysThenEachKeyIsValid() {

        XCTAssertEqual(DDGSYNCCRYPTO_OK, ddgSyncGenerateAccountKeys(&primaryKey,
                                                                  &secretKey,
                                                                  &protectedSymmetricKey,
                                                                  &passwordHash,
                                                                  "UserID",
                                                                  "Password"))

        assertValidKey(primaryKey)
        assertValidKey(secretKey)
        assertValidKey(protectedSymmetricKey)
        assertValidKey(passwordHash)
    }

    func testWhenGeneratingAccountKeysThenPrimaryIsDeterministic() {
        var primaryKey2 = [UInt8](repeating: 0, count: Int(DDGSYNCCRYPTO_PRIMARY_KEY_SIZE.rawValue))

        XCTAssertEqual(DDGSYNCCRYPTO_OK, ddgSyncGenerateAccountKeys(&primaryKey,
                                                                  &secretKey,
                                                                  &protectedSymmetricKey,
                                                                  &passwordHash,
                                                                  "UserID",
                                                                  "Password"))

        XCTAssertEqual(DDGSYNCCRYPTO_OK, ddgSyncGenerateAccountKeys(&primaryKey2,
                                                                  &secretKey,
                                                                  &protectedSymmetricKey,
                                                                  &passwordHash,
                                                                  "UserID",
                                                                  "Password"))

        assertValidKey(primaryKey)
        assertValidKey(primaryKey2)

        XCTAssertEqual(primaryKey, primaryKey2)
    }

    func testWhenGeneratingAccountKeysThenSecretKeyIsNonDeterministic() {
        var secretKey2 = [UInt8](repeating: 0, count: Int(DDGSYNCCRYPTO_SECRET_KEY_SIZE.rawValue))

        XCTAssertEqual(DDGSYNCCRYPTO_OK, ddgSyncGenerateAccountKeys(&primaryKey,
                                                                  &secretKey,
                                                                  &protectedSymmetricKey,
                                                                  &passwordHash,
                                                                  "UserID",
                                                                  "Password"))

        XCTAssertEqual(DDGSYNCCRYPTO_OK, ddgSyncGenerateAccountKeys(&primaryKey,
                                                                  &secretKey2,
                                                                  &protectedSymmetricKey,
                                                                  &passwordHash,
                                                                  "UserID",
                                                                  "Password"))

        // The chance of these being randomly the same is so low that it should never happen.
        XCTAssertNotEqual(secretKey, secretKey2)
    }

    func assertValidKey(_ key: [UInt8]) {
        var nullCount = 0
        for value in key {
            if value == 0 {
                nullCount += 1
            }
        }
        XCTAssertNotEqual(nullCount, key.count)
    }

}
