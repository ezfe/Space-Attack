//
//  PythonHelperFunctions.swift
//  Space Attack
//
//  Created by Ezekiel Elin on 3/7/15.
//  Copyright (c) 2015 Ezekiel Elin. All rights reserved.
//

import Foundation

func convertCoordinates(#pygameX: Int) -> Int {
	return pygameX
}

func convertCoordinates(#pygameY: Int) -> Int {
	return 512 - pygameY
}

func convertCoordinates(#swiftX: Int) -> Int {
	return swiftX
}

func convertCoordinates(#swiftY: Int) -> Int {
	return 512 - swiftY
}