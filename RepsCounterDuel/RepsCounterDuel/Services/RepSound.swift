import AudioToolbox
import Foundation

/// Short system click for every counted rep (training and duel), so the player hears the count
/// from 2–3 m away. Off when Settings → Rep sound is Off. System sounds follow the ring / silent
/// switch. 1057 is iOS's short "Tink" system sound (undocumented ID, PROVISIONAL choice).
enum RepSound {
    private static let soundID: SystemSoundID = 1057

    static func play() {
        let isOn = UserDefaults.standard.object(forKey: LocalStorageKeys.repSound) as? Bool ?? true
        guard isOn else { return }
        AudioServicesPlaySystemSound(soundID)
    }
}
