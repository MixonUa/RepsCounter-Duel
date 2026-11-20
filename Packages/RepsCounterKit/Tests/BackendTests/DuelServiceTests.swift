import Foundation
import Testing
@testable import Backend

@Suite struct DuelRowTests {
    @Test func convertsServerTimesToTheLocalClock() throws {
        let json = """
        {"id":"8b0c4f8e-4b8f-4a43-9c1d-0d6f1b2f9a10","phase":"countdown","role":"host",
         "opponent":{"nickname":"Lena_v","emoji":"🐱"},"exercise":"push_ups","duration_seconds":60,
         "expires_at":"2026-11-20T10:03:00+00:00","my_ready":true,"opponent_ready":true,
         "starts_at":"2026-11-20T10:00:04.5+00:00","ends_at":"2026-11-20T10:01:04.5+00:00",
         "my_reps":0,"opponent_reps":0,"forfeited_by_me":false,"server_now":"2026-11-20T10:00:00.000000+00:00"}
        """
        let row = try JSONDecoder().decode(DuelRow.self, from: Data(json.utf8))
        // This device's clock is 10 s ahead of the server.
        let received = try #require(DuelRow.date("2026-11-20T10:00:10+00:00"))
        let snapshot = try row.snapshot(receivedAt: received)
        #expect(snapshot.phase == .countdown)
        #expect(snapshot.exercise == .pushUps)
        #expect(snapshot.opponent.nickname == "Lena_v")
        #expect(snapshot.startsAt == received.addingTimeInterval(4.5))
        #expect(snapshot.endsAt == received.addingTimeInterval(64.5))
    }
}

@Suite struct MockDuelServiceTests {
    @Test func hostFlowRunsToTheLobbyAndStarts() async throws {
        let service = MockDuelService(acceptDelay: 0, readyDelay: 0)
        let friend = PlayerProfile(serverNickname: "Lena_v", emoji: "🐱")
        let created = try await service.create(friend: friend, exercise: .squats, duration: DuelDuration(seconds: 10))
        #expect(created.phase == .invited)
        let lobby = try #require(try await service.view(created.id))
        #expect(lobby.phase == .lobby)
        let started = try await service.setReady(created.id)
        #expect(started.phase == .countdown)
        #expect(started.startsAt != nil)
        // Reps before the start don't count.
        #expect(try await service.submitRep(created.id, sequence: 1).myReps == 0)
        #expect(try await service.leave(created.id).phase == .cancelled)
    }
}
