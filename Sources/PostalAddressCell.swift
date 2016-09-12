//
//  PostalAddressCell.swift
//  PostalAddressRow
//
//  Created by Mathias Claassen on 9/13/16.
//
//

import Foundation
import Eureka

// MARK: PostalAddressCell

/**
 *  Protocol for cells that contain a postal address
 */
public protocol PostalAddressCellConformance {
    var streetTextField: UITextField? { get }
    var stateTextField: UITextField? { get }
    var postalCodeTextField: UITextField? { get }
    var cityTextField: UITextField? { get }
    var countryTextField: UITextField? { get }
}

/// Base class that implements the cell logic for the PostalAddressRow
open class _PostalAddressCell<T: PostalAddressType>: Cell<T>, CellType, PostalAddressCellConformance, UITextFieldDelegate {

    @IBOutlet open var streetTextField: UITextField?
    @IBOutlet open var firstSeparatorView: UIView?
    @IBOutlet open var stateTextField: UITextField?
    @IBOutlet open var postalCodeTextField: UITextField?
    @IBOutlet open var cityTextField: UITextField?
    @IBOutlet open var secondSeparatorView: UIView?
    @IBOutlet open var countryTextField: UITextField?

    @IBOutlet weak var postalPercentageConstraint: NSLayoutConstraint?

    open var textFieldOrdering: [UITextField?] = []

    public required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        textFieldOrdering = [streetTextField, postalCodeTextField, cityTextField, stateTextField, countryTextField]
    }

    deinit {
        streetTextField?.delegate = nil
        streetTextField?.removeTarget(self, action: nil, for: .allEvents)
        stateTextField?.delegate = nil
        stateTextField?.removeTarget(self, action: nil, for: .allEvents)
        postalCodeTextField?.delegate = nil
        postalCodeTextField?.removeTarget(self, action: nil, for: .allEvents)
        cityTextField?.delegate = nil
        cityTextField?.removeTarget(self, action: nil, for: .allEvents)
        countryTextField?.delegate = nil
        countryTextField?.removeTarget(self, action: nil, for: .allEvents)
        imageView?.removeObserver(self, forKeyPath: "image")
    }

    open override func setup() {
        super.setup()
        height = { 120 }
        selectionStyle = .none

        postalPercentageConstraint?.constant = (row as? PostalAddressRowConformance)?.postalAddressPercentage ?? 0.5

        imageView?.addObserver(self, forKeyPath: "image", options: NSKeyValueObservingOptions.old.union(.new), context: nil)

        for textField in textFieldOrdering {
            textField?.addTarget(self, action: #selector(PostalAddressCell.textFieldDidChange(_:)), for: .editingChanged)
            textField?.textAlignment =  .left
            textField?.clearButtonMode =  .whileEditing
            textField?.delegate = self
            textField?.font = .preferredFont(forTextStyle: UIFontTextStyle.body)
        }

        for separator in [firstSeparatorView, secondSeparatorView] {
            separator?.backgroundColor = .gray
        }
    }

    open override func update() {
        super.update()
        detailTextLabel?.text = nil

        for textField in textFieldOrdering {
            textField?.isEnabled = !row.isDisabled
            textField?.textColor = row.isDisabled ? .gray : .black
            textField?.autocorrectionType = .no
            textField?.autocapitalizationType = .words
        }

        streetTextField?.text = row.value?.street
        streetTextField?.keyboardType = .asciiCapable

        stateTextField?.text = row.value?.state
        stateTextField?.keyboardType = .asciiCapable

        postalCodeTextField?.text = row.value?.postalCode
        postalCodeTextField?.keyboardType = .numbersAndPunctuation

        cityTextField?.text = row.value?.city
        cityTextField?.keyboardType = .asciiCapable

        countryTextField?.text = row.value?.country
        countryTextField?.keyboardType = .asciiCapable

        if let rowConformance = row as? PostalAddressRowConformance {
            setPlaceholderToTextField(textField: streetTextField, placeholder: rowConformance.streetPlaceholder)
            setPlaceholderToTextField(textField: stateTextField, placeholder: rowConformance.statePlaceholder)
            setPlaceholderToTextField(textField: postalCodeTextField, placeholder: rowConformance.postalCodePlaceholder)
            setPlaceholderToTextField(textField: cityTextField, placeholder: rowConformance.cityPlaceholder)
            setPlaceholderToTextField(textField: countryTextField, placeholder: rowConformance.countryPlaceholder)
        }
    }

    private func setPlaceholderToTextField(textField: UITextField?, placeholder: String?) {
        if let placeholder = placeholder, let textField = textField {
            if let color = (row as? PostalAddressRowConformance)?.placeholderColor {
                textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSForegroundColorAttributeName: color])
            } else {
                textField.placeholder = placeholder
            }
        }
    }

    open override func cellCanBecomeFirstResponder() -> Bool {
        return !row.isDisabled && (
            streetTextField?.canBecomeFirstResponder == true ||
                stateTextField?.canBecomeFirstResponder == true ||
                postalCodeTextField?.canBecomeFirstResponder == true ||
                cityTextField?.canBecomeFirstResponder == true ||
                countryTextField?.canBecomeFirstResponder == true
        )
    }

    open override func cellBecomeFirstResponder(withDirection direction: Direction) -> Bool {
        return direction == .down ? textFieldOrdering.first??.becomeFirstResponder() ?? false : textFieldOrdering.last??.becomeFirstResponder() ?? false
    }

    open override func cellResignFirstResponder() -> Bool {
        return streetTextField?.resignFirstResponder() ?? true
            && stateTextField?.resignFirstResponder() ?? true
            && postalCodeTextField?.resignFirstResponder() ?? true
            && stateTextField?.resignFirstResponder() ?? true
            && cityTextField?.resignFirstResponder() ?? true
            && countryTextField?.resignFirstResponder() ?? true
    }

    override open var inputAccessoryView: UIView? {
        if let v = formViewController()?.inputAccessoryView(for: row) as? NavigationAccessoryView {
            guard let first = textFieldOrdering.first, let last = textFieldOrdering.last, first != last else { return v }

            if first?.isFirstResponder == true {
                v.nextButton.isEnabled = true
                v.nextButton.target = self
                v.nextButton.action = #selector(PostalAddressCell.internalNavigationAction(_:))
            }
            else if last?.isFirstResponder == true {
                v.previousButton.target = self
                v.previousButton.action = #selector(PostalAddressCell.internalNavigationAction(_:))
                v.previousButton.isEnabled = true
            }
            else {
                v.previousButton.target = self
                v.previousButton.action = #selector(PostalAddressCell.internalNavigationAction(_:))
                v.nextButton.target = self
                v.nextButton.action = #selector(PostalAddressCell.internalNavigationAction(_:))
                v.previousButton.isEnabled = true
                v.nextButton.isEnabled = true
            }
            return v
        }
        return super.inputAccessoryView
    }

    func internalNavigationAction(_ sender: UIBarButtonItem) {
        guard let inputAccesoryView  = inputAccessoryView as? NavigationAccessoryView else { return }

        var index = 0
        for field in textFieldOrdering {
            if field?.isFirstResponder == true {
                let _ = sender == inputAccesoryView.previousButton ? textFieldOrdering[index-1]?.becomeFirstResponder() : textFieldOrdering[index+1]?.becomeFirstResponder()
                break
            }
            index += 1
        }
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let obj = object as AnyObject?

        if let keyPathValue = keyPath, let changeType = change?[NSKeyValueChangeKey.kindKey], (obj === imageView && keyPathValue == "image") && (changeType as? NSNumber)?.uintValue == NSKeyValueChange.setting.rawValue {
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
        }
    }

    open func textFieldDidChange(_ textField : UITextField){
        if row.baseValue == nil{
            row.baseValue = PostalAddress()
        }

        guard let textValue = textField.text else {
            switch(textField){
            case let field where field == streetTextField:
                row.value?.street = nil

            case let field where field == stateTextField:
                row.value?.state = nil

            case let field where field == postalCodeTextField:
                row.value?.postalCode = nil
            case let field where field == cityTextField:
                row.value?.city = nil

            case let field where field == countryTextField:
                row.value?.country = nil

            default:
                break
            }
            return
        }

        if let rowConformance = row as? PostalAddressRowConformance{
            var useFormatterDuringInput = false
            var valueFormatter: Formatter?

            switch(textField){
            case let field where field == streetTextField:
                useFormatterDuringInput = rowConformance.streetUseFormatterDuringInput
                valueFormatter = rowConformance.streetFormatter

            case let field where field == stateTextField:
                useFormatterDuringInput = rowConformance.stateUseFormatterDuringInput
                valueFormatter = rowConformance.stateFormatter

            case let field where field == postalCodeTextField:
                useFormatterDuringInput = rowConformance.postalCodeUseFormatterDuringInput
                valueFormatter = rowConformance.postalCodeFormatter

            case let field where field == cityTextField:
                useFormatterDuringInput = rowConformance.cityUseFormatterDuringInput
                valueFormatter = rowConformance.cityFormatter

            case let field where field == countryTextField:
                useFormatterDuringInput = rowConformance.countryUseFormatterDuringInput
                valueFormatter = rowConformance.countryFormatter

            default:
                break
            }

            if let formatter = valueFormatter, useFormatterDuringInput{
                let value: AutoreleasingUnsafeMutablePointer<AnyObject?> = AutoreleasingUnsafeMutablePointer<AnyObject?>.init(UnsafeMutablePointer<T>.allocate(capacity: 1))
                let errorDesc: AutoreleasingUnsafeMutablePointer<NSString?>? = nil
                if formatter.getObjectValue(value, for: textValue, errorDescription: errorDesc) {

                    switch(textField){
                    case let field where field == streetTextField:
                        row.value?.street = value.pointee as? String
                    case let field where field == stateTextField:
                        row.value?.state = value.pointee as? String
                    case let field where field == postalCodeTextField:
                        row.value?.postalCode = value.pointee as? String
                    case let field where field == cityTextField:
                        row.value?.city = value.pointee as? String
                    case let field where field == countryTextField:
                        row.value?.country = value.pointee as? String
                    default:
                        break
                    }

                    if var selStartPos = textField.selectedTextRange?.start {
                        let oldVal = textField.text
                        textField.text = row.displayValueFor?(row.value)
                        if let f = formatter as? FormatterProtocol {
                            selStartPos = f.getNewPosition(forPosition: selStartPos, inTextInput: textField, oldValue: oldVal, newValue: textField.text)
                        }
                        textField.selectedTextRange = textField.textRange(from: selStartPos, to: selStartPos)
                    }
                    return
                }
            }
        }

        guard !textValue.isEmpty else {
            switch(textField){
            case let field where field == streetTextField:
                row.value?.street = nil
            case let field where field == stateTextField:
                row.value?.state = nil
            case let field where field == postalCodeTextField:
                row.value?.postalCode = nil
            case let field where field == cityTextField:
                row.value?.city = nil
            case let field where field == countryTextField:
                row.value?.country = nil
            default:
                break
            }
            return
        }

        switch(textField){
        case let field where field == streetTextField:
            row.value?.street = textValue
        case let field where field == stateTextField:
            row.value?.state = textValue
        case let field where field == postalCodeTextField:
            row.value?.postalCode = textValue
        case let field where field == cityTextField:
            row.value?.city = textValue
        case let field where field == countryTextField:
            row.value?.country = textValue
        default:
            break
        }
    }

    //MARK: TextFieldDelegate

    open func textFieldDidBeginEditing(_ textField: UITextField) {
        formViewController()?.beginEditing(of: self)
        formViewController()?.textInputDidBeginEditing(textField, cell: self)
    }

    open func textFieldDidEndEditing(_ textField: UITextField) {
        formViewController()?.endEditing(of: self)
        formViewController()?.textInputDidEndEditing(textField, cell: self)
        textFieldDidChange(textField)
    }

    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldReturn(textField, cell: self) ?? true
    }

    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return formViewController()?.textInputShouldEndEditing(textField, cell: self) ?? true
    }

    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldBeginEditing(textField, cell: self) ?? true
    }

    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldClear(textField, cell: self) ?? true
    }

    open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldEndEditing(textField, cell: self) ?? true
    }
}


/// Concrete implementation of generic _PostalAddressCell with row value type PostalAddress
public final class PostalAddressCell: _PostalAddressCell<PostalAddress> {
    public required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
