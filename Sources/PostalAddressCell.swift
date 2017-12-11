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
	var countrySelectorTableView: UITableView?{ get }
}

/// Base class that implements the cell logic for the PostalAddressRow
open class _PostalAddressCell<T: PostalAddressType>: Cell<T>, CellType, PostalAddressCellConformance, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet open var streetTextField: UITextField?
    @IBOutlet open var firstSeparatorView: UIView?
    @IBOutlet open var stateTextField: UITextField?
    @IBOutlet open var postalCodeTextField: UITextField?
    @IBOutlet open var cityTextField: UITextField?
    @IBOutlet open var secondSeparatorView: UIView?
    @IBOutlet open var countryTextField: UITextField?
	@IBOutlet open var countrySelectorTableView: UITableView?
	
    @IBOutlet weak var postalPercentageConstraint: NSLayoutConstraint?
	
    open var textFieldOrdering: [UITextField?] = []
	var textFieldOrderingVisible: [UITextField?]{
		return textFieldOrdering.filter{ $0?.isHidden == false }
	}

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
		countrySelectorTableView?.delegate = nil
		countrySelectorTableView?.dataSource = nil
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
		
		if (row as? PostalAddressRowConformance)?.countrySelectorRow == nil{
			countrySelectorTableView?.isHidden = true
			countryTextField?.isHidden = false
		} else {
			countrySelectorTableView?.isHidden = false
			countryTextField?.isHidden = true
		}
		
		countrySelectorTableView?.isScrollEnabled = false
		countrySelectorTableView?.sectionHeaderHeight = 0.0
		countrySelectorTableView?.sectionFooterHeight = 0.0
		countrySelectorTableView?.delegate = self
		countrySelectorTableView?.dataSource = self
		
		if let rowConformance = row as? PostalAddressRowConformance, let selectorRow = rowConformance.countrySelectorRow{
			selectorRow
				.onChange{ [weak self] in
					guard let this = self else{ return }
					
					var rowValue = this.row.value ?? T()
					rowValue.country = $0.value
					this.row.value = rowValue
					
					$0.title = $0.displayValueFor?($0.value) ?? $0.noValueDisplayText ?? (this.row as? PostalAddressRowConformance)?.countryPlaceholder
					
					this.row.updateCell()
					
				}.cellSetup{ [weak self] cell, row in
					cell.selectionStyle = .none
					cell.detailTextLabel?.isHidden = true
					cell.textLabel?.textColor = self?.row.value?.country == nil ? UIColor(red: 196.0/255.0, green: 196.0/255.0, blue: 196.0/255.0, alpha: 1.0) : (self?.row.isDisabled == true ? .gray : .black)
					
				}.cellUpdate{ [weak self] cell, row in
					cell.selectionStyle = .none
					cell.textLabel?.textColor = self?.row.value?.country == nil ? UIColor(red: 196.0/255.0, green: 196.0/255.0, blue: 196.0/255.0, alpha: 1.0) : (self?.row.isDisabled == true ? .gray : .black)
				
				}.onPresent{ from, to in
					to.sectionKeyForValue = { _ in return selectorRow.selectorTitle ?? "" }
				}
			
			selectorRow.baseCell.setup()
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
			
			rowConformance.countrySelectorRow?.title = rowConformance.countrySelectorRow?.title ?? rowConformance.countryPlaceholder
			rowConformance.countrySelectorRow?.selectorTitle = rowConformance.countrySelectorRow?.selectorTitle ?? rowConformance.countryPlaceholder
        }
    }

    private func setPlaceholderToTextField(textField: UITextField?, placeholder: String?) {
        if let placeholder = placeholder, let textField = textField {
            if let color = (row as? PostalAddressRowConformance)?.placeholderColor {
                textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedStringKey.foregroundColor: color])
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
                countryTextField?.canBecomeFirstResponder == true ||
				(row as? PostalAddressRowConformance)?.countrySelectorRow?.cell?.cellCanBecomeFirstResponder() == true
        )
    }

    open override func cellBecomeFirstResponder(withDirection direction: Direction) -> Bool {
        return direction == .down ? textFieldOrderingVisible.first??.becomeFirstResponder() ?? false : textFieldOrderingVisible.last??.becomeFirstResponder() ?? false
    }

    open override func cellResignFirstResponder() -> Bool {
        return streetTextField?.resignFirstResponder() ?? true
            && stateTextField?.resignFirstResponder() ?? true
            && postalCodeTextField?.resignFirstResponder() ?? true
            && stateTextField?.resignFirstResponder() ?? true
            && cityTextField?.resignFirstResponder() ?? true
            && countryTextField?.resignFirstResponder() ?? true
			&& (row as? PostalAddressRowConformance)?.countrySelectorRow?.cell?.cellResignFirstResponder() ?? true
    }

    override open var inputAccessoryView: UIView? {
        if let v = formViewController()?.inputAccessoryView(for: row) as? NavigationAccessoryView {
            guard let first = textFieldOrderingVisible.first, let last = textFieldOrderingVisible.last, first != last else { return v }

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

    @objc func internalNavigationAction(_ sender: UIBarButtonItem) {
        guard let inputAccesoryView  = inputAccessoryView as? NavigationAccessoryView else { return }

        var index = 0
        for field in textFieldOrderingVisible {
            if field?.isFirstResponder == true {
                let _ = sender == inputAccesoryView.previousButton ? textFieldOrderingVisible[index-1]?.becomeFirstResponder() : textFieldOrderingVisible[index+1]?.becomeFirstResponder()
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

    @objc open func textFieldDidChange(_ textField : UITextField){
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
					var rowValue = row.value ?? T()

                    switch(textField){
                    case let field where field == streetTextField:
                        rowValue.street = value.pointee as? String
                    case let field where field == stateTextField:
                        rowValue.state = value.pointee as? String
                    case let field where field == postalCodeTextField:
                        rowValue.postalCode = value.pointee as? String
                    case let field where field == cityTextField:
                        rowValue.city = value.pointee as? String
                    case let field where field == countryTextField:
                        rowValue.country = value.pointee as? String
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
					
					row.value = rowValue
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
		
		var rowValue = row.value ?? T()
        switch(textField){
        case let field where field == streetTextField:
            rowValue.street = textValue
        case let field where field == stateTextField:
            rowValue.state = textValue
        case let field where field == postalCodeTextField:
            rowValue.postalCode = textValue
        case let field where field == cityTextField:
            rowValue.city = textValue
        case let field where field == countryTextField:
            rowValue.country = textValue
        default:
            break
        }
		row.value = rowValue
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
	
	//MARK: UITableViewDataSource
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		guard let rowConformance = row as? PostalAddressRowConformance else{ return 0 }
		return rowConformance.countrySelectorRow == nil ? 0 : 1
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let rowConformance = row as? PostalAddressRowConformance else{ return 0 }
		return rowConformance.countrySelectorRow == nil ? 0 : 1
	}
	
	//MARK: UITableViewDelegate
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let row = (row as? PostalAddressRowConformance)?.countrySelectorRow else{ fatalError() }
		return row.baseCell
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let row = (row as? PostalAddressRowConformance)?.countrySelectorRow else{ return }
		
		// row.baseCell.cellBecomeFirstResponder() may be cause InlineRow collapsed then section count will be changed. Use orignal indexPath will out of  section's bounds.
		if !row.baseCell.cellCanBecomeFirstResponder() || !row.baseCell.cellBecomeFirstResponder() {
			tableView.endEditing(true)
		}
		row.didSelect()
	}
	
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		guard let row = (row as? PostalAddressRowConformance)?.countrySelectorRow else{ return tableView.rowHeight }
		return row.baseCell.height?() ?? tableView.rowHeight
	}
	
	public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
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
