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
        //Start File as Header
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
