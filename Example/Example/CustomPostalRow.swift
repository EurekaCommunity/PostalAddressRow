//
//  CustomPostalRow.swift
//  Example
//
//  Created by Mathias Claassen on 9/13/16.
//
//

import Foundation
import PostalAddressRow
import Eureka

final class MyPostalAddressRow: _PostalAddressRow<PostalAddressCell>, RowType {
    public required init(tag: String? = nil) {
        super.init(tag: tag)
        cellProvider = CellProvider<PostalAddressCell>(nibName: "CustomNib", bundle: Bundle.main)
    }
}
