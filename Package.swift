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
    name: "protoc-gen-grpc-swift",
    targets: ["protoc-gen-grpc-swift"]
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
    url: "https://github.com/grpc/grpc-swift.git",
    from: "2.2.0"
  ),
  .package(
    url: "https://github.com/apple/swift-protobuf.git",
    from: "1.28.1"
  ),
]

let defaultSwiftSettings: [SwiftSetting] = [
  .swiftLanguageMode(.v6),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("InternalImportsByDefault"),
  .enableUpcomingFeature("MemberImportVisibility"),
]

var targets: [Target] = [
  // protoc plugin for grpc-swift
  .executableTarget(
    name: "protoc-gen-grpc-swift",
    dependencies: [
      .target(name: "GRPCProtobufCodeGen"),
      .product(name: "GRPCCodeGen", package: "grpc-swift"),
      .product(name: "SwiftProtobuf", package: "swift-protobuf"),
      .product(name: "SwiftProtobufPluginLibrary", package: "swift-protobuf"),
    ],
    swiftSettings: defaultSwiftSettings
  ),

  // Runtime serialization components
  .target(
    name: "GRPCProtobuf",
    dependencies: [
      .product(name: "GRPCCore", package: "grpc-swift"),
      .product(name: "SwiftProtobuf", package: "swift-protobuf"),
    ],
    swiftSettings: defaultSwiftSettings
  ),
  .testTarget(
    name: "GRPCProtobufTests",
    dependencies: [
      .target(name: "GRPCProtobuf"),
      .product(name: "GRPCCore", package: "grpc-swift"),
      .product(name: "GRPCInProcessTransport", package: "grpc-swift"),
      .product(name: "SwiftProtobuf", package: "swift-protobuf"),
    ],
    swiftSettings: defaultSwiftSettings
  ),

  // Code generator library for protoc-gen-grpc-swift
  .target(
    name: "GRPCProtobufCodeGen",
    dependencies: [
      .product(name: "GRPCCodeGen", package: "grpc-swift"),
      .product(name: "SwiftProtobufPluginLibrary", package: "swift-protobuf"),
    ],
    swiftSettings: defaultSwiftSettings
  ),
  .testTarget(
    name: "GRPCProtobufCodeGenTests",
    dependencies: [
      .target(name: "GRPCProtobufCodeGen"),
      .product(name: "GRPCCodeGen", package: "grpc-swift"),
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
      .target(name: "protoc-gen-grpc-swift"),
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
      .target(name: "protoc-gen-grpc-swift"),
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
    if target.name == "protoc-gen-grpc-swift" {
      target.dependencies.append(.target(name: "CGRPCProtobuf"))
    }
  }
}

// -------------------------------------------------------------------------------------------------

let package = Package(
  name: "grpc-swift-protobuf",
  platforms: [
    .macOS(.v15),
    .iOS(.v18),
    .tvOS(.v18),
    .watchOS(.v11),
    .visionOS(.v2),
  ],
  products: products,
  dependencies: dependencies,
  targets: targets
)
