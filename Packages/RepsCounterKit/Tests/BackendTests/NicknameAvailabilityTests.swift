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
