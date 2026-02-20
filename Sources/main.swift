import Foundation
import Velt

let screenW: Int32 = 360
let screenH: Int32 = 800

startApp(
    RouterView(
        initialPath: "/",
        routes: [
            Route("/", builder: { DashboardScreen() }),
            Route("/about", builder: { AboutScreen() }),
            Route("/settings", builder: { SettingsScreen() }),
            Route("/gallery", builder: { GalleryScreen() }),
            Route("/material3", builder: { Material3DemoScreen() }),
        ]
    ),
    width: screenW,
    height: screenH,
    debug: false
)
