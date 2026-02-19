import ProjectDescription

// MARK: - Settings

extension Project {
    public static func makeProjectSettings() -> Settings {
        .settings(
            base: [
                "ENABLE_USER_SCRIPT_SANDBOXING": false,
                "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": true,
                // Critical for certain packages to work
                "OTHER_LDFLAGS": "$(inherited) -ObjC"
                // Swift 6 opt in
    //                "SWIFT_UPCOMING_FEATURE_CONCISE_MAGIC_FILE": true,
    //                "SWIFT_UPCOMING_FEATURE_DEPRECATE_APPLICATION_MAIN": true,
    //                "SWIFT_UPCOMING_FEATURE_DISABLE_OUTWARD_ACTOR_ISOLATION": true,
    //                "SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY": true,
    //                "SWIFT_UPCOMING_FEATURE_FORWARD_TRAILING_CLOSURES": true,
    //                "SWIFT_UPCOMING_FEATURE_GLOBAL_CONCURRENCY": true,
    //                "SWIFT_UPCOMING_FEATURE_IMPLICIT_OPEN_EXISTENTIALS": true,
    //                "SWIFT_UPCOMING_FEATURE_IMPORT_OBJC_FORWARD_DECLS": true,
    //                "SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES": true,
    //                "SWIFT_UPCOMING_FEATURE_INTERNAL_IMPORTS_BY_DEFAULT": true,
    //                "SWIFT_UPCOMING_FEATURE_ISOLATED_DEFAULT_VALUES": true,
    //                "SWIFT_UPCOMING_FEATURE_REGION_BASED_ISOLATION": true,
    //                "SWIFT_STRICT_CONCURRENCY": "complete"
            ],
            configurations: [
                .debug(
                    name: "Debug"
                ),
                .release(
                    name: "Release",
                    settings: [
                        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "RELEASE"
                    ]
                ),
                .release(
                    name: "AdHoc",
                    settings: [
                        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "ADHOC"
                    ]
                )
            ]
        )
    }

    public static func makePackageSettings() -> PackageSettings {
        PackageSettings(
            baseSettings: .settings(
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release"),
                    .release(name: "AdHoc")
                ]
            )
        )
    }

    public static func makeMainTargetSettings(marketingVersion: String, currentProjectVersion: String) -> Settings {
        .settings(
            base: [
                "INFOPLIST_KEY_CFBundleDisplayName": "Demo",
                "MARKETING_VERSION": SettingValue(stringLiteral: marketingVersion),
                "CURRENT_PROJECT_VERSION": SettingValue(stringLiteral: currentProjectVersion),
                "DEVELOPMENT_TEAM": "F6J8B455GU",
                "CODE_SIGN_STYLE": "Manual"
            ],
            configurations: [
               .debug(
                   name: "Debug",
                   settings: [
                       "CODE_SIGN_IDENTITY": "iPhone Developer",
                       "PROVISIONING_PROFILE_SPECIFIER": "match Development com.cardinalblue-package-demo"
                   ],
                   xcconfig: nil
               ),
               .release(
                   name: "AdHoc",
                   settings: [
                       "CODE_SIGN_IDENTITY": "iPhone Distribution",
                       "PROVISIONING_PROFILE_SPECIFIER": "match AdHoc com.cardinalblue-package-demo"
                   ],
                   xcconfig: nil
               ),
               .release(
                   name: "Release",
                   settings: [
                       "CODE_SIGN_IDENTITY": "iPhone Distribution",
                       "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.cardinalblue-package-demo"
                   ],
                   xcconfig: nil
               )
           ],
           defaultSettings: .recommended
        )
    }
}

// MARK: - Plists

extension Project {
    public static func makeMainPlist(marketingVersion: String, currentProjectVersion: String) -> InfoPlist {
        .extendingDefault(with: [
            "CFBundleShortVersionString": Plist.Value(stringLiteral: marketingVersion),
            "CFBundleVersion": Plist.Value(stringLiteral: currentProjectVersion),
            "UIRequiresFullScreen": true,
            "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
            "FirebaseAppDelegateProxyEnabled": false,
            "UILaunchStoryboardName": "LaunchScreen.storyboard",
            "UIAppFonts": [
                // Add fonts here
                // "Figtree-Black.ttf"
            ]
        ])
    }
}

// MARK: - Sources

extension Project {
    public static func makeMainSources() -> SourceFilesList {
        [
            "Demo/**"
        ]
    }
}

// MARK: - Resources

extension Project {
    public static func makeMainResources() -> ResourceFileElements {
        [
            "Demo/Assets.xcassets",
            "Demo/Color.xcassets",
            "Demo/LaunchScreen.storyboard",
            "Demo/Preview Content/Preview Assets.xcassets",
            "PrivacyInfo.xcprivacy"

            // Include other non-swift files here as needed
            // "GoogleService-Info.plist"
        ]
    }
}

// MARK: - Dependencies

extension Project {
    public static func makeMainDependencies() -> [TargetDependency] {
        [
            .external(name: "CBAssistiveTouch")
        ]
    }
}
