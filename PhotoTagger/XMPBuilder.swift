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
        
        let photoURLString = photoURL.absoluteString
        let extensionRegex = try? NSRegularExpression(pattern: "\\.[^\\/]+$", options: .caseInsensitive)
        let metadataURLString = extensionRegex?.stringByReplacingMatches(in: photoURLString, options: .withoutAnchoringBounds, range: NSMakeRange(0, photoURLString.count), withTemplate: ".xmp")
        self.xmpFilename = metadataURLString!
        print("metadata URL: ",metadataURLString!,"\n")
        
        if metadataURLString != nil && self.fileManager.fileExists(atPath: metadataURLString!){
            do{
                print("OH SHIT WE'RE ABOUT TO ENTER THE INCOMPLETE ZONE")
                /*** THE CODE BELOW IS UNTESTED AND INCOMPLETE ***/
                let fileString = try String.init(contentsOf: URL(fileURLWithPath: metadataURLString!))
                let starRegex = try NSRegularExpression(pattern: "xmp:Rating=\"(\\d*)\"", options: .caseInsensitive)
                let labelRegex = try NSRegularExpression(pattern: "xmp:Label=\"([a-z]*)\"", options: .caseInsensitive)
                let copyRegex = try NSRegularExpression(pattern: "<dc:rights>\\s*<rdf:Alt>\\s*<rdf:li xml:lang=\"x-default\">(.*)<\\/rdf:li>\\s*<\\/rdf:Alt>\\s*<\\/dc:rights>", options: .caseInsensitive)
                let keyRegex = try NSRegularExpression(pattern: "<dc:subject>\\s*<rdf:Bag>\\s*(?:<rdf:li>(.*)<\\/rdf:li>\\s*)+<\\/rdf:Bag>\\s*<\\/dc:subject>", options: .caseInsensitive)
                
                let range = NSMakeRange(0, fileString.count)
                let starMatch = starRegex.firstMatch(in: fileString, options: [], range: range)
                let labelMatch = labelRegex.firstMatch(in: fileString, options: [], range: range)
                let copyMatch = copyRegex.firstMatch(in: fileString, options: [], range: range)
                let keyMatch = keyRegex.firstMatch(in: fileString, options: [], range: range)
                
            
            }catch{
                print("Error extracting old metadata for file.")
                starRating = nil
                colourLabel = nil
                keywords = nil
                copyright = nil
            }
        }
        starRating = nil
        colourLabel = nil
        keywords = nil
        copyright = nil
    }
    
    func removeOldFile() -> Bool{
        do{
            try self.fileManager.removeItem(atPath: self.xmpFilename)
            return true
        }catch{
            print("Old Metadata file not removed or did not exist. XMP File not updated.")
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
        if removeOldFile(){
            do{
                let nsString : NSString = NSString.init(string: newFileContents)
                try nsString.write(toFile: self.xmpFilename, atomically: true, encoding: String.Encoding.utf8.rawValue)
            }catch{
                print("Failed to create new metadata file.")
            }
        }
    }
    
    func setStarRating(rating: Int?){
        self.starRating = rating
        writeFile()
    }
    func setColourLabel(colour: String?){
        self.colourLabel = colour
        writeFile()
    }
    func setCopyright(copy: String?){
        self.copyright = copy
        writeFile()
    }
    func setKeywords(words: [String]?){
        self.keywords = words
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
