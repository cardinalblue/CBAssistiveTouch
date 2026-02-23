import ProjectDescription
import ProjectDescriptionHelpers

let marketingVersion = "1.0.0"
let currentProjectVersion = "1"
let deploymentTargets = DeploymentTargets.iOS("17.0")
let destinations: Destinations = [.iPhone]

let mainTarget = Target.target(
    name: "Demo",
    destinations: destinations,
    product: .app,
    productName: "CBAssistiveTouchDemo",
    bundleId: "com.cardinalblue.CBAssistiveTouch.package-demo",
    deploymentTargets: deploymentTargets,
    infoPlist: Project.makeMainPlist(
        marketingVersion: marketingVersion,
        currentProjectVersion: currentProjectVersion
    ),
    sources: Project.makeMainSources(),
    resources: Project.makeMainResources(),
    dependencies: Project.makeMainDependencies(),
    settings: Project.makeMainTargetSettings(
        marketingVersion: marketingVersion,
        currentProjectVersion: currentProjectVersion
    )
)

let project = Project(
    name: "Demo",
    organizationName: "Cardinal Blue",
    settings: Project.makeProjectSettings(),
    targets: [mainTarget]
)
