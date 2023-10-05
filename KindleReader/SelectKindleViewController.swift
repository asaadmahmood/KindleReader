import Cocoa

class SelectKindleViewController: NSViewController {

    // This will store the parsed data and will be passed to the next view controller
    var bookHighlights: [String: [String]] = [:]


    @IBAction func selectKindleButtonPressed(_ sender: Any) {
        promptUserForKindleDrive()
    }
    
    private func promptUserForKindleDrive() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select the Kindle Drive"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        openPanel.begin { [weak self] (result) in
            if result == .OK, let selectedDirectory = openPanel.url {
                let fileManager = FileManager.default
                let documentsPath = selectedDirectory.appendingPathComponent("documents").path
                if fileManager.fileExists(atPath: documentsPath) {
                    // Parse the highlights from the Kindle and store them in bookHighlights
                    self?.parseKindleHighlights(from: selectedDirectory)
                    self?.performSegue(withIdentifier: NSStoryboardSegue.Identifier("showHighlights"), sender: self)
                } else {
                    // Show an alert to the user indicating that the selected drive is not a Kindle
                    let alert = NSAlert()
                    alert.messageText = "Error"
                    alert.informativeText = "The selected drive does not appear to be a Kindle. Please select the correct drive."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }

    private func parseKindleHighlights(from kindleURL: URL) {
        let clippingsURL = kindleURL.appendingPathComponent("documents/My Clippings.txt")
        do {
            let fileContents = try String(contentsOf: clippingsURL, encoding: .utf8)
            bookHighlights = parseClippings(from: fileContents)
        } catch {
            print("Error reading the My Clippings.txt file:", error)
        }
    }

    private func parseClippings(from text: String) -> [String: [String]] {
        let entries = text.components(separatedBy: "==========")
        var parsedHighlights: [String: [String]] = [:]

        for entry in entries {
            let lines = entry.trimmingCharacters(in: .whitespacesAndNewlines)
                             .split(separator: "\r\n", omittingEmptySubsequences: true)
                             .map(String.init)
                        
            if lines.count >= 3 {
                let bookTitle = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let highlightDetails = lines[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let highlightText = lines[2...].joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                let fullHighlight = highlightDetails + "\n" + highlightText
                if parsedHighlights[bookTitle] != nil {
                    parsedHighlights[bookTitle]!.append(fullHighlight)
                } else {
                    parsedHighlights[bookTitle] = [fullHighlight]
                }
            }

        }

        return parsedHighlights
    }

    // This method will pass the bookHighlights to the next view controller
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == NSStoryboardSegue.Identifier("showHighlights"),
           let destinationVC = segue.destinationController as? HighlightsViewController {
            destinationVC.bookHighlights = self.bookHighlights
        }
    }
}
