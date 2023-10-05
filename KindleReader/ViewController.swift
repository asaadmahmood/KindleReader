import Cocoa

class HighlightsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.keyCode == 3 { // 3 is the key code for 'F'
            searchField.becomeFirstResponder()
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.makeFirstResponder(self)
    }
    
    var filteredHighlights: [String: [String]] = [:]
    
    @IBOutlet weak var highlightsTableView: NSTableView!
    @IBOutlet var highlightContentView: NSTextView!
    @IBOutlet weak var searchField: NSSearchField!
    
    @IBAction func searchFieldChanged(_ sender: NSSearchField) {
        filterHighlights(with: sender.stringValue)
        updateHighlightContentView()
    }
    
    func filterHighlights(with searchTerm: String) {
        if searchTerm.isEmpty {
            filteredHighlights = bookHighlights
        } else {
            filteredHighlights = bookHighlights.compactMapValues { highlights in
                let matchingHighlights = highlights.filter { $0.contains(searchTerm) }
                return matchingHighlights.isEmpty ? nil : matchingHighlights
            }
        }
        highlightsTableView.reloadData()
    }
    
    func highlight(searchTerm: String, in text: String) -> NSAttributedString {
        let fontSize: CGFloat = 14.0 // Set your desired font size here
        let font = NSFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.textColor,
            .font: font
        ]
        
        let attributedString = NSMutableAttributedString(string: text, attributes: attributes) // Set default text color and font
        let searchLength = searchTerm.count
        var range = NSRange(location: 0, length: text.count)
        
        while range.location != NSNotFound {
            range = (text as NSString).range(of: searchTerm, options: .caseInsensitive, range: range)
            if range.location != NSNotFound {
                attributedString.addAttribute(.backgroundColor, value: NSColor.blue, range: range)
                range = NSRange(location: range.location + searchLength, length: text.count - (range.location + searchLength))
            }
        }
        
        return attributedString
    }

    
    var bookHighlights: [String: [String]] = [:] // Dictionary to store parsed data

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        filteredHighlights = bookHighlights // Initialize with all highlights
    }

    
    private func setupTableView() {
        highlightsTableView.dataSource = self
        highlightsTableView.delegate = self
    }
    
    private func updateHighlightContentView() {
        guard let selectedBook = selectedBookTitle() else {
            highlightContentView.string = "" // Clear the content view if no book is selected
            return
        }
        if let highlights = filteredHighlights[selectedBook] {
            let searchTerm = searchField.stringValue
            let highlightedText = NSMutableAttributedString()
            
            for highlightText in highlights {
                let highlightedSegment = highlight(searchTerm: searchTerm, in: highlightText)
                highlightedText.append(highlightedSegment)
                highlightedText.append(NSAttributedString(string: "\n\n")) // Add separator
            }
            
            // Remove the last separator
            if highlightedText.length > 2 {
                highlightedText.deleteCharacters(in: NSRange(location: highlightedText.length - 2, length: 2))
            }
            
            highlightContentView.textStorage?.setAttributedString(highlightedText)
        }
    }

    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateHighlightContentView()
    }

    
    private func selectedBookTitle() -> String? {
        let selectedRow = highlightsTableView.selectedRow
        return selectedRow != -1 ? Array(filteredHighlights.keys)[selectedRow] : nil
    }

    // NSTableViewDataSource methods
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredHighlights.keys.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let bookTitle = Array(filteredHighlights.keys)[row]
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "BookTitleColumn") {
            return bookTitle
        }
        return nil
    }
}
