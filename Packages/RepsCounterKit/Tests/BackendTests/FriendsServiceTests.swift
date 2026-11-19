import Foundation
import Testing
@testable import Backend

@Suite struct FriendsServiceTests {
    private let service = MockFriendsService(delay: .zero)

    @Test func findsByExactNicknameIgnoringCaseAndSpaces() async throws {
        #expect(try await service.findPlayer(nickname: "theo_9")?.profile.nickname == "Theo_9")
        #expect(try await service.findPlayer(nickname: "  MAX_POWER ")?.profile.nickname == "Max_Power")
    }

    @Test func noPartialMatches() async throws {
        #expect(try await service.findPlayer(nickname: "Theo") == nil)
        #expect(try await service.findPlayer(nickname: "nobody") == nil)
    }

    @Test func offlineTriggerThrows() async {
        await #expect(throws: URLError.self) {
            try await service.findPlayer(nickname: "offline")
        }
    }

    @Test func cardKeepsOnlyThreeMostRecentFriends() {
        let card = MockData.searchablePlayers[0]
        #expect(card.recentFriends.count == 3)
        #expect(card.recentFriends.first?.nickname == "Sophie")
        #expect(card.allFriends.count == 4)
    }
}

@Suite struct RatingMockTests {
    @Test func filledRatingPutsMeAt24WithDistinctPodium() {
        let me = PlayerProfile(nickname: "Nova_07", emoji: "🐧")
        let rating = MockData.ratingFilled(me: me)
        #expect(rating.global.first { $0.player == me }?.rank == 24)
        #expect(rating.global.prefix(3).map(\.rank) == [1, 2, 3])
        #expect(rating.friends.first { $0.player == me }?.rank == 4)
    }
}
