/* Copyright Airship and Contributors */

import Foundation
import UIKit

#if canImport(AirshipCore)
import AirshipCore
#endif

/// Wraps a custom display adapter as a DisplayAdapter
final class CustomDisplayAdapterWrapper: DisplayAdapter {
    let adapter: CustomDisplayAdapter

    var isReady: Bool { return adapter.isReady }

    func waitForReady() async {
        await adapter.waitForReady()
    }

    init(
        adapter: CustomDisplayAdapter
    ) {
        self.adapter = adapter
    }

    func display(scene: WindowSceneHolder, analytics: InAppMessageAnalyticsProtocol) async {
        analytics.recordEvent(InAppDisplayEvent(), layoutContext: nil)

        let timer = ActiveTimer()
        timer.start()
        let result = await self.adapter.display(scene: scene.scene)
        timer.stop()

        switch(result) {
        case .buttonTap(let buttonInfo):
            analytics.recordEvent(
                InAppResolutionEvent.buttonTap(
                    identifier: buttonInfo.identifier,
                    description: buttonInfo.label.text,
                    displayTime: timer.time
                ),
                layoutContext: nil
            )
        case .messageTap:
            analytics.recordEvent(
                InAppResolutionEvent.messageTap(displayTime: timer.time),
                layoutContext: nil
            )
        case .userDismissed:
            analytics.recordEvent(
                InAppResolutionEvent.userDismissed(displayTime: timer.time),
                layoutContext: nil
            )
        case .timedOut:
            analytics.recordEvent(
                InAppResolutionEvent.timedOut(displayTime: timer.time),
                layoutContext: nil
            )
        }
    }
}
