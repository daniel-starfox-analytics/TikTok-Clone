import Foundation

enum CSVError: Error {
    case fileNotFound(String)
    case invalidDataEncoding
    case parsingError(String)
}

class CSVParser {

    static func parse<T: Decodable>(fileName: String, bundle: Bundle = .main, completion: @escaping (Result<[T], Error>) -> Void) {
        guard let filePath = bundle.path(forResource: fileName, ofType: "csv") else {
            completion(.failure(CSVError.fileNotFound("CSV file '\(fileName).csv' not found in bundle.")))
            return
        }

        do {
            let contents = try String(contentsOfFile: filePath, encoding: .utf8)
            let lines = contents.split(separator: "\n").map { String($0) }

            guard !lines.isEmpty else {
                completion(.failure(CSVError.parsingError("CSV file is empty.")))
                return
            }

            let headerLine = lines.first!
            let headers = headerLine.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

            var records = [T]()
            let dataLines = lines.dropFirst()

            for (lineIndex, line) in dataLines.enumerated() {
                if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continue // Skip empty lines
                }
                let values = line.split(separator: ",", keepingEmptySubsequences: true).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

                if values.count != headers.count && !(T.self == Product.self && values.count >= 5) { // Special handling for Product due to UTM
                     print("Warning: Line \(lineIndex + 2): Number of values (\(values.count)) does not match number of headers (\(headers.count)). Line: '\(line)'")
                     continue // Skip lines that don't match header count, unless it's a Product with potential UTMs
                }

                var recordDict = [String: String]()
                for (index, header) in headers.enumerated() {
                    if index < values.count {
                        recordDict[header] = values[index]
                    } else {
                        recordDict[header] = "" // Fill missing values with empty string if any
                    }
                }

                // Special handling for Product UTM parameters
                if T.self == Product.self {
                    var utmParams = [String: String]()
                    if values.count > headers.count { // if there are more values than predefined headers
                        // This assumes fixed initial headers: id,name,videoURL,brandID,productPageURL
                        // And the rest are dynamic UTM key-value pairs.
                        // This part needs careful implementation based on exact CSV structure for UTMs.
                        // For the example, utm_source, utm_medium, utm_campaign are headers.
                        // If UTMs are truly dynamic (e.g., key1,value1,key2,value2), parsing is different.
                        // Given the CSV, utm_ prefixed headers are explicit.
                         for (index, header) in headers.enumerated() {
                            if header.starts(with: "utm_") {
                                if index < values.count {
                                    utmParams[String(header)] = values[index]
                                }
                            }
                        }
                    } else {
                        // Populate UTMs from explicitly named utm_ columns
                        for (header, value) in recordDict where header.starts(with: "utm_") {
                            utmParams[header] = value
                        }
                    }
                    // Remove UTM parameters from recordDict to avoid issues with Decodable
                    // if they are not direct properties of Product struct (excluding the utmParameters dictionary)
                    // However, our Product struct has `utmParameters`, so we need to populate that.
                    // The generic decoding below might not automatically handle this dictionary.
                }


                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: recordDict, options: [])
                    var decodedRecord = try JSONDecoder().decode(T.self, from: jsonData)

                    // If it's a Product, manually assign the parsed UTM parameters
                    if var productRecord = decodedRecord as? Product {
                        var utmParametersDict = [String: String]()
                        for i in 5..<headers.count { // Assuming fixed headers up to productPageURL, then UTMs
                            if i < values.count {
                                utmParametersDict[headers[i]] = values[i]
                            }
                        }
                        productRecord.utmParameters = utmParametersDict
                        if let updatedRecord = productRecord as? T {
                             records.append(updatedRecord)
                        } else {
                            throw CSVError.parsingError("Could not cast Product back to generic type T after setting UTM parameters.")
                        }
                    } else {
                        records.append(decodedRecord)
                    }

                } catch let decodingError {
                    completion(.failure(CSVError.parsingError("Decoding error on line \(lineIndex + 2): \(decodingError.localizedDescription). Record: \(recordDict)")))
                    return
                }
            }
            completion(.success(records))

        } catch {
            completion(.failure(error))
        }
    }
}
