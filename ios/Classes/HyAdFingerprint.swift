import Foundation
import AdSupport
import CryptoKit
import Darwin
import UIKit

/// Fingerprint payload mirrored from sdk-ios v0.4.0.
/// Keep this file BYTE-COMPATIBLE with sdk-ios/Sources/HyStatistical/HyAdFingerprint.swift
/// so that:
///   - PAID computed by Flutter SDK on iOS matches the PAID a native iOS SDK would compute
///     on the same device (same install_time / system_update_time / boot_time inputs)
///   - IDFA / IDFV semantics identical (lowercase UUID; "" when unauthorized)
struct HyAdFingerprintData {
    let os: String          // "ios"
    let idfa: String        // "" if all-zero (unauthorized) — backend treats as absent
    let idfv: String        // identifierForVendor raw UUID — required by 巨量引擎 real-time attribution
    let paid: String        // 32-hex MD5 triple separated by "-"
}

enum HyAdFingerprint {
    static func collect() -> HyAdFingerprintData {
        let idfa = readIdfa()
        let idfv = readIdfv()
        let paid = computePaid()
        return HyAdFingerprintData(
            os: "ios",
            idfa: idfa.isAllZero ? "" : idfa,
            idfv: idfv,
            paid: paid
        )
    }

    private static func readIdfv() -> String {
        return UIDevice.current.identifierForVendor?.uuidString.lowercased() ?? ""
    }

    private static func readIdfa() -> String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString.lowercased()
    }

    private static func computePaid() -> String {
        let install = secondsToMD5(installTime())
        let sysupd  = secondsToMD5(systemUpdateTime())
        let boot    = secondsToMD5(bootTime())
        return "\(install)-\(sysupd)-\(boot)"
    }

    private static func installTime() -> UInt64 {
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        guard let path = libraryURL?.path,
              let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let date = attrs[.creationDate] as? Date else {
            return 0
        }
        return UInt64(date.timeIntervalSince1970)
    }

    private static func systemUpdateTime() -> UInt64 {
        var st = stat()
        guard stat("/usr/lib", &st) == 0 else { return 0 }
        return UInt64(st.st_mtimespec.tv_sec)
    }

    private static func bootTime() -> UInt64 {
        var tv = timeval()
        var size = MemoryLayout<timeval>.size
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        guard sysctl(&mib, 2, &tv, &size, nil, 0) == 0 else { return 0 }
        return UInt64(tv.tv_sec)
    }

    private static func secondsToMD5(_ s: UInt64) -> String {
        let str = String(s)
        let digest = Insecure.MD5.hash(data: Data(str.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private extension String {
    var isAllZero: Bool {
        return self == "00000000-0000-0000-0000-000000000000"
    }
}
