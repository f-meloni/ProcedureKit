import PackageDescription

let package = Package(
    name: "ProcedureKit",

    targets: [

        /** ProcedureKit libraries */
        Target(name: "ProcedureKit"),

        Target(
            name: "ProcedureKitCloud",
            dependencies: ["ProcedureKit"]),

        Target(
            name: "ProcedureKitLocation",
            dependencies: ["ProcedureKit"]),

        Target(
            name: "ProcedureKitMac",
            dependencies: ["ProcedureKit"]),

        Target(
            name: "ProcedureKitNetwork",
            dependencies: ["ProcedureKit"])
    ],

    exclude: [
        "Sources/ProcedureKitMobile",
        "Sources/ProcedureKitTV",
        "Tests/ProcedureKitMobileTests",
        "Tests/ProcedureKitTVTests",
    ]
)
