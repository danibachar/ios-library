/* Copyright Airship and Contributors */

import Combine
import Foundation
import SwiftUI

@available(iOS 13.0.0, tvOS 13.0, *)
struct FormVisibilityViewModifier: ViewModifier {
    @Environment(\.isVisible) private var isVisible
    @EnvironmentObject var formState: FormState

    @ViewBuilder
    func body(content: Content) -> some View {
        content.onChange(of: isVisible) { newValue in
            if newValue {
                formState.markVisible()
            }
        }

    }
}

@available(iOS 14.0.0, tvOS 14.0, *)
struct FormInputEnabledViewModifier: ViewModifier {
    @EnvironmentObject var formState: FormState

    @ViewBuilder
    func body(content: Content) -> some View {
        content.disabled(!formState.isEnabled)
    }
}

@available(iOS 14.0.0, tvOS 14.0, *)
extension View {
    @ViewBuilder
    func formElement() -> some View {
        self.modifier(FormVisibilityViewModifier())
            .modifier(FormInputEnabledViewModifier())
    }
}
