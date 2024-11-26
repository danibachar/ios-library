/* Copyright Airship and Contributors */

import XCTest
import XcodeEdit

class ProjectValidationTest: XCTestCase {

    var sourceRootURL: URL?
    var xcodeProject: XCProjectFile?

    override func setUp() {
        super.setUp()
        let infoPlistDict =
            NSDictionary(
                contentsOfFile: Bundle(for: type(of: self))
                    .path(
                        forResource: "Info",
                        ofType: "plist"
                    )!
            ) as! [String: AnyObject]

        // The xcodeproj file to load
        let projectFilePath = infoPlistDict["PROJECT_FILE_PATH"] as! String
        let xcodeprojPath = URL(fileURLWithPath: projectFilePath)

        // Load from the xcodeproj file
        do {
            xcodeProject = try XCProjectFile(xcodeprojURL: xcodeprojPath)
        } catch let error {
            XCTFail(
                "Unable to load xcodeproj file - \(String(describing:error))"
            )
            return
        }
        XCTAssert(
            xcodeProject != nil,
            "Unable to load xcodeproj file - something wrong with the plist?"
        )

        // path to the source root
        sourceRootURL = xcodeprojPath.deletingLastPathComponent()
        XCTAssert(sourceRootURL != nil)
    }

    func testAirshipCore() {
        validateTarget(
            target: "AirshipCore",
            sourcePaths: [
                "AirshipCore/Source/Internal", "AirshipCore/Source/Public",
                "AirshipCore/Source",
            ]
        )
    }

    func testAirshipAutomation() {
        validateTarget(
            target: "AirshipAutomation",
            sourcePaths: ["AirshipAutomation/Source"]
        )
    }

    func testAirshipMessageCenter() {
        validateTarget(
            target: "AirshipMessageCenter",
            sourcePaths: ["AirshipMessageCenter/Source"]
        )
    }

    func convertSourceTreeFolderToURL(sourceTreeFolder: SourceTreeFolder) -> URL
    {
        if sourceTreeFolder != .sourceRoot {
            XCTFail(
                "SourceTreeFolders other than .sourceRoot are not currently supported by this tool"
            )
        }
        return sourceRootURL!
    }

    func getSourceFiles(target: String) -> [URL] {
        let target: PBXTarget = xcodeProject!.project.targets
            .first {
                $0.value?.name == target
            }!
            .value!

        let sourceBuildPhases: [PBXBuildPhase] = target.buildPhases
            .compactMap { $0.value }
            .filter {
                type(of: ($0)) == XcodeEdit.PBXHeadersBuildPhase.self
                    || type(of: ($0)) == XcodeEdit.PBXSourcesBuildPhase.self
            }

        let sourceFiles: [URL] =
            sourceBuildPhases
            .flatMap { $0.files }
            .compactMap { $0.value?.fileRef?.value as? PBXFileReference }
            .compactMap { $0.fullPath?.url(with: convertSourceTreeFolderToURL) }

        return sourceFiles
    }

    func getSourceFiles(directories: [URL]) -> [URL] {
        let fileManager = FileManager.default
        let souceExtensions = ["swift", "m", "h"]

        return
            directories.compactMap { (directory) -> [URL] in
                fileManager.enumerator(atPath: directory.path)?.allObjects
                    .compactMap { $0 as? String }
                    .compactMap { directory.appendingPathComponent($0) } ?? []
            }
            .flatMap { $0 }
            .filter { souceExtensions.contains($0.pathExtension) }
    }

    func validateTarget(
        target: String,
        sourcePaths: [String],
        excludeFiles: [String] = []
    ) {
        guard let sourceRootURL = self.sourceRootURL else {
            XCTFail("Source root is nil - check xcodeprojPath")
            return
        }

        let excludeUrls = excludeFiles.compactMap {
            sourceRootURL.appendingPathComponent($0)
        }
        let directories = sourcePaths.compactMap {
            sourceRootURL.appendingPathComponent($0)
        }

        let filesFromTarget = Set(getSourceFiles(target: target))
        XCTAssertFalse(filesFromTarget.isEmpty)

        let filesFromDirectories = Set(getSourceFiles(directories: directories))
        XCTAssertFalse(filesFromDirectories.isEmpty)

        let missingFilesFromTarget =
            filesFromDirectories
            .subtracting(filesFromTarget)
            .filter { !excludeUrls.contains($0) }

        let filesWrongDirectory = filesFromTarget.subtracting(
            filesFromDirectories
        )

        XCTAssertTrue(
            missingFilesFromTarget.isEmpty,
            "Missing: \(missingFilesFromTarget) from target \(target)"
        )
        XCTAssertTrue(
            filesWrongDirectory.isEmpty,
            "Files: \(filesWrongDirectory) not in source directories \(sourcePaths)"
        )
    }
}
