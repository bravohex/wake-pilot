import XCTest
@testable import BrHxWakePilot

final class AppLocalizationTests: XCTestCase {
    func testEveryLanguageContainsEveryTranslation() {
        for language in AppLanguage.allCases {
            for key in AppStrings.Key.allCases {
                XCTAssertFalse(
                    AppStrings.text(key, language: language).isEmpty,
                    "Missing \(key) for \(language)"
                )
            }
        }
    }

    func testFormatsLocalizedValues() {
        XCTAssertEqual(
            AppStrings.format(
                .minutes,
                language: .japanese,
                arguments: [3]
            ),
            "3分"
        )
    }
}
