import Foundation

// MARK: - Time Converter Service

@Observable
class TimeConverterService {
  // MARK: - Properties

  private let iso8601Formatter: ISO8601DateFormatter
  private let rfc2822Formatter: DateFormatter

  // Real-time conversion properties
  private var realTimeConversionTimer: Timer?
  private var realTimeConversionCallback: ((TimeConversionResult) -> Void)?
  private var lastRealTimeInput: String = ""
  private var lastRealTimeOptions: TimeConversionOptions?

  // Performance optimization caches
  private var formatterCache: [String: DateFormatter] = [:]
  private var timezoneCache: [String: TimeZone] = [:]
  private let cacheQueue = DispatchQueue(label: "timeconverter.cache", attributes: .concurrent)

  // Batch processing optimization
  private let batchProcessingQueue = DispatchQueue(
    label: "timeconverter.batch", qos: .userInitiated)

  // MARK: - Initialization

  init() {
    // ISO 8601 formatter
    iso8601Formatter = ISO8601DateFormatter()
    iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    // RFC 2822 formatter
    rfc2822Formatter = DateFormatter()
    rfc2822Formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    rfc2822Formatter.locale = Locale(identifier: "en_US_POSIX")

    // Pre-populate timezone cache with common timezones
    preloadCommonTimezones()
  }

  deinit {
    stopRealTimeConversion()
  }

  // MARK: - Main Conversion Method

  func convertTime(input: String, options: TimeConversionOptions) -> TimeConversionResult {
    let trimmedInput = sanitizeInput(input)

    guard !trimmedInput.isEmpty else {
      return .failure(error: TimeConverterError.inputEmpty.localizedDescription)
    }

    // Auto-detect format if enabled
    let actualSourceFormat: TimeFormat
    if options.autoDetectFormat {
      actualSourceFormat = detectFormat(for: trimmedInput) ?? options.sourceFormat
    } else {
      actualSourceFormat = options.sourceFormat
    }

    // Enhanced input validation
    if options.validateInput {
      if let validationError = validateInputForFormat(
        trimmedInput, format: actualSourceFormat, customFormat: options.customFormat)
      {
        return .failure(error: validationError)
      }
    }

    // First, parse the input based on source format
    guard
      let sourceDate = parseInputWithEnhancedErrorHandling(
        trimmedInput,
        format: actualSourceFormat,
        timeZone: options.sourceTimeZone,
        customFormat: options.customFormat)
    else {
      let errorMessage = generateDetailedParsingError(
        input: trimmedInput,
        format: actualSourceFormat,
        timeZone: options.sourceTimeZone,
        customFormat: options.customFormat
      )
      return .failure(error: errorMessage)
    }

    // Enhanced timezone conversion with validation
    let adjustedDate: Date
    if options.sourceTimeZone != options.targetTimeZone {
      do {
        adjustedDate = try convertTimeZoneWithValidation(
          date: sourceDate,
          from: options.sourceTimeZone,
          to: options.targetTimeZone
        )
      } catch {
        let detailedError = generateTimezoneConversionError(
          from: options.sourceTimeZone,
          to: options.targetTimeZone,
          date: sourceDate
        )
        return .failure(error: detailedError)
      }
    } else {
      adjustedDate = sourceDate
    }

    // Then, format the date to target format
    do {
      let result = try formatDateWithEnhancedErrorHandling(
        adjustedDate,
        format: options.targetFormat,
        timeZone: options.targetTimeZone,
        customFormat: options.customFormat,
        includeMilliseconds: options.includeMilliseconds
      )

      return .success(
        result: result,
        timestamp: sourceDate.timeIntervalSince1970,
        date: sourceDate
      )
    } catch {
      return .failure(error: TimeConverterError.outputGenerationFailed.localizedDescription)
    }
  }

  // MARK: - Current Time Methods

  func getCurrentTime(
    format: TimeFormat,
    timeZone: TimeZone = .current,
    customFormat: String = "yyyy-MM-dd HH:mm:ss",
    includeMilliseconds: Bool = false
  ) -> String {
    let currentDate = Date()
    return formatDate(
      currentDate,
      format: format,
      timeZone: timeZone,
      customFormat: customFormat,
      includeMilliseconds: includeMilliseconds)
  }

  func getCurrentTimestamp(includeMilliseconds: Bool = false) -> String {
    let timestamp = Date().timeIntervalSince1970
    if includeMilliseconds {
      return String(format: "%.3f", timestamp)
    } else {
      return String(Int(timestamp))
    }
  }

  // MARK: - Real-Time Conversion

  func startRealTimeConversion(
    input: String,
    options: TimeConversionOptions,
    callback: @escaping (TimeConversionResult) -> Void
  ) {
    stopRealTimeConversion()

    lastRealTimeInput = input
    lastRealTimeOptions = options
    realTimeConversionCallback = callback

    // Perform initial conversion
    let result = convertTime(input: input, options: options)
    callback(result)

    // Start timer for continuous updates if dealing with current time or real-time conversion is enabled
    if options.enableRealTimeConversion || input.isEmpty || input.lowercased().contains("now")
      || input.lowercased().contains("current")
    {
      realTimeConversionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
        [weak self] _ in
        guard let self = self,
          let options = self.lastRealTimeOptions,
          let callback = self.realTimeConversionCallback
        else { return }

        // For real-time conversion, continuously convert the same input
        if options.enableRealTimeConversion && !self.lastRealTimeInput.isEmpty {
          let result = self.convertTime(input: self.lastRealTimeInput, options: options)
          callback(result)
        } else {
          // For current time updates
          let currentTime = self.getCurrentTime(
            format: options.sourceFormat,
            timeZone: options.sourceTimeZone,
            customFormat: options.customFormat,
            includeMilliseconds: options.includeMilliseconds
          )

          let result = self.convertTime(input: currentTime, options: options)
          callback(result)
        }
      }
    }
  }

  func stopRealTimeConversion() {
    realTimeConversionTimer?.invalidate()
    realTimeConversionTimer = nil
    realTimeConversionCallback = nil
    lastRealTimeInput = ""
    lastRealTimeOptions = nil
  }

  func updateRealTimeConversion(input: String) {
    guard let options = lastRealTimeOptions,
      let callback = realTimeConversionCallback
    else { return }

    lastRealTimeInput = input
    let result = convertTime(input: input, options: options)
    callback(result)
  }

  // MARK: - Time Zone Conversion

  func convertTimeZone(
    date: Date,
    from sourceTimeZone: TimeZone,
    to targetTimeZone: TimeZone
  ) -> Date {
    let sourceOffset = sourceTimeZone.secondsFromGMT(for: date)
    let targetOffset = targetTimeZone.secondsFromGMT(for: date)
    let offsetDifference = targetOffset - sourceOffset

    return date.addingTimeInterval(TimeInterval(offsetDifference))
  }

  // MARK: - Enhanced Time Zone Conversion

  func convertTimeZoneWithValidation(
    date: Date,
    from sourceTimeZone: TimeZone,
    to targetTimeZone: TimeZone
  ) throws -> Date {
    // Validate timezone availability
    guard isTimezoneAvailable(sourceTimeZone) else {
      throw TimeConverterError.timezoneDataUnavailable(sourceTimeZone.identifier)
    }

    guard isTimezoneAvailable(targetTimeZone) else {
      throw TimeConverterError.timezoneDataUnavailable(targetTimeZone.identifier)
    }

    // Use cached timezone if available
    let cachedSourceTZ = getCachedTimezone(sourceTimeZone.identifier) ?? sourceTimeZone
    let cachedTargetTZ = getCachedTimezone(targetTimeZone.identifier) ?? targetTimeZone

    let sourceOffset = cachedSourceTZ.secondsFromGMT(for: date)
    let targetOffset = cachedTargetTZ.secondsFromGMT(for: date)
    let offsetDifference = targetOffset - sourceOffset

    return date.addingTimeInterval(TimeInterval(offsetDifference))
  }

  func getTimezoneInfo(for identifier: String) -> TimeZoneInfo? {
    guard let timeZone = TimeZone(identifier: identifier) else { return nil }
    return TimeZoneInfo(timeZone: timeZone)
  }

  func searchTimezones(query: String) -> [TimeZoneInfo] {
    let allIdentifiers = TimeZone.knownTimeZoneIdentifiers
    let filteredIdentifiers = allIdentifiers.filter { identifier in
      identifier.localizedCaseInsensitiveContains(query)
        || TimeZone(identifier: identifier)?.localizedName(for: .standard, locale: .current)?
          .localizedCaseInsensitiveContains(query) == true
    }

    return filteredIdentifiers.compactMap { identifier in
      guard let timeZone = TimeZone(identifier: identifier) else { return nil }
      return TimeZoneInfo(timeZone: timeZone)
    }.sorted { $0.displayName < $1.displayName }
  }

  func getPopularTimezones() -> [TimeZoneInfo] {
    let popularIdentifiers = [
      "UTC",
      "America/New_York",
      "America/Los_Angeles",
      "America/Chicago",
      "America/Denver",
      "Europe/London",
      "Europe/Paris",
      "Europe/Berlin",
      "Asia/Tokyo",
      "Asia/Shanghai",
      "Asia/Kolkata",
      "Australia/Sydney",
      "Pacific/Auckland",
    ]

    return popularIdentifiers.compactMap { identifier in
      guard let timeZone = TimeZone(identifier: identifier) else { return nil }
      return TimeZoneInfo(timeZone: timeZone)
    }
  }

  func validateTimezoneCompatibility(source: TimeZone, target: TimeZone, for date: Date) -> Bool {
    // Check if both timezones have valid data for the given date
    let sourceOffset = source.secondsFromGMT(for: date)
    let targetOffset = target.secondsFromGMT(for: date)

    // Validate that offsets are within reasonable bounds (-12 to +14 hours)
    let minOffset = -12 * 3600
    let maxOffset = 14 * 3600

    return sourceOffset >= minOffset && sourceOffset <= maxOffset && targetOffset >= minOffset
      && targetOffset <= maxOffset
  }

  // MARK: - Validation Methods

  func validateTimestamp(_ input: String) -> Bool {
    // Sanitize input
    let sanitizedInput = sanitizeInput(input)
    guard let timestamp = Double(sanitizedInput) else { return false }

    // Check if timestamp is within reasonable range (1970-2100)
    // Also handle millisecond timestamps
    let adjustedTimestamp = timestamp > 1_000_000_000_000 ? timestamp / 1000 : timestamp
    return adjustedTimestamp >= 0 && adjustedTimestamp <= 4_102_444_800  // Jan 1, 2100
  }

  func sanitizeInput(_ input: String) -> String {
    // Remove common problematic characters and whitespace
    return
      input
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "\u{00A0}", with: " ")  // Non-breaking space
      .replacingOccurrences(of: "\u{2000}", with: " ")  // En quad
      .replacingOccurrences(of: "\u{2001}", with: " ")  // Em quad
      .replacingOccurrences(of: "\u{2002}", with: " ")  // En space
      .replacingOccurrences(of: "\u{2003}", with: " ")  // Em space
      .replacingOccurrences(of: "\u{2004}", with: " ")  // Three-per-em space
      .replacingOccurrences(of: "\u{2005}", with: " ")  // Four-per-em space
      .replacingOccurrences(of: "\u{2006}", with: " ")  // Six-per-em space
      .replacingOccurrences(of: "\u{2007}", with: " ")  // Figure space
      .replacingOccurrences(of: "\u{2008}", with: " ")  // Punctuation space
      .replacingOccurrences(of: "\u{2009}", with: " ")  // Thin space
      .replacingOccurrences(of: "\u{200A}", with: " ")  // Hair space
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func validateDateString(_ input: String, format: TimeFormat, customFormat: String? = nil) -> Bool
  {
    let sanitizedInput = sanitizeInput(input)
    guard !sanitizedInput.isEmpty else { return false }

    switch format {
    case .timestamp:
      return validateTimestamp(sanitizedInput)
    case .iso8601:
      return iso8601Formatter.date(from: sanitizedInput) != nil
    case .rfc2822:
      return rfc2822Formatter.date(from: sanitizedInput) != nil
    case .custom:
      guard let customFormat = customFormat, !customFormat.isEmpty else { return false }
      let formatter = getOrCreateFormatter(for: customFormat)
      return formatter.date(from: sanitizedInput) != nil
    }
  }

  private func getOrCreateFormatter(for customFormat: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = customFormat
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }

  func isTimezoneAvailable(_ timezone: TimeZone) -> Bool {
    // Check if timezone is available and has valid data
    let testDate = Date()
    let offset = timezone.secondsFromGMT(for: testDate)

    // Validate that offset is within reasonable bounds (-12 to +14 hours)
    let minOffset = -12 * 3600
    let maxOffset = 14 * 3600

    return offset >= minOffset && offset <= maxOffset
  }

  // MARK: - Enhanced Validation Methods

  func validateInputForFormat(_ input: String, format: TimeFormat, customFormat: String) -> String?
  {
    switch format {
    case .timestamp:
      if !validateTimestamp(input) {
        return TimeConverterError.invalidTimestamp(input).localizedDescription
      }
    case .iso8601:
      if !validateDateString(input, format: .iso8601) {
        return TimeConverterError.invalidDateFormat(input).localizedDescription
      }
    case .rfc2822:
      if !validateDateString(input, format: .rfc2822) {
        return TimeConverterError.invalidDateFormat(input).localizedDescription
      }
    case .custom:
      if customFormat.isEmpty {
        return TimeConverterError.customFormatInvalid("Custom format cannot be empty")
          .localizedDescription
      }
      if !validateDateString(input, format: .custom, customFormat: customFormat) {
        return TimeConverterError.invalidDateFormat(input).localizedDescription
      }
    }
    return nil
  }

  // MARK: - Format Detection

  func detectFormat(for input: String) -> TimeFormat? {
    let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

    // Try timestamp first (most common)
    if validateTimestamp(trimmedInput) {
      return .timestamp
    }

    // Try ISO 8601
    if validateDateString(trimmedInput, format: .iso8601) {
      return .iso8601
    }

    // Try RFC 2822
    if validateDateString(trimmedInput, format: .rfc2822) {
      return .rfc2822
    }

    return nil
  }

  // MARK: - Performance Optimization Methods

  func optimizedBatchConvert(inputs: [String], options: TimeConversionOptions)
    -> [TimeConversionResult]
  {
    return batchProcessingQueue.sync {
      // Pre-validate timezone data
      let sourceTimezone =
        getCachedTimezone(options.sourceTimeZone.identifier) ?? options.sourceTimeZone
      let targetTimezone =
        getCachedTimezone(options.targetTimeZone.identifier) ?? options.targetTimeZone

      // Create optimized options with cached timezones
      let optimizedOptions = TimeConversionOptions(
        sourceFormat: options.sourceFormat,
        targetFormat: options.targetFormat,
        sourceTimeZone: sourceTimezone,
        targetTimeZone: targetTimezone,
        customFormat: options.customFormat,
        includeMilliseconds: options.includeMilliseconds,
        enableRealTimeConversion: false,  // Disable for batch processing
        batchProcessingEnabled: true,
        validateInput: options.validateInput,
        preserveHistory: false,  // Disable history for batch processing
        autoDetectFormat: options.autoDetectFormat
      )

      return inputs.map { input in
        convertTime(input: input, options: optimizedOptions)
      }
    }
  }

  func optimizedBatchConvertConcurrent(inputs: [String], options: TimeConversionOptions)
    -> [TimeConversionResult]
  {
    guard inputs.count > 10 else {
      // For small batches, use regular processing to avoid overhead
      return optimizedBatchConvert(inputs: inputs, options: options)
    }

    return batchProcessingQueue.sync {
      // Pre-validate timezone data
      let sourceTimezone =
        getCachedTimezone(options.sourceTimeZone.identifier) ?? options.sourceTimeZone
      let targetTimezone =
        getCachedTimezone(options.targetTimeZone.identifier) ?? options.targetTimeZone

      // Create optimized options with cached timezones
      let optimizedOptions = TimeConversionOptions(
        sourceFormat: options.sourceFormat,
        targetFormat: options.targetFormat,
        sourceTimeZone: sourceTimezone,
        targetTimeZone: targetTimezone,
        customFormat: options.customFormat,
        includeMilliseconds: options.includeMilliseconds,
        enableRealTimeConversion: false,
        batchProcessingEnabled: true,
        validateInput: options.validateInput,
        preserveHistory: false,
        autoDetectFormat: options.autoDetectFormat
      )

      // Process in chunks for better performance while maintaining order
      let chunkSize = max(1, inputs.count / ProcessInfo.processInfo.activeProcessorCount)
      let chunks = inputs.chunked(into: chunkSize)

      var results: [TimeConversionResult] = Array(
        repeating: .failure(error: "Processing"), count: inputs.count)
      let resultsQueue = DispatchQueue(label: "batch.results", attributes: .concurrent)
      let group = DispatchGroup()

      var currentIndex = 0
      for chunk in chunks {
        let startIndex = currentIndex
        currentIndex += chunk.count

        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
          let chunkResults = chunk.map { input in
            self.convertTime(input: input, options: optimizedOptions)
          }

          resultsQueue.async(flags: .barrier) {
            for (i, result) in chunkResults.enumerated() {
              results[startIndex + i] = result
            }
            group.leave()
          }
        }
      }

      group.wait()
      return results
    }
  }

  // MARK: - Performance Monitoring

  func measureConversionPerformance(
    input: String,
    options: TimeConversionOptions,
    iterations: Int = 100
  ) -> (averageTime: TimeInterval, result: TimeConversionResult) {
    var totalTime: TimeInterval = 0
    var lastResult: TimeConversionResult = .failure(error: "No conversion performed")

    for _ in 0..<iterations {
      let startTime = CFAbsoluteTimeGetCurrent()
      lastResult = convertTime(input: input, options: options)
      let endTime = CFAbsoluteTimeGetCurrent()
      totalTime += (endTime - startTime)
    }

    return (averageTime: totalTime / Double(iterations), result: lastResult)
  }

  func clearPerformanceCaches() {
    cacheQueue.async(flags: .barrier) {
      self.formatterCache.removeAll()
      self.timezoneCache.removeAll()
      // Reload common timezones
      self.preloadCommonTimezones()
    }
  }

  func getCacheStatistics() -> (formatterCacheSize: Int, timezoneCacheSize: Int) {
    return cacheQueue.sync {
      (formatterCacheSize: formatterCache.count, timezoneCacheSize: timezoneCache.count)
    }
  }

  // MARK: - Private Helper Methods

  // MARK: - Enhanced Error Handling

  private func parseInputWithEnhancedErrorHandling(
    _ input: String,
    format: TimeFormat,
    timeZone: TimeZone,
    customFormat: String
  ) -> Date? {
    return parseInput(input, format: format, timeZone: timeZone, customFormat: customFormat)
  }

  private func formatDateWithEnhancedErrorHandling(
    _ date: Date,
    format: TimeFormat,
    timeZone: TimeZone,
    customFormat: String,
    includeMilliseconds: Bool
  ) throws -> String {
    return formatDate(
      date, format: format, timeZone: timeZone, customFormat: customFormat,
      includeMilliseconds: includeMilliseconds)
  }

  private func generateDetailedParsingError(
    input: String,
    format: TimeFormat,
    timeZone: TimeZone,
    customFormat: String
  ) -> String {
    switch format {
    case .timestamp:
      let error = TimeConverterError.invalidTimestamp(input)
      return "\(error.localizedDescription) \(error.recoverySuggestion ?? "")"
    case .iso8601:
      return
        "Invalid ISO 8601 format: '\(input)'. Expected format like '2024-01-01T12:00:00Z' or '2024-01-01T12:00:00.000Z'. Check that the date components are valid (month 1-12, day 1-31, hour 0-23, etc.)."
    case .rfc2822:
      return
        "Invalid RFC 2822 format: '\(input)'. Expected format like 'Mon, 01 Jan 2024 12:00:00 GMT'. Ensure the day name, date components, and timezone are correctly formatted."
    case .custom:
      return
        "Invalid custom format: '\(input)' does not match pattern '\(customFormat)'. Common patterns: yyyy=year, MM=month, dd=day, HH=hour (24h), mm=minute, ss=second. Example: 'yyyy-MM-dd HH:mm:ss' for '2024-01-01 12:00:00'."
    }
  }

  private func generateTimezoneConversionError(
    from sourceTimeZone: TimeZone,
    to targetTimeZone: TimeZone,
    date: Date
  ) -> String {
    if !isTimezoneAvailable(sourceTimeZone) {
      return
        "Source timezone '\(sourceTimeZone.identifier)' is not available. Please select a valid timezone from the list."
    }

    if !isTimezoneAvailable(targetTimeZone) {
      return
        "Target timezone '\(targetTimeZone.identifier)' is not available. Please select a valid timezone from the list."
    }

    if !validateTimezoneCompatibility(source: sourceTimeZone, target: targetTimeZone, for: date) {
      return
        "Timezone conversion failed due to incompatible timezone data for the given date. This may occur with historical dates or future dates beyond timezone data availability."
    }

    return
      "Timezone conversion failed between '\(sourceTimeZone.identifier)' and '\(targetTimeZone.identifier)'. Please verify the timezones and try again."
  }

  // MARK: - Caching and Performance

  private func preloadCommonTimezones() {
    cacheQueue.async(flags: .barrier) {
      let commonIdentifiers = [
        "UTC", "America/New_York", "America/Los_Angeles", "Europe/London",
        "Europe/Paris", "Asia/Tokyo", "Asia/Shanghai", "Australia/Sydney",
      ]

      for identifier in commonIdentifiers {
        if let timezone = TimeZone(identifier: identifier) {
          self.timezoneCache[identifier] = timezone
        }
      }
    }
  }

  private func getCachedTimezone(_ identifier: String) -> TimeZone? {
    return cacheQueue.sync {
      if let cached = timezoneCache[identifier] {
        return cached
      }

      // Cache miss - load and cache
      if let timezone = TimeZone(identifier: identifier) {
        timezoneCache[identifier] = timezone
        return timezone
      }

      return nil
    }
  }

  private func getCachedFormatter(for format: String, timeZone: TimeZone) -> DateFormatter {
    let cacheKey = "\(format)_\(timeZone.identifier)"

    return cacheQueue.sync {
      if let cached = formatterCache[cacheKey] {
        return cached
      }

      // Create new formatter
      let formatter = DateFormatter()
      formatter.dateFormat = format
      formatter.timeZone = timeZone
      formatter.locale = Locale(identifier: "en_US_POSIX")

      formatterCache[cacheKey] = formatter
      return formatter
    }
  }

  private func parseInput(
    _ input: String,
    format: TimeFormat,
    timeZone: TimeZone,
    customFormat: String
  ) -> Date? {
    let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

    switch format {
    case .timestamp:
      return parseTimestamp(trimmedInput)

    case .iso8601:
      return parseISO8601(trimmedInput)

    case .rfc2822:
      return parseRFC2822(trimmedInput, timeZone: timeZone)

    case .custom:
      return parseCustomFormat(trimmedInput, format: customFormat, timeZone: timeZone)
    }
  }

  private func parseTimestamp(_ input: String) -> Date? {
    guard let timestamp = Double(input) else { return nil }

    // Handle both seconds and milliseconds timestamps
    let adjustedTimestamp: TimeInterval =
      if timestamp > 1_000_000_000_000 {  // Likely milliseconds
        timestamp / 1000
      } else {
        timestamp
      }

    return Date(timeIntervalSince1970: adjustedTimestamp)
  }

  private func parseISO8601(_ input: String) -> Date? {
    // Try with fractional seconds first
    if let date = iso8601Formatter.date(from: input) {
      return date
    }

    // Try without fractional seconds
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: input)
  }

  private func parseRFC2822(_ input: String, timeZone: TimeZone) -> Date? {
    rfc2822Formatter.timeZone = timeZone
    return rfc2822Formatter.date(from: input)
  }

  private func parseCustomFormat(_ input: String, format: String, timeZone: TimeZone) -> Date? {
    let formatter = getCachedFormatter(for: format, timeZone: timeZone)
    return formatter.date(from: input)
  }

  private func formatDate(
    _ date: Date,
    format: TimeFormat,
    timeZone: TimeZone,
    customFormat: String,
    includeMilliseconds: Bool
  ) -> String {
    switch format {
    case .timestamp:
      let timestamp = date.timeIntervalSince1970
      if includeMilliseconds {
        return String(format: "%.3f", timestamp)
      } else {
        return String(Int(timestamp))
      }

    case .iso8601:
      let formatter = ISO8601DateFormatter()
      formatter.timeZone = timeZone
      if includeMilliseconds {
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      } else {
        formatter.formatOptions = [.withInternetDateTime]
      }
      return formatter.string(from: date)

    case .rfc2822:
      let formatter = DateFormatter()
      formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
      formatter.timeZone = timeZone
      formatter.locale = Locale(identifier: "en_US_POSIX")
      return formatter.string(from: date)

    case .custom:
      let formatter = getCachedFormatter(for: customFormat, timeZone: timeZone)
      return formatter.string(from: date)
    }
  }
}

// MARK: - Array Extension for Batch Processing

extension Array {
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }
}

// MARK: - Time Converter Service Extensions

extension TimeConverterService {
  // MARK: - Batch Conversion

  func batchConvert(inputs: [String], options: TimeConversionOptions) -> [TimeConversionResult] {
    inputs.map { convertTime(input: $0, options: options) }
  }

  // MARK: - Time Difference Calculation

  func calculateTimeDifference(
    from startDate: Date,
    to endDate: Date
  ) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
    let timeInterval = endDate.timeIntervalSince(startDate)
    let totalSeconds = Int(abs(timeInterval))

    let days = totalSeconds / 86400
    let hours = (totalSeconds % 86400) / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    return (days: days, hours: hours, minutes: minutes, seconds: seconds)
  }

  // MARK: - Relative Time

  func getRelativeTime(from date: Date, to referenceDate: Date = Date()) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full

    return formatter.localizedString(for: date, relativeTo: referenceDate)
  }

  // MARK: - Format Examples

  func getFormatExamples(for format: TimeFormat, timeZone: TimeZone = .current) -> [String] {
    let sampleDate = Date()
    let pastDate = Date().addingTimeInterval(-86400)  // 1 day ago
    let futureDate = Date().addingTimeInterval(86400)  // 1 day from now

    return [
      formatDate(
        sampleDate,
        format: format,
        timeZone: timeZone,
        customFormat: "yyyy-MM-dd HH:mm:ss",
        includeMilliseconds: false),
      formatDate(
        pastDate,
        format: format,
        timeZone: timeZone,
        customFormat: "yyyy-MM-dd HH:mm:ss",
        includeMilliseconds: false),
      formatDate(
        futureDate,
        format: format,
        timeZone: timeZone,
        customFormat: "yyyy-MM-dd HH:mm:ss",
        includeMilliseconds: false),
    ]
  }
}
