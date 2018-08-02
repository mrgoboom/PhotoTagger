//
//  XMPBuilder.swift
//  PhotoTagger
//
//  Created by Old iMac on 2018-07-12.
//  Copyright © 2018 Scott. All rights reserved.
//

import Foundation

class XMPBuilder {
    private var starRating: Int?
    private var colourLabel: String?
    private var copyright: String?
    private var keywords: [String]?
    private var fileManager: FileManager
    private var xmpFilename: String
    
    init(forImageFile photoURL:URL) {
        self.fileManager = FileManager.default
        
        let photoURLString = photoURL.path
        let extensionRegex = try? NSRegularExpression(pattern: "\\.[^\\/]+$", options: .caseInsensitive)
        let metadataURLString = extensionRegex?.stringByReplacingMatches(in: photoURLString, options: .withoutAnchoringBounds, range: NSMakeRange(0, photoURLString.count), withTemplate: ".xmp")
        self.xmpFilename = metadataURLString!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        print("metadata URL: ",metadataURLString!,"\n")
        
        if metadataURLString != nil && self.fileManager.fileExists(atPath: metadataURLString!){
            do{
                let fileString = try String.init(contentsOf: URL(fileURLWithPath: metadataURLString!))
                let starRegex = try NSRegularExpression(pattern: "xmp:Rating=\"(\\d*)\"", options: .caseInsensitive)
                let labelRegex = try NSRegularExpression(pattern: "xmp:Label=\"([a-z]*)\"", options: .caseInsensitive)
                let copyRegex = try NSRegularExpression(pattern: "<dc:rights>\\s*<rdf:Alt>\\s*<rdf:li xml:lang=\"x-default\">(.*)<\\/rdf:li>\\s*<\\/rdf:Alt>\\s*<\\/dc:rights>", options: .caseInsensitive)
                let keyGroupRegex = try NSRegularExpression(pattern: "<dc:subject>\\s*<rdf:Bag>\\s*((?:<rdf:li>.*<\\/rdf:li>\\s*)+)<\\/rdf:Bag>\\s*<\\/dc:subject>", options: .caseInsensitive)
                let keyRegex = try NSRegularExpression(pattern: "<rdf:li>(.*)<\\/rdf:li>", options: .caseInsensitive)
                
                let range = NSMakeRange(0, fileString.count)
                if let starMatch = starRegex.firstMatch(in: fileString, options: [], range: range){
                    if starMatch.numberOfRanges == 2{
                        let oldRating = (fileString as NSString).substring(with: starMatch.range(at: 1))
                        print("Found starRating: ",oldRating)
                        self.starRating = Int(oldRating)
                        if self.starRating == nil{
                            print("Previous starRating was not a valid number")
                        }
                    }else{
                        print("Weird error with number of match groups in starRating")
                    }
                }
                if let labelMatch = labelRegex.firstMatch(in: fileString, options: [], range: range){
                    if labelMatch.numberOfRanges == 2{
                        self.colourLabel = (fileString as NSString).substring(with: labelMatch.range(at: 1))
                        if self.colourLabel != nil{
                            print("Found colourLabel: ",self.colourLabel!)
                        }else{
                            print("Found nil colourLabel.")
                        }
                    }else{
                        print("Weird error with number of match groups in colourLabel")
                    }
                }
                if let copyMatch = copyRegex.firstMatch(in: fileString, options: [], range: range){
                    if copyMatch.numberOfRanges == 2{
                        self.copyright = (fileString as NSString).substring(with: copyMatch.range(at: 1))
                        if self.copyright != nil{
                            print("Found copyright: ",self.copyright!)
                        }else{
                            print("Found nil copyright")
                        }
                    }else{
                        print("Weird error with number of match groups in copyright")
                    }
                }
                if let keyGroupMatch = keyGroupRegex.firstMatch(in: fileString, options: [], range: range){
                    /*for index in 1..<keyGroupMatch.numberOfRanges{
                        print("Range ",index," (",keyGroupMatch.range(at: index),"): ",(fileString as NSString).substring(with: keyGroupMatch.range(at: index)))
                    }*/
                    if keyGroupMatch.numberOfRanges == 2{
                        let keyGroup = (fileString as NSString).substring(with: keyGroupMatch.range(at: 1))
                        let keyMatches = keyRegex.matches(in: keyGroup, options: [], range: NSMakeRange(0, keyGroup.count))
                        if keyMatches.count > 0{
                            self.keywords = [String]()
                            for keyMatch in keyMatches{
                                if keyMatch.numberOfRanges == 2{
                                    let newKeyword = (keyGroup as NSString).substring(with: keyMatch.range(at: 1))
                                    self.keywords!.append(newKeyword)
                                    print("Found keyword: ", newKeyword)
                                }else{
                                    print("Weird error with number of match groups in keyMatch.")
                                }
                            }
                        }
                    }else{
                        print("Weird error with number of match groups for keyGroupMatch")
                    }
                }
            }catch{
                print("Error extracting old metadata for file.")
                starRating = nil
                colourLabel = nil
                keywords = nil
                copyright = nil
            }
        }else{
            print("File did not exist or metadataURL nil.")
            starRating = nil
            colourLabel = nil
            keywords = nil
            copyright = nil
        }
    }
    
    func removeOldFile() -> Bool{
        do{
            try self.fileManager.removeItem(atPath: self.xmpFilename)
            return true
        }catch{
            print("Old Metadata file not removed or did not exist.")
            return false
        }
    }
    
    func writeFile(){
        let clean = false
        //This version cleans the old file before creating a new one
        if clean || !self.fileManager.fileExists(atPath: self.xmpFilename){
            if self.starRating == nil && self.colourLabel == nil && self.keywords == nil && self.copyright == nil{
                _ = removeOldFile()
                return
            }
            var newFileContents = "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\" x:xmptk=\"Adobe XMP Core 5.6-c140 79.160451,\r\n\t2017/05/06-01:08:21        \">\r\n <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\r\n  <rdf:Description rdf:about=\"\""
            if self.starRating != nil || self.colourLabel != nil{
                newFileContents += "\r\n    xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\""
            }
            if self.keywords != nil || self.copyright != nil{
                newFileContents += "\r\n    xmlns:dc=\"http://purl.org/dc/elements/1.1/\""
            }
            if self.colourLabel != nil{
                newFileContents += "\r\n   xmp:Label=\""+self.colourLabel!+"\""
            }
            if self.starRating != nil{
                newFileContents += "\r\n   xmp:Rating=\""+String(self.starRating!)+"\""
            }
            newFileContents += ">\r\n"
            if self.copyright != nil {
                newFileContents += "   <dc:rights>\r\n    <rdf:Alt>\r\n     <rdf:li xml:lang=\"x-default\">"+self.copyright!+"</rdf:li>\r\n    </rdf:Alt>\r\n   </dc:rights>\r\n"
            }
            if self.keywords != nil {
                newFileContents += "   <dc:subject>\r\n    <rdf:Bag>\r\n"
                for keyword in self.keywords!{
                    newFileContents += "     <rdf:li>"+keyword+"</rdf:li>\r\n"
                }
                newFileContents += "    </rdf:Bag>\r\n   </dc:subject>\r\n"
            }
            newFileContents += "  </rdf:Description>\r\n </rdf:RDF>\r\n</x:xmpmeta>\r\n"
            if !self.fileManager.fileExists(atPath: self.xmpFilename) || removeOldFile(){
                do{
                    let nsString : NSString = NSString.init(string: newFileContents)
                    try nsString.write(toFile: self.xmpFilename, atomically: true, encoding: String.Encoding.utf8.rawValue)
                    print("XMP File Updated at ",self.xmpFilename)
                }catch{
                    print("Failed to create new metadata file ",self.xmpFilename)
                    print(error)
                }
            }else{
                print("XMP File not Updated")
            }
        }else{
            do{
                let fileContents = try NSMutableString.init(string: String.init(contentsOf: URL(fileURLWithPath: self.xmpFilename)))
                let fileContentsRange = NSMakeRange(0, fileContents.length)
                if self.starRating == nil && self.colourLabel == nil && !self.hasOtherXMPTags(area: (fileContents as String)){
                    let xmpXMLNSTagRegex = try NSRegularExpression(pattern: "\\s*xmlns:xmp=\".*\"", options: .caseInsensitive)
                    xmpXMLNSTagRegex.replaceMatches(in: fileContents, options: [], range: fileContentsRange, withTemplate: "")
                }
                if self.copyright == nil && self.keywords == nil && !self.hasOtherDCTags(area: (fileContents as String)){
                    let dcXMLNSTagRegex = try NSRegularExpression(pattern: "\\s*xmlns:dc=\".*\"", options: .caseInsensitive)
                    dcXMLNSTagRegex.replaceMatches(in: fileContents, options: [], range: fileContentsRange, withTemplate: "")
                }
                if self.starRating != nil{
                    ensureXMPXMLNSTag(area: fileContents)
                    let xmlnsTagRegex = try NSRegularExpression(pattern: "xmlns:\\w+=\".*\"([^\r\n>]*)", options: .caseInsensitive)
                    var startIndex = 0
                    for match in xmlnsTagRegex.matches(in: (fileContents as String), options: [], range: fileContentsRange){
                        let newStartIndex = match.range(at: 1).location
                        if newStartIndex > startIndex{
                            startIndex = newStartIndex
                        }
                    }
                    fileContents.replaceCharacters(in: NSMakeRange(startIndex, 0), with: ("\r\n   xmp:Rating=\""+String(self.starRating!)+"\""))
                }else{
                    let ratingRegex = try NSRegularExpression(pattern: "\\s*xmp:rating=\".*\"", options: .caseInsensitive)
                    ratingRegex.replaceMatches(in: fileContents, options: [], range: fileContentsRange, withTemplate: "")
                }
                if self.colourLabel != nil{
                    ensureXMPXMLNSTag(area: fileContents)
                    let xmlnsTagRegex = try NSRegularExpression(pattern: "xmlns:\\w+=\".*\"([^\r\n>]*)", options: .caseInsensitive)
                    var startIndex = 0
                    for match in xmlnsTagRegex.matches(in: (fileContents as String), options: [], range: fileContentsRange){
                        let newStartIndex = match.range(at: 1).location
                        if newStartIndex > startIndex{
                            startIndex = newStartIndex
                        }
                    }
                    fileContents.replaceCharacters(in: NSMakeRange(startIndex, 0), with: "\r\n   xmp:Label=\""+self.colourLabel!+"\"")
                }else{
                    let labelRegex = try NSRegularExpression(pattern: "\\s*xmp:label=\".*\"", options: .caseInsensitive)
                    labelRegex.replaceMatches(in: fileContents, options: [], range: fileContentsRange, withTemplate: "")
                }
                if self.copyright != nil{
                    
                }
            }catch{
                print("Failed to update file")
                print(error)
            }
        }
    }
    
    func ensureDCXMLNSTag(area: NSMutableString){
        let range = NSMakeRange(0, area.length)
        do{
            let dcXMLNSTagRegex = try NSRegularExpression(pattern: "xmlns:dc=\".*\"", options: .caseInsensitive)
            if dcXMLNSTagRegex.firstMatch(in: (area as String), options: [], range: range) == nil{
                let aboutRegex = try NSRegularExpression(pattern: "rdf:about=\".*\"([^\r\n>]*)", options: .caseInsensitive)
                var startIndex = 0
                if let aboutMatch = aboutRegex.firstMatch(in: (area as String), options: [], range: range){
                    startIndex = aboutMatch.range(at: 1).location
                }else{
                    throw NSError(domain: "rdf:about found in XMP File", code: 100, userInfo: nil)
                }
                let xmpRegex = try NSRegularExpression(pattern: "xmlns:xmp=\".*\"([^\r\n>]*)", options: .caseInsensitive)
                if let xmpMatch = xmpRegex.firstMatch(in: (area as String), options: [], range: range){
                    startIndex = xmpMatch.range(at: 1).location
                }
                let tiffRegex = try NSRegularExpression(pattern: "xmlns:tiff=\".*\"([^\r\n>]*)", options: .caseInsensitive)
                if let tiffMatch = tiffRegex.firstMatch(in: (area as String), options: [], range: range){
                    startIndex = tiffMatch.range(at: 1).location
                }
                let exifRegex = try NSRegularExpression(pattern: "xmlns:exif=\".*\"([^\r\n^]*)", options: .caseInsensitive)
                if let exifMatch = exifRegex.firstMatch(in: (area as String), options: [], range: range){
                    startIndex = exifMatch.range(at: 1).location
                }
                area.replaceCharacters(in: NSMakeRange(startIndex, 0), with: "\r\n    xmlns:dc=\"http://purl.org/dc/elements/1.1/\"")
            }
        }catch{
            print("Failed to ensure DC XMLNS Tag")
        }
    }
    
    func ensureXMPXMLNSTag(area: NSMutableString){
        let range = NSMakeRange(0, area.length)
        do {
            let xmpXMLNSTagRegex = try NSRegularExpression(pattern: "xmlns:xmp=\".*\"", options: .caseInsensitive)
            if xmpXMLNSTagRegex.firstMatch(in: (area as String), options: [], range: range) == nil{
                let aboutRegex = try NSRegularExpression(pattern: "rdf:about=\".*\"([^\r\n>]*)", options: .caseInsensitive)
                if let aboutMatch = aboutRegex.firstMatch(in: (area as String), options: [], range: range){
                    let startIndex = aboutMatch.range(at: 1).location
                    area.replaceCharacters(in: NSMakeRange(startIndex, 0), with: "\r\n    xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\"")
                }else{
                    throw NSError(domain: "rdf:about found in XMP File", code: 100, userInfo: nil)
                }
            }
        } catch {
            print("Failed to ensure XMP XMLNS Tag")
            print(error)
        }
    }
    
    func hasOtherDCTags(area: String) -> Bool{
        do{
            let dcTagRegex = try NSRegularExpression(pattern: "dc:(\\w+)", options: .caseInsensitive)
            for match in dcTagRegex.matches(in: area, options: [], range: NSMakeRange(0, area.count)){
                let tagType = (area as NSString).substring(with: match.range(at: 1))
                if tagType.caseInsensitiveCompare("rights") != .orderedSame && tagType.caseInsensitiveCompare("subject") != .orderedSame{
                    return true
                }
            }
        }catch{
            print(error)
        }
        return false
    }
    
    func hasOtherXMPTags(area: String) -> Bool{
        do{
            let xmpTagRegex = try NSRegularExpression(pattern: "xmp:(\\w+)=\".*\"", options: .caseInsensitive)
            let xmpTagMatches = xmpTagRegex.matches(in: area, options: [], range: NSMakeRange(0, area.count))
            for match in xmpTagMatches{
                let tagType = (area as NSString).substring(with: match.range(at: 1))
                if tagType.caseInsensitiveCompare("rating") != .orderedSame && tagType.caseInsensitiveCompare("label") != .orderedSame{
                    return true
                }
            }
        }catch{
            print(error)
        }
        return false
    }
    
    func setStarRating(rating: Int?){
        if rating != nil && rating! > 0{
            self.starRating = rating
        }else{
            self.starRating = nil
        }
        writeFile()
    }
    func setColourLabel(colour: String?){
        if colour != nil && colour! != "empty"{
            self.colourLabel = colour
        }else{
            self.colourLabel = nil
        }
        writeFile()
    }
    func setCopyright(copy: String?){
        if copy != nil && copy != ""{
            self.copyright = copy
        }else{
            self.copyright = nil
        }
        writeFile()
    }
    func setKeywords(words: String?){
        self.keywords = nil
        if words != nil && words != ""{
            let subsequences = words!.split(separator: ",", omittingEmptySubsequences: true)
            for tempWord in subsequences{
                let finalWord = tempWord.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
                if finalWord != ""{
                    if self.keywords == nil{
                        self.keywords = [String]()
                    }
                    self.keywords!.append(finalWord)
                }
            }
        }
        writeFile()
    }
    
    func getStarRating() -> Int?{
        return self.starRating
    }
    func getColourLabel() -> String?{
        return self.colourLabel
    }
    func getCopyright() -> String?{
        return self.copyright
    }
    func getKeywords() -> [String]?{
        return self.keywords
    }
}

/*class XMPTag{
    private var subTags: [XMPTag]
    private let tag: String
    private var rdfXMLNSComponents: [String : String]?
    private var rdfOtherComponents: [String : String]?
    
    init?(withTag: String, isRDFDescription: Bool) {
        self.subTags = [XMPTag]()
        self.tag = withTag
        if isRDFDescription{
            do{
                self.rdfXMLNSComponents = [String : String]()
                self.rdfOtherComponents = [String : String]()
                let descriptionXMLNSRegex = try NSRegularExpression(pattern: "(xmlns:\\w+)=\"(.*)\"", options: .caseInsensitive)
                let descriptionTagRegex = try NSRegularExpression(pattern: "(\\w+:\\w+)=\"(.*)\"", options: .caseInsensitive)
                let xmlnsMatches = descriptionXMLNSRegex.matches(in: withTag, options: [], range: NSMakeRange(0, withTag.count))
                var otherMatches = descriptionTagRegex.matches(in: withTag, options: [], range: NSMakeRange(0, withTag.count))
                for match in xmlnsMatches{
                    if let indexToRemove = PhotoViewController.firstIndex(array: otherMatches, item: match){
                        otherMatches.remove(at: indexToRemove)
                    }
                    let key = (withTag as NSString).substring(with: match.range(at: 1))
                    let value = (withTag as NSString).substring(with: match.range(at: 2))
                    self.rdfXMLNSComponents!.updateValue(value, forKey: key)
                }
                for match in otherMatches{
                    let key = (withTag as NSString).substring(with: match.range(at: 1))
                    let value = (withTag as NSString).substring(with: match.range(at: 2))
                    self.rdfOtherComponents!.updateValue(value, forKey: key)
                }
            }catch{
                print(error)
                return nil
            }
        }
    }
    
    func containsXMLNSTag(key: String) -> Bool{
        if self.rdfXMLNSComponents != nil{
            if self.rdfXMLNSComponents![key] != nil{
                return true
            }else{
                return false
            }
        }else{
            return false
        }
    }
    
    func setOtherComponent(key: String, value: String)->Bool{
        if self.rdfOtherComponents != nil{
            self.rdfOtherComponents!.updateValue(value, forKey: key)
            return true
        }
        return false
    }
    
    func setXMLNSComponent(key: String, value: String)-> Bool{
        if self.rdfXMLNSComponents != nil{
            self.rdfXMLNSComponents!.updateValue(value, forKey: key)
            return true
        }
        return false
    }
}*/
