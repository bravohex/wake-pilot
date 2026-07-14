import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case vietnamese = "vi"
    case english = "en"
    case japanese = "ja"

    static let defaultLanguage: AppLanguage = .english

    var id: String {
        rawValue
    }

    var nativeName: String {
        switch self {
        case .vietnamese:
            return "Tiếng Việt"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        }
    }

    var locale: Locale {
        switch self {
        case .vietnamese:
            return Locale(identifier: "vi_VN")
        case .english:
            return Locale(identifier: "en_US")
        case .japanese:
            return Locale(identifier: "ja_JP")
        }
    }
}

enum AppStrings {
    enum Key: CaseIterable {
        case activitySection
        case enableWakePilot
        case keepDisplayAwake
        case keepChatActive
        case presenceInterval
        case minutes
        case scheduleSection
        case scheduleEnabled
        case scheduleStart
        case scheduleEnd
        case scheduleCurrent
        case scheduleAlwaysOn
        case systemPermissionsSection
        case accessibility
        case permissionGranted
        case permissionNotGranted
        case grantPermission
        case presenceExplanation
        case startupSection
        case launchAtLogin
        case status
        case openLoginItemsSettings
        case notesSection
        case notesExplanation
        case errorsSection
        case languageSection
        case appVersion
        case paused
        case outsideScheduledTime
        case accessibilityRequired
        case active
        case sleepMayResume
        case resumesAt
        case heartbeatUnavailable
        case heartbeatActive
        case powerAssertionActive
        case alwaysActive
        case allDay
        case cannotUpdateLoginItem
        case cannotCreateHeartbeat
        case scheduleLabel
        case accessibilityGranted
        case lastPresence
        case settings
        case quit
        case loginEnabled
        case loginRequiresApproval
        case loginDisabled
        case loginNotFound
        case loginUnknown
        case systemAssertionName
        case systemAssertionError
        case displayAssertionName
        case displayAssertionError
    }

    static func text(_ key: Key, language: AppLanguage) -> String {
        catalogs[language]?[key] ?? catalogs[.english]![key]!
    }

    static func format(
        _ key: Key,
        language: AppLanguage,
        arguments: [CVarArg]
    ) -> String {
        String(
            format: text(key, language: language),
            locale: language.locale,
            arguments: arguments
        )
    }

    private static let catalogs: [AppLanguage: [Key: String]] = [
        .vietnamese: [
            .activitySection: "Hoạt động",
            .enableWakePilot: "Bật Wake Pilot",
            .keepDisplayAwake: "Giữ màn hình sáng",
            .keepChatActive: "Giữ trạng thái chat hoạt động",
            .presenceInterval: "Chu kỳ presence",
            .minutes: "%d phút",
            .scheduleSection: "Lịch hoạt động",
            .scheduleEnabled: "Chỉ hoạt động theo khung giờ",
            .scheduleStart: "Bắt đầu",
            .scheduleEnd: "Kết thúc",
            .scheduleCurrent: "Lịch hiện tại: %@. Hỗ trợ khung giờ qua đêm; thời điểm kết thúc không được tính.",
            .scheduleAlwaysOn: "Wake Pilot sẽ luôn hoạt động khi đang bật.",
            .systemPermissionsSection: "Quyền hệ thống",
            .accessibility: "Accessibility",
            .permissionGranted: "Đã cấp",
            .permissionNotGranted: "Chưa cấp",
            .grantPermission: "Cấp quyền…",
            .presenceExplanation: "Presence heartbeat chỉ phát một lần nhấn Shift khi máy đã không có thao tác trong khoảng thời gian đã chọn.",
            .startupSection: "Khởi động",
            .launchAtLogin: "Mở Wake Pilot khi đăng nhập",
            .status: "Trạng thái",
            .openLoginItemsSettings: "Mở Login Items Settings…",
            .notesSection: "Lưu ý",
            .notesExplanation: "Chống sleep dùng IOKit power assertion. Presence heartbeat cần Accessibility và có thể không được mọi ứng dụng chat công nhận. App không vượt qua màn hình khóa hoặc chính sách MDM.",
            .errorsSection: "Lỗi",
            .languageSection: "Ngôn ngữ",
            .appVersion: "Phiên bản %@",
            .paused: "Đang tạm dừng",
            .outsideScheduledTime: "Ngoài khung giờ",
            .accessibilityRequired: "Cần cấp quyền Accessibility",
            .active: "Đang hoạt động",
            .sleepMayResume: "Mac có thể sleep theo cài đặt hệ thống.",
            .resumesAt: "Wake Pilot sẽ tiếp tục lúc %@.",
            .heartbeatUnavailable: "Chống sleep đang bật, nhưng nhịp presence chưa hoạt động.",
            .heartbeatActive: "Chống sleep và nhịp presence đang hoạt động.",
            .powerAssertionActive: "Đang chống system sleep.",
            .alwaysActive: "Luôn hoạt động",
            .allDay: "Cả ngày",
            .cannotUpdateLoginItem: "Không thể cập nhật Launch at Login: %@",
            .cannotCreateHeartbeat: "Không thể tạo presence heartbeat.",
            .scheduleLabel: "Lịch: %@",
            .accessibilityGranted: "Accessibility đã được cấp",
            .lastPresence: "Presence gần nhất",
            .settings: "Cài đặt…",
            .quit: "Thoát",
            .loginEnabled: "Đã bật",
            .loginRequiresApproval: "Đang chờ phê duyệt trong System Settings",
            .loginDisabled: "Đã tắt",
            .loginNotFound: "Không tìm thấy dịch vụ Mở khi đăng nhập",
            .loginUnknown: "Không xác định",
            .systemAssertionName: "Wake Pilot đang giữ máy hoạt động.",
            .systemAssertionError: "Không thể tạo system sleep assertion (mã %d).",
            .displayAssertionName: "Wake Pilot đang giữ màn hình hoạt động.",
            .displayAssertionError: "Không thể tạo display sleep assertion (mã %d)."
        ],
        .english: [
            .activitySection: "Activity",
            .enableWakePilot: "Enable Wake Pilot",
            .keepDisplayAwake: "Keep display awake",
            .keepChatActive: "Keep chat status active",
            .presenceInterval: "Presence interval",
            .minutes: "%d minutes",
            .scheduleSection: "Activity schedule",
            .scheduleEnabled: "Only run during scheduled hours",
            .scheduleStart: "Start",
            .scheduleEnd: "End",
            .scheduleCurrent: "Current schedule: %@. Overnight ranges are supported; the end time is excluded.",
            .scheduleAlwaysOn: "Wake Pilot will run whenever it is enabled.",
            .systemPermissionsSection: "System permissions",
            .accessibility: "Accessibility",
            .permissionGranted: "Granted",
            .permissionNotGranted: "Not granted",
            .grantPermission: "Grant permission…",
            .presenceExplanation: "Presence heartbeat sends one Shift key press only after the Mac has been idle for the selected period.",
            .startupSection: "Startup",
            .launchAtLogin: "Open Wake Pilot at login",
            .status: "Status",
            .openLoginItemsSettings: "Open Login Items Settings…",
            .notesSection: "Notes",
            .notesExplanation: "Sleep prevention uses an IOKit power assertion. Presence heartbeat requires Accessibility and may not be recognized by every chat app. The app does not bypass the lock screen, MDM, or organization security policies.",
            .errorsSection: "Error",
            .languageSection: "Language",
            .appVersion: "Version %@",
            .paused: "Paused",
            .outsideScheduledTime: "Outside scheduled hours",
            .accessibilityRequired: "Accessibility permission required",
            .active: "Active",
            .sleepMayResume: "Your Mac may sleep according to its system settings.",
            .resumesAt: "Wake Pilot will resume at %@.",
            .heartbeatUnavailable: "Sleep prevention is enabled, but presence heartbeat is unavailable.",
            .heartbeatActive: "Sleep prevention and presence heartbeat are active.",
            .powerAssertionActive: "Preventing system idle sleep.",
            .alwaysActive: "Always active",
            .allDay: "All day",
            .cannotUpdateLoginItem: "Unable to update Launch at Login: %@",
            .cannotCreateHeartbeat: "Unable to send a presence heartbeat.",
            .scheduleLabel: "Schedule: %@",
            .accessibilityGranted: "Accessibility granted",
            .lastPresence: "Last presence heartbeat",
            .settings: "Settings…",
            .quit: "Quit",
            .loginEnabled: "Enabled",
            .loginRequiresApproval: "Awaiting approval in System Settings",
            .loginDisabled: "Disabled",
            .loginNotFound: "Launch at Login service not found",
            .loginUnknown: "Unknown",
            .systemAssertionName: "Wake Pilot is keeping your Mac awake.",
            .systemAssertionError: "Unable to create a system sleep assertion (code %d).",
            .displayAssertionName: "Wake Pilot is keeping the display awake.",
            .displayAssertionError: "Unable to create a display sleep assertion (code %d)."
        ],
        .japanese: [
            .activitySection: "動作",
            .enableWakePilot: "Wake Pilotを有効にする",
            .keepDisplayAwake: "画面を点灯したままにする",
            .keepChatActive: "チャットのオンライン状態を維持",
            .presenceInterval: "プレゼンスの間隔",
            .minutes: "%d分",
            .scheduleSection: "稼働スケジュール",
            .scheduleEnabled: "時間帯を指定して稼働",
            .scheduleStart: "開始",
            .scheduleEnd: "終了",
            .scheduleCurrent: "現在のスケジュール: %@。深夜をまたぐ時間帯にも対応し、終了時刻は含まれません。",
            .scheduleAlwaysOn: "Wake Pilotは有効な間、常に動作します。",
            .systemPermissionsSection: "システムアクセス",
            .accessibility: "アクセシビリティ",
            .permissionGranted: "許可済み",
            .permissionNotGranted: "未許可",
            .grantPermission: "アクセスを許可…",
            .presenceExplanation: "プレゼンス ハートビートは、選択した時間だけ操作がない場合に Shift キーを一度送信します。",
            .startupSection: "起動",
            .launchAtLogin: "ログイン時にWake Pilotを開く",
            .status: "ステータス",
            .openLoginItemsSettings: "ログイン項目の設定を開く…",
            .notesSection: "注意",
            .notesExplanation: "スリープ防止にはIOKit power assertionを使用します。プレゼンス ハートビートにはアクセシビリティへのアクセスが必要で、すべてのチャットアプリで認識されるとは限りません。ロック画面、MDM、組織のセキュリティポリシーを回避するものではありません。",
            .errorsSection: "エラー",
            .languageSection: "言語",
            .appVersion: "バージョン %@",
            .paused: "一時停止中",
            .outsideScheduledTime: "時間外",
            .accessibilityRequired: "アクセシビリティへのアクセスが必要",
            .active: "動作中",
            .sleepMayResume: "Macはシステム設定に従ってスリープすることがあります。",
            .resumesAt: "Wake Pilotは%@から再開します。",
            .heartbeatUnavailable: "スリープ防止は有効ですが、プレゼンス ハートビートは利用できません。",
            .heartbeatActive: "スリープ防止とプレゼンス ハートビートが有効です。",
            .powerAssertionActive: "システムのアイドルスリープを防止しています。",
            .alwaysActive: "常に動作",
            .allDay: "終日",
            .cannotUpdateLoginItem: "ログイン時に開く設定を更新できません: %@",
            .cannotCreateHeartbeat: "プレゼンス ハートビートを送信できません。",
            .scheduleLabel: "スケジュール: %@",
            .accessibilityGranted: "アクセシビリティが許可されています",
            .lastPresence: "直近のプレゼンス",
            .settings: "設定…",
            .quit: "終了",
            .loginEnabled: "有効",
            .loginRequiresApproval: "システム設定での承認待ち",
            .loginDisabled: "無効",
            .loginNotFound: "ログイン項目サービスが見つかりません",
            .loginUnknown: "不明",
            .systemAssertionName: "Wake PilotがMacをスリープさせないようにしています。",
            .systemAssertionError: "システムスリープ防止を作成できません (コード %d)。",
            .displayAssertionName: "Wake Pilotが画面を点灯したままにしています。",
            .displayAssertionError: "画面スリープ防止を作成できません (コード %d)。"
        ]
    ]
}
