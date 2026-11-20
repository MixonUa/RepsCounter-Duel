import Foundation
import Testing
@testable import Backend

@Suite struct NicknameAvailabilityTests {
    private let service = MockNicknameAvailabilityService(takenNicknames: ["Jade"], delay: .zero)

    @Test func takenNicknameIsCaseInsensitive() async throws {
        #expect(try await service.isNicknameAvailable("jade") == false)
        #expect(try await service.isNicknameAvailable("JADE") == false)
        #expect(try await service.isNicknameAvailable("  jade  ") == false)
    }

    @Test func freeNicknameIsAvailable() async throws {
        #expect(try await service.isNicknameAvailable("jade2") == true)
    }

    @Test func offlineTriggerThrowsNetworkError() async {
        await #expect(throws: URLError.self) {
            try await service.isNicknameAvailable("offline")
        }
    }

    @Test func submitNeedsAtLeastOneNonSpaceCharacter() {
        #expect(NicknameRules.canSubmit("") == false)
        #expect(NicknameRules.canSubmit("   ") == false)
        #expect(NicknameRules.canSubmit("a") == true)
        #expect(NicknameRules.normalized("  jade ") == "jade")
    }
}

@Suite struct ProfileRegistrationTests {
    private let service = MockProfileRegistrationService(delay: .zero)

    @Test func registersTrimmedNicknameAndEmoji() async throws {
        let profile = try await service.register(nickname: " Nova_07 ", emoji: "🐧")
        #expect(profile.nickname == "Nova_07")
        #expect(profile.emoji == "🐧")
    }

    @Test func takenNicknameFailsAtRegistration() async {
        await #expect(throws: ProfileRegistrationError.nicknameTaken) {
            try await service.register(nickname: "Admin", emoji: "🐧")
        }
    }
}

@Suite struct NicknameFormatTests {
    @Test func acceptsTheAgreedCharacterSet() {
        #expect(NicknameRules.isValid("Nova_07"))
        #expect(NicknameRules.isValid("lena.v"))
        #expect(NicknameRules.isValid("  abc  "))
        #expect(NicknameRules.isValid(String(repeating: "a", count: 20)))
    }

    @Test func rejectsEverythingElse() {
        #expect(!NicknameRules.isValid("ab"))
        #expect(!NicknameRules.isValid(String(repeating: "a", count: 21)))
        #expect(!NicknameRules.isValid("nova 07"))
        #expect(!NicknameRules.isValid("nova-07"))
        #expect(!NicknameRules.isValid("никита"))
        #expect(!NicknameRules.isValid("nova🐧"))
    }
}
