/* Copyright Airship and Contributors */

public import SwiftUI
import Combine

// MARK: Channel text field
public struct ChannelTextField: View {
    @Environment(\.colorScheme) var colorScheme

    private let placeHolderPadding = EdgeInsets(top: 4, leading: 15, bottom: 4, trailing: 4)

    private var senders: [PreferenceCenterConfig.ContactManagementItem.SMSSenderInfo]?

    private var platform: PreferenceCenterConfig.ContactManagementItem.Platform?

    @Binding var selectedSender: PreferenceCenterConfig.ContactManagementItem.SMSSenderInfo

    @State var selectedSenderID: String = ""

    @Binding var inputText: String

    @State
    private var placeholder: String = ""

    private let fieldCornerRadius: CGFloat = 4

    /// The preference center theme
    var theme: PreferenceCenterTheme.ContactManagement?

    private var smsOptions: PreferenceCenterConfig.ContactManagementItem.SMS?
    private var emailOptions: PreferenceCenterConfig.ContactManagementItem.Email?

    public init(
        platform: PreferenceCenterConfig.ContactManagementItem.Platform?,
        selectedSender: Binding<PreferenceCenterConfig.ContactManagementItem.SMSSenderInfo>,
        inputText: Binding<String>,
        theme: PreferenceCenterTheme.ContactManagement?
    ) {
        self.platform = platform
        _selectedSender = selectedSender
        _inputText = inputText

        self.theme = theme

        if let platform = self.platform {
            switch platform {
            case .sms(let options):
                self.senders = options.senders
                smsOptions = options
            case .email(let options):
                emailOptions = options
            }
        }

        self.placeholder = makePlaceholder()
    }

    public var body: some View {
        countryPicker
        VStack {
            HStack(spacing:2) {
                textFieldLabel
                textField
            }
            .padding(10)
            .background(backgroundView)
        }
    }

    @ViewBuilder
    private var countryPicker: some View {
        if let senders = self.senders, (senders.count >= 1) {
            HStack(spacing:10) {
                if let smsOptions = smsOptions {
                    Text(smsOptions.countryLabel)
                }
                Spacer()
                Picker("senders", selection: $selectedSenderID) {
                    ForEach(senders, id: \.self) {
                        Text($0.displayName).tag($0.senderId)
                    }
                }
                .accentColor(DefaultColors.primaryText)
                .airshipOnChangeOf(self.selectedSenderID, { newVal in
                    if let sender = senders.first(where: { $0.senderId == newVal }) {
                        selectedSender = sender
                        /// Update placeholder with selection
                        placeholder = makePlaceholder()
                    }
                })
                .onAppear {
                    /// Ensure initial value is set
                    if let sender = self.senders?.first {
                        self.selectedSenderID = sender.senderId
                    }
                }
            }
            .padding(10)
            .background(backgroundView)
        }
    }

    private var textField: some View {
        TextField(makePlaceholder(), text: $inputText)
            .padding(self.placeHolderPadding)
            .keyboardType(keyboardType)
    }

    @ViewBuilder
    private var textFieldLabel: some View {
        if let smsOptions = smsOptions {
            Text(smsOptions.msisdnLabel)
        } else if let emailOptions = emailOptions {
            Text(emailOptions.addressLabel)
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        let backgroundColor = theme?.backgroundColor ?? DefaultContactManagementSectionStyle.backgroundColor

        RoundedRectangle(cornerRadius: fieldCornerRadius).foregroundColor(backgroundColor.secondaryVariant(for: colorScheme).opacity(0.2))
    }

    // MARK: Keyboard type
    private var keyboardType: UIKeyboardType {
        if let platform = self.platform {
            switch platform {
            case .sms(_):
                return .decimalPad
            case .email(_):
                return .emailAddress
            }
        } else {
            return .default
        }
    }

    // MARK: Placeholder
    private func makePlaceholder() -> String {
        let defaultPlaceholder = ""
        if let platform = self.platform {
            switch platform {
            case .sms(_):
                return self.selectedSender.placeholderText
            case .email(let emailRegistrationOption):
                return emailRegistrationOption.placeholder ?? defaultPlaceholder
            }
        } else {
            return defaultPlaceholder
        }
    }
}
