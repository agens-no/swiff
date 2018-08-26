#!/usr/bin/env xcrun swift

import Foundation

struct ANSIColors {
    static let clear = "\u{001B}[0m"
    static let red = "\u{001B}[38;5;160m"
    static let orange = "\u{001B}[38;5;202m"
    static let yellow = "\u{001B}[38;5;220m"
    static let green = "\u{001B}[0;32m"
    static let blue = "\u{001B}[0;36m"
    static let grey = "\u{001B}[38;5;237m"
}

struct Config {
    enum DiffMode: String {
        case fastlane
        case live
    }
    var scriptName = "time-diff"
    var diffMode = DiffMode.live
    var low = 1
    var medium = 5
    var high = 10
    var summaryLimit = 20
    var resetRegex: NSRegularExpression?
    
    func colorCode(duration: TimeInterval) -> String {
        switch Int(duration) {
        case high...:
            return ANSIColors.red
        case medium...:
            return ANSIColors.orange
        case low...:
            return ANSIColors.yellow
        default:
            return ANSIColors.grey
        }
    }
    
    func resetMatch(_ string: String) -> Bool {
        return config.resetRegex?.firstMatch(in: string, range: NSMakeRange(0, string.count)) != nil
    }
}

func usage(error: String) -> Never {
    let scriptLocation = CommandLine.arguments.first ?? "time-diff.swift"
    print(ANSIColors.red, "👉 ", error, ANSIColors.clear, separator: "")
    print(ANSIColors.red, "Script failed ", scriptLocation, ANSIColors.clear, separator: "")
    let defaultConfig = Config()
    print("""

        Usage: \(scriptLocation) [-l low] [-m medium] [-h high] [-r reset-mark] [-d diff-mode] [-s summary-limit] [-f --fastlane]
          -l, --low                   Threshold in seconds for low duration color formatting (default: \(defaultConfig.low))
          -m, --medium                Threshold in seconds for medium duration color formatting (default: \(defaultConfig.medium))
          -h, --high                  Threshold in seconds for high duration color formatting (default: \(defaultConfig.high))
          -r, --reset-mark            String match to reset total counter (default: none)
          -d, --diff-mode             Valid options is "live" or "fastlane (default: live)
          -s, --summary-limit         Maximum number of lines in summary (default: \(defaultConfig.summaryLimit))
        
          -f, --fastlane              Shortcut for --diff-mode fastlane --reset-mark "Step :"
        
        Example: cat build.log | \(scriptLocation) --low \(defaultConfig.low) --medium \(defaultConfig.medium) --high \(defaultConfig.high) --reset-mark "Step: " --diff-mode \(defaultConfig.diffMode.rawValue) --summary-limit \(defaultConfig.summaryLimit)
        
        Example: fastlane build | \(scriptLocation) -f
        
        """)
    exit(1)
}

func parseCLIArguments() -> Config {
    var config = Config()
    var arguments = CommandLine.arguments
    arguments.removeFirst()
    while arguments.isEmpty == false {
        let argument = arguments.removeFirst()
        switch argument {
        case "-d", "--diff-mode":
            guard !arguments.isEmpty else {
                usage(error: "Missing value on  option option")
            }
            guard let diffMode = Config.DiffMode(rawValue: arguments.removeFirst().lowercased()) else {
                usage(error: "Bad value sent to  option option")
            }
            config.diffMode = diffMode
        case "-r", "--reset-mark":
            guard !arguments.isEmpty else {
                usage(error: "Missing value on --reset mark")
            }
            do {
                config.resetRegex = try NSRegularExpression(pattern: arguments.removeFirst())
            } catch {
                usage(error: "Bad regex pattern passed to \(argument) option. Error: \(error.localizedDescription))")
            }
        case "-l", "--low":
            guard !arguments.isEmpty, let value = Int(arguments.removeFirst()) else {
                usage(error: "Bad value passed to \(argument) option")
            }
            config.low = value
        case "-m", "--medium":
            guard !arguments.isEmpty, let value = Int(arguments.removeFirst()) else {
                usage(error: "Bad value passed to \(argument) option")
            }
            config.medium = value
        case "-h", "--high":
            guard !arguments.isEmpty, let value = Int(arguments.removeFirst()) else {
                usage(error: "Bad value passed to \(argument) option")
            }
            config.high = value
        case "-s", "--summary-limit":
            guard !arguments.isEmpty, let value = Int(arguments.removeFirst()) else {
                usage(error: "Bad value passed to \(argument) option")
            }
            config.summaryLimit = value
        case "-f", "--fastlane":
            if config.resetRegex == nil {
                config.resetRegex = try! NSRegularExpression(pattern: "Step: ")
            }
            config.diffMode = .fastlane
        default:
            usage(error: "Unknown argument \"\(argument)\"")
        }
    }
    return config
}

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        return count < toLength ? String(repeating: character, count: toLength - count) + self : self
    }
}

func parseFastlaneDate(string: String) -> TimeInterval? {
    let scanner = Scanner(string: string)
    var hours: Int = 0
    var minutes: Int = 0
    var seconds: Int = 0
    if scanner.scanInt(&hours),
        scanner.scanString(":", into: nil),
        scanner.scanInt(&minutes),
        scanner.scanString(":", into: nil),
        scanner.scanInt(&seconds) {
        return TimeInterval(seconds) + (TimeInterval(minutes) * 60) + (TimeInterval(hours) * 60 * 60)
    }
    return nil
}

class Chapter {
    struct Offender {
        var duration: TimeInterval
        var timestamp: TimeInterval
        var line: String
    }
    var name: String
    var offenders: [Offender] = []
    var endTime: TimeInterval?
    var startTime: TimeInterval?
    var duration: TimeInterval? {
        if let endTime = endTime, let startTime = startTime {
            return endTime - startTime
        }
        return nil
    }
    var limit: Int {
        didSet {
            trim()
        }
    }
    
    init(name: String, limit: Int) {
        self.name = name
        self.limit = limit
    }
    
    func addLineIfSlow(duration: TimeInterval, minimumLimit: TimeInterval, timestamp: TimeInterval, line: String) {
        guard duration > minimumLimit else {
            return
        }
        if duration > offenders.last?.duration ?? 0 || offenders.count < limit {
            offenders.append(Offender(duration: duration, timestamp: timestamp, line: line))
            sortOffendersByDuration()
            trim()
        }
    }
    
    func sortOffendersByTimeStamp() {
        offenders.sort { $0.timestamp < $1.timestamp }
    }
    
    func sortOffendersByDuration() {
        offenders.sort { $0.duration > $1.duration }
    }
    
    func trim() {
        if offenders.count > limit {
            offenders.removeLast(offenders.count - limit)
        }
    }
}

let config = parseCLIArguments()
var lastTime: Double?
var time: Double?
var chapter: Chapter = Chapter(name: "First chapter\n", limit: config.summaryLimit)
var total: Chapter = Chapter(name: "Everything\n", limit: config.summaryLimit)
var chapters: [Chapter] = [chapter]
var lastLine: String?
while let line = readLine(strippingNewline: false) {
    switch config.diffMode {
    case .fastlane:
        let dateString = String(line.prefix(9).suffix(8))
        time = parseFastlaneDate(string: dateString) ?? time
    case .live:
        time = Date().timeIntervalSinceReferenceDate
    }
    if lastTime == nil {
        lastTime = time
    }
    if chapter.startTime == nil {
        chapter.startTime = time
    }
    if total.startTime == nil {
        total.startTime = time
    }
    if config.resetMatch(line) {
        print(ANSIColors.blue,
              "Reseting timer ---------------- ",
              ANSIColors.clear,
              line, separator: "", terminator: "")
        if let time = time {
            chapter.endTime = time
        }
        chapter = Chapter(name: line, limit: config.summaryLimit)
        chapters.append(chapter)
        chapter.startTime = time
    }
    else if let time = time, let chapterTime = chapter.startTime {
        let lastDiff = time - (lastTime ?? 0)
        let chapterDiff = time - chapterTime
        print(config.colorCode(duration: lastDiff),
              String(format: "+ %.0f", lastDiff).leftPadding(toLength: 7, withPad: " "),
              " seconds",
              ANSIColors.grey,
              " = ",
              String(format: "%.0f", chapterDiff).leftPadding(toLength: 5, withPad: " "),
              " seconds ",
              ANSIColors.clear,
              line, separator: "", terminator: "")
        if let lastLine = lastLine {
            chapter.addLineIfSlow(duration: lastDiff, minimumLimit: TimeInterval(config.low), timestamp: time, line: lastLine)
            total.addLineIfSlow(duration: lastDiff, minimumLimit: TimeInterval(config.low), timestamp: time, line: lastLine)
        }
    }
    else {
        print("                                ", line, separator: "", terminator: "")
    }
    lastTime = time
    lastLine = line
}

chapter.endTime = time
total.endTime = time

let onlyOneChapterBesidesTotal = chapters.count == 2
if onlyOneChapterBesidesTotal == true {
    chapters.removeLast()
}

func printSummary(chapter: Chapter) {
    print(ANSIColors.grey,
          String(format: "%.0f", chapter.duration ?? 0).leftPadding(toLength: 6, withPad: " "),
          " seconds in total ",
          ANSIColors.blue,
          "# ",
          ANSIColors.clear,
          chapter.name, separator: "", terminator: "")
    for offender in chapter.offenders {
        print(config.colorCode(duration: offender.duration),
              String(format: "%.0f", offender.duration).leftPadding(toLength: 15, withPad: " "),
              " seconds ",
              ANSIColors.blue,
              "  ",
              ANSIColors.clear,
              offender.line, separator: "", terminator: "")
    }
    if chapter.offenders.count == 0 {
        print(ANSIColors.grey,
              "".leftPadding(toLength: 15, withPad: " "),
              "           (No significant events)\n",
              ANSIColors.clear, separator: "", terminator: "")
    }
    print()
}

if config.summaryLimit > 0 {
    print("\n\n", ANSIColors.blue, "========================= Summary by timestamp =========================", ANSIColors.clear, "\n", separator: "")
    for chapter in chapters {
        chapter.sortOffendersByTimeStamp()
        printSummary(chapter: chapter)
    }
    
    print("\n", ANSIColors.blue, "========================= Summary by duration ==========================", ANSIColors.clear, "\n", separator: "")
    for chapter in chapters {
        chapter.sortOffendersByDuration()
        printSummary(chapter: chapter)
    }
}
