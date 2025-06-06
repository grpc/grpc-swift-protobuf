// swift-tools-version: 6.0
/*
 * Copyright 2024, gRPC Authors All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import PackageDescription

let products: [Product] = [
  .library(
    name: "GRPCProtobuf",
    targets: ["GRPCProtobuf"]
  ),
  .executable(
    name: "protoc-gen-grpc-swift-2",
    targets: ["protoc-gen-grpc-swift-2"]
  ),
  .plugin(
    name: "GRPCProtobufGenerator",
    targets: ["GRPCProtobufGenerator"]
  ),
  .plugin(
    name: "generate-grpc-code-from-protos",
    targets: ["generate-grpc-code-from-protos"]
  ),
]

let dependencies: [Package.Dependency] = [
  .package(
    url: "https://github.com/grpc/grpc-swift-2.git",
    from: "2.0.0"
  ),
  .package(
    url: "https://github.com/apple/swift-protobuf.git",
    from: "1.28.1"
  ),
]

// -------------------------------------------------------------------------------------------------

// This adds some build settings which allow us to map "@available(gRPCSwiftProtobuf 2.x, *)" to
// the appropriate OS platforms.
let nextMinorVersion = 1
let availabilitySettings: [SwiftSetting] = (0 ... nextMinorVersion).map { minor in
  let name = "gRPCSwiftProtobuf"
  let version = "2.\(minor)"
  let platforms = "macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0"
  let setting = "AvailabilityMacro=\(name) \(version):\(platforms)"
  return .enableExperimentalFeature(setting)
}

let defaultSwiftSettings: [SwiftSetting] =
  availabilitySettings + [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
  ]

// -------------------------------------------------------------------------------------------------

var targets: [Target] = [
  // protoc plugin for grpc-swift-2
  .executableTarget(
    name: "protoc-gen-grpc-swift-2",
    dependencies: [
      .target(name: "GRPCProtobufCodeGen"),
      .product(name: "GRPCCodeGen", package: "grpc-swift-2"),
      .product(name: "SwiftProtobuf", package: "swift-protobuf"),
      .product(name: "SwiftProtobufPluginLibrary", package: "swift-protobuf"),
    ],
    swiftSettings: defaultSwiftSettings
  ),

  // Runtime serialization components
  .target(
    name: "GRPCProtobuf",
    dependencies: [
      .product(name: "GRPCCore", package: "grpc-swift-2"),
      .product(name: "SwiftProtobuf", package: "swift-protobuf"),
    ],
    swiftSettings: defaultSwiftSettings
  ),
  .testTarget(
    name: "GRPCProtobufTests",
    dependencies: [
      .target(name: "GRPCProtobuf"),
      .product(name: "GRPCCore", package: "grpc-swift-2"),
      .product(name: "GRPCInProcessTransport", package: "grpc-swift-2"),
      .product(name: "SwiftProtobuf", package: "swift-protobuf"),
    ],
    swiftSettings: defaultSwiftSettings
  ),

  // Code generator library for protoc-gen-grpc-swift-2
  .target(
    name: "GRPCProtobufCodeGen",
    dependencies: [
      .product(name: "GRPCCodeGen", package: "grpc-swift-2"),
      .product(name: "SwiftProtobufPluginLibrary", package: "swift-protobuf"),
    ],
    swiftSettings: defaultSwiftSettings
  ),
  .testTarget(
    name: "GRPCProtobufCodeGenTests",
    dependencies: [
      .target(name: "GRPCProtobufCodeGen"),
      .product(name: "GRPCCodeGen", package: "grpc-swift-2"),
      .product(name: "SwiftProtobuf", package: "swift-protobuf"),
      .product(name: "SwiftProtobufPluginLibrary", package: "swift-protobuf"),
    ],
    resources: [
      .copy("Generated")
    ],
    swiftSettings: defaultSwiftSettings
  ),

  // Code generator build plugin
  .plugin(
    name: "GRPCProtobufGenerator",
    capability: .buildTool(),
    dependencies: [
      .target(name: "protoc-gen-grpc-swift-2"),
      .product(name: "protoc-gen-swift", package: "swift-protobuf"),
    ]
  ),

  // Code generator SwiftPM command
  .plugin(
    name: "generate-grpc-code-from-protos",
    capability: .command(
      intent: .custom(
        verb: "generate-grpc-code-from-protos",
        description: "Generate Swift code for gRPC services from protobuf definitions."
      ),
      permissions: [
        .writeToPackageDirectory(
          reason:
            "To write the generated Swift files back into the source directory of the package."
        )
      ]
    ),
    dependencies: [
      .target(name: "protoc-gen-grpc-swift-2"),
      .product(name: "protoc-gen-swift", package: "swift-protobuf"),
    ],
    path: "Plugins/GRPCProtobufGeneratorCommand"
  ),
]

// -------------------------------------------------------------------------------------------------

extension Context {
  fileprivate static var versionString: String {
    guard let git = Self.gitInformation else { return "" }

    if let tag = git.currentTag {
      return tag
    } else {
      let suffix = git.hasUncommittedChanges ? " (modified)" : ""
      return git.currentCommit + suffix
    }
  }

  fileprivate static var buildCGRPCProtobuf: Bool {
    let noVersion = Context.environment.keys.contains("GRPC_SWIFT_PROTOBUF_NO_VERSION")
    return !noVersion
  }
}

// Having a C module as a transitive dependency of a plugin seems to trip up the API breakage
// checking tool. See also https://github.com/swiftlang/swift-package-manager/issues/8081
//
// The CGRPCProtobuf module (which only includes package version information) is conditionally
// compiled and included based on an environment variable. This is set in CI only for the API
// breakage checking job to avoid tripping up SwiftPM.
if Context.buildCGRPCProtobuf {
  targets.append(
    .target(
      name: "CGRPCProtobuf",
      cSettings: [
        .define("CGRPC_GRPC_SWIFT_PROTOBUF_VERSION", to: "\"\(Context.versionString)\"")
      ]
    )
  )

  for target in targets {
    if target.name == "protoc-gen-grpc-swift-2" {
      target.dependencies.append(.target(name: "CGRPCProtobuf"))
    }
  }
}

// -------------------------------------------------------------------------------------------------

let package = Package(
  name: "grpc-swift-protobuf",
  products: products,
  dependencies: dependencies,
  targets: targets
)
