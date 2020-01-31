//
//  PostalAddressRow.swift
//  Eureka
//
//  Created by Martin Barreto on 2/23/16.
//  Copyright © 2016 Xmartlabs. All rights reserved.
//

import Foundation
import Eureka

// MARK: Type

/**
 *  Protocol to be implemented by PostalAddress types.
 */
public protocol PostalAddressType: Equatable {
    var street1: String? { get set }
    var street2: String? { get set }
    var pobox: String? { get set }
    var state: String? { get set }
    var postalCode: String? { get set }
    var city: String? { get set }
    var country: String? { get set }
}

public func == <T: PostalAddressType>(lhs: T, rhs: T) -> Bool {
    return lhs.street1 == rhs.street1 && lhs.street2 == rhs.street2 && lhs.pobox == rhs.pobox && lhs.state == rhs.state && lhs.postalCode == rhs.postalCode && lhs.city == rhs.city && lhs.country == rhs.country
}

/// Row type for PostalAddressRow
public struct PostalAddress: PostalAddressType {
    public var street1: String?
    public var street2: String?
    public var pobox: String?
    public var state: String?
    public var postalCode: String?
    public var city: String?
    public var country: String?
    
    public init(){}
    
    public init(street1: String?, street2: String?, pobox: String?, state: String?, postalCode: String?, city: String?, country: String?) {
        self.street1 = street1
        self.street2 = street2
        self.pobox = pobox
        self.state = state
        self.postalCode = postalCode
        self.city = city
        self.country = country
    }
}

public protocol PostalAddressFormatterConformance: class {
    var street1UseFormatterDuringInput: Bool { get set }
    var street1Formatter: Formatter? { get set }
    
    var street2UseFormatterDuringInput: Bool { get set }
    var street2Formatter: Formatter? { get set }
    
    var poboxUseFormatterDuringInput: Bool { get set }
    var poboxFormatter: Formatter? { get set }
    
    var stateUseFormatterDuringInput: Bool { get set }
    var stateFormatter: Formatter? { get set }
    
    var postalCodeUseFormatterDuringInput: Bool { get set }
    var postalCodeFormatter: Formatter? { get set }
    
    var cityUseFormatterDuringInput: Bool { get set }
    var cityFormatter: Formatter? { get set }
    
    var countryUseFormatterDuringInput: Bool { get set }
    var countryFormatter: Formatter? { get set }
}

public protocol PostalAddressRowConformance: PostalAddressFormatterConformance {
    var postalAddressPercentage : CGFloat? { get set }
    var placeholderColor : UIColor? { get set }
    var street1Placeholder : String? { get set }
    var street2Placeholder : String? { get set }
    var poboxPlaceholder : String? { get set }
    var statePlaceholder : String? { get set }
    var postalCodePlaceholder : String? { get set }
    var cityPlaceholder : String? { get set }
    var countryPlaceholder : String? { get set }
}

//MARK: PostalAddressRow

open class _PostalAddressRow<Cell: CellType>: Row<Cell>, PostalAddressRowConformance, KeyboardReturnHandler where Cell: BaseCell, Cell: PostalAddressCellConformance {
    
    /// Configuration for the keyboardReturnType of this row
    open var keyboardReturnType : KeyboardReturnTypeConfiguration?
    
    /// The proportional width that the text fields on the left should have compared to those on the right.
    open var postalAddressPercentage: CGFloat?
    
    /// The textColor for the textField's placeholder
    open var placeholderColor : UIColor?
    
    /// The placeholder for the street1 textField
    open var street1Placeholder : String?
    
    /// The placeholder for the street 2textField
    open var street2Placeholder : String?
    
    /// The placeholder for the pobox textField
    open var poboxPlaceholder : String?
    
    /// The placeholder for the state textField
    open var statePlaceholder : String?
    
    /// The placeholder for the zip textField
    open var postalCodePlaceholder : String?
    
    /// The placeholder for the city textField
    open var cityPlaceholder : String?
    
    /// The placeholder for the country textField
    open var countryPlaceholder : String?
    
    /// A formatter to be used to format the user's input for street1
    open var street1Formatter: Formatter?
    
    /// A formatter to be used to format the user's input for street2
    open var street2Formatter: Formatter?
    
    /// A formatter to be used to format the user's input for pobox
    open var poboxFormatter: Formatter?
    
    /// A formatter to be used to format the user's input for state
    open var stateFormatter: Formatter?
    
    /// A formatter to be used to format the user's input for zip
    open var postalCodeFormatter: Formatter?
    
    /// A formatter to be used to format the user's input for city
    open var cityFormatter: Formatter?
    
    /// A formatter to be used to format the user's input for country
    open var countryFormatter: Formatter?
    
    /// If the formatter should be used while the user is editing the street1.
    open var street1UseFormatterDuringInput: Bool
    
    /// If the formatter should be used while the user is editing the street2.
    open var street2UseFormatterDuringInput: Bool
    
    /// If the formatter should be used while the user is editing the street1.
    open var poboxUseFormatterDuringInput: Bool
    
    /// If the formatter should be used while the user is editing the state.
    open var stateUseFormatterDuringInput: Bool
    
    /// If the formatter should be used while the user is editing the zip.
    open var postalCodeUseFormatterDuringInput: Bool
    
    /// If the formatter should be used while the user is editing the city.
    open var cityUseFormatterDuringInput: Bool
    
    /// If the formatter should be used while the user is editing the country.
    open var countryUseFormatterDuringInput: Bool
    
    public required init(tag: String?) {
        street1UseFormatterDuringInput = false
        street2UseFormatterDuringInput = false
        poboxUseFormatterDuringInput = false
        stateUseFormatterDuringInput = false
        postalCodeUseFormatterDuringInput = false
        cityUseFormatterDuringInput = false
        countryUseFormatterDuringInput = false
        
        super.init(tag: tag)
    }
}

/// A PostalAddress valued row where the user can enter a postal address.
public final class PostalAddressRow: _PostalAddressRow<PostalAddressCell>, RowType {
    public required init(tag: String? = nil) {
        super.init(tag: tag)
        // load correct bundle for cell nib file
        var bundle: Bundle
        if let bundleWithIdentifier = Bundle(identifier: "com.xmartlabs.PostalAddressRow") {
            // Example or Carthage
            bundle = bundleWithIdentifier
        } else {
            // Cocoapods
            let podBundle = Bundle(for: PostalAddressRow.self)
            let bundleURL = podBundle.url(forResource: "PostalAddressRow", withExtension: "bundle")
            bundle = Bundle(url: bundleURL!)!
        }
        cellProvider = CellProvider<PostalAddressCell>(nibName: "PostalAddressCell", bundle: bundle)
    }
}
