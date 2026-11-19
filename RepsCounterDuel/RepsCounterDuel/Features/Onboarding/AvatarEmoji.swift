/// Emoji avatars offered in onboarding (the profile stores only the emoji character).
/// PROVISIONAL list of 21 animal faces (7 full rows of 3, head-only like Figma); the first is
/// preselected. The app uses the system emoji glyphs.
struct AvatarEmoji: Identifiable, Hashable {
    let emoji: String
    /// VoiceOver name.
    let name: String

    var id: String { emoji }

    static let all: [AvatarEmoji] = [
        AvatarEmoji(emoji: "🐧", name: "Penguin"),
        AvatarEmoji(emoji: "🐱", name: "Cat"),
        AvatarEmoji(emoji: "🐼", name: "Panda"),
        AvatarEmoji(emoji: "🐰", name: "Rabbit"),
        AvatarEmoji(emoji: "🐨", name: "Koala"),
        AvatarEmoji(emoji: "🦊", name: "Fox"),
        AvatarEmoji(emoji: "🐯", name: "Tiger"),
        AvatarEmoji(emoji: "🐵", name: "Monkey"),
        AvatarEmoji(emoji: "🦁", name: "Lion"),
        AvatarEmoji(emoji: "🐶", name: "Dog"),
        AvatarEmoji(emoji: "🐻", name: "Bear"),
        AvatarEmoji(emoji: "🐸", name: "Frog"),
        AvatarEmoji(emoji: "🐷", name: "Pig"),
        AvatarEmoji(emoji: "🐮", name: "Cow"),
        AvatarEmoji(emoji: "🐔", name: "Chicken"),
        AvatarEmoji(emoji: "🦄", name: "Unicorn"),
        AvatarEmoji(emoji: "🐺", name: "Wolf"),
        AvatarEmoji(emoji: "🐴", name: "Horse"),
        AvatarEmoji(emoji: "🐹", name: "Hamster"),
        AvatarEmoji(emoji: "🐲", name: "Dragon"),
        AvatarEmoji(emoji: "🐻‍❄️", name: "Polar bear"),
    ]

    static let `default` = all[0]
}
