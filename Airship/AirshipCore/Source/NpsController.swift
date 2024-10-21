/* Copyright Airship and Contributors */

import Combine
import Foundation
import SwiftUI


struct NpsController: View {
    let model: NpsControllerModel
    let constraints: ViewConstraints

    @StateObject var formState: FormState

    @MainActor
    init(model: NpsControllerModel, constraints: ViewConstraints) {
        self.model = model
        self.constraints = constraints
        self._formState = StateObject(
            wrappedValue: FormState(
                identifier: model.identifier,
                formType: .nps(model.npsIdentifier),
                formResponseType: model.responseType
            )
        )
    }

    var body: some View {
        if model.submit != nil {
            ParentNpsController(
                model: model,
                constraints: constraints,
                formState: formState
            )
        } else {
            ChildNpsController(
                model: model,
                constraints: constraints,
                formState: formState
            )
        }
    }
}


private struct ParentNpsController: View {
    let model: NpsControllerModel
    let constraints: ViewConstraints

    @ObservedObject var formState: FormState
    @EnvironmentObject var thomasEnvironment: ThomasEnvironment
    @Environment(\.layoutState) var layoutState

    var body: some View {
        ViewFactory.createView(model: self.model.view, constraints: constraints)
            .background(
                color: self.model.backgroundColor,
                border: self.model.border
            )
            .common(self.model, formInputID: self.model.identifier)
            .enableBehaviors(self.model.formEnableBehaviors) { enabled in
                self.formState.isEnabled = enabled
            }
            .environmentObject(formState)
            .environment(
                \.layoutState,
                layoutState.override(formState: formState)
            )
            .airshipOnChangeOf(formState.isVisible) { [weak formState, weak thomasEnvironment] incoming in
                guard incoming, let formState, let thomasEnvironment else {
                    return
                }
                thomasEnvironment.formDisplayed(
                    formState,
                    layoutState: layoutState.override(
                        formState: formState
                    )
                )
            }
    }
}


private struct ChildNpsController: View {
    let model: NpsControllerModel
    let constraints: ViewConstraints

    @EnvironmentObject var parentFormState: FormState
    @ObservedObject var formState: FormState

    var body: some View {
        return
            ViewFactory.createView(
                model: self.model.view,
                constraints: constraints
            )
            .background(
                color: self.model.backgroundColor,
                border: self.model.border
            )
            .common(self.model, formInputID: self.model.identifier)
            .enableBehaviors(self.model.formEnableBehaviors) { enabled in
                self.formState.isEnabled = enabled
            }
            .environmentObject(formState)
            .onAppear {
                restoreFormState()
                self.formState.parentFormState = self.parentFormState
            }
    }

    private func restoreFormState() {
        guard
            let formData = self.parentFormState.data.formData(
                identifier: self.model.identifier
            ),
            case let .form(responseType, formType, children) = formData.value,
            responseType == self.model.responseType,
            case let .nps(scoreID) = formType,
            scoreID == self.model.npsIdentifier
        else {
            return
        }

        children.forEach {
            self.formState.updateFormInput($0)
        }
    }
}
