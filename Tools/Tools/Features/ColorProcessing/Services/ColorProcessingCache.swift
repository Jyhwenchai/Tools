import Foundation

/// Cache service for optimizing color processing performance
@MainActor
class ColorProcessingCache: ObservableObject {

    // MARK: - Cache Configuration

    private let maxCacheSize: Int
    private let cacheExpirationTime: TimeInterval

    // MARK: - Cache Storage

    private var conversionCache: [String: CachedConversion] = [:]
    private var validationCache: [String: CachedValidation] = [:]
    private var colorRepresentationCache: [String: CachedColorRepresentation] = [:]

    // MARK: - Cache Statistics

    @Published var cacheHits: Int = 0
    @Published var cacheMisses: Int = 0
    @Published var cacheSize: Int = 0

    // MARK: - Initialization

    init(maxCacheSize: Int = 1000, cacheExpirationTime: TimeInterval = 300) {
        self.maxCacheSize = maxCacheSize
        self.cacheExpirationTime = cacheExpirationTime

        // Start cache cleanup timer
        startCacheCleanupTimer()
    }

    // MARK: - Conversion Caching

    /// Cache color conversion result
    func cacheConversion(
        from sourceFormat: ColorFormat,
        to targetFormat: ColorFormat,
        input: String,
        result: Result<String, ColorProcessingError>
    ) {
        let key = conversionCacheKey(from: sourceFormat, to: targetFormat, input: input)
        let cachedConversion = CachedConversion(
            sourceFormat: sourceFormat,
            targetFormat: targetFormat,
            input: input,
            result: result,
            timestamp: Date()
        )

        conversionCache[key] = cachedConversion
        updateCacheSize()

        // Cleanup if cache is too large
        if conversionCache.count > maxCacheSize {
            cleanupOldestEntries()
        }
    }

    /// Retrieve cached conversion result
    func getCachedConversion(
        from sourceFormat: ColorFormat,
        to targetFormat: ColorFormat,
        input: String
    ) -> Result<String, ColorProcessingError>? {
        let key = conversionCacheKey(from: sourceFormat, to: targetFormat, input: input)

        guard let cachedConversion = conversionCache[key],
            !isExpired(cachedConversion.timestamp)
        else {
            cacheMisses += 1
            return nil
        }

        cacheHits += 1
        return cachedConversion.result
    }

    // MARK: - Validation Caching

    /// Cache validation result
    func cacheValidation(
        input: String,
        format: ColorFormat,
        result: ValidationResult
    ) {
        let key = validationCacheKey(input: input, format: format)
        let cachedValidation = CachedValidation(
            input: input,
            format: format,
            result: result,
            timestamp: Date()
        )

        validationCache[key] = cachedValidation
        updateCacheSize()

        // Cleanup if cache is too large
        if validationCache.count > maxCacheSize {
            cleanupOldestValidationEntries()
        }
    }

    /// Retrieve cached validation result
    func getCachedValidation(
        input: String,
        format: ColorFormat
    ) -> ValidationResult? {
        let key = validationCacheKey(input: input, format: format)

        guard let cachedValidation = validationCache[key],
            !isExpired(cachedValidation.timestamp)
        else {
            cacheMisses += 1
            return nil
        }

        cacheHits += 1
        return cachedValidation.result
    }

    // MARK: - Color Representation Caching

    /// Cache complete color representation
    func cacheColorRepresentation(
        input: String,
        format: ColorFormat,
        representation: ColorRepresentation
    ) {
        let key = colorRepresentationCacheKey(input: input, format: format)
        let cachedRepresentation = CachedColorRepresentation(
            input: input,
            format: format,
            representation: representation,
            timestamp: Date()
        )

        colorRepresentationCache[key] = cachedRepresentation
        updateCacheSize()

        // Cleanup if cache is too large
        if colorRepresentationCache.count > maxCacheSize {
            cleanupOldestRepresentationEntries()
        }
    }

    /// Retrieve cached color representation
    func getCachedColorRepresentation(
        input: String,
        format: ColorFormat
    ) -> ColorRepresentation? {
        let key = colorRepresentationCacheKey(input: input, format: format)

        guard let cachedRepresentation = colorRepresentationCache[key],
            !isExpired(cachedRepresentation.timestamp)
        else {
            cacheMisses += 1
            return nil
        }

        cacheHits += 1
        return cachedRepresentation.representation
    }

    // MARK: - Cache Management

    /// Clear all caches
    func clearAllCaches() {
        conversionCache.removeAll()
        validationCache.removeAll()
        colorRepresentationCache.removeAll()
        updateCacheSize()
        resetStatistics()
    }

    /// Clear expired entries
    func clearExpiredEntries() {
        let now = Date()

        conversionCache = conversionCache.filter { !isExpired($0.value.timestamp, relativeTo: now) }
        validationCache = validationCache.filter { !isExpired($0.value.timestamp, relativeTo: now) }
        colorRepresentationCache = colorRepresentationCache.filter {
            !isExpired($0.value.timestamp, relativeTo: now)
        }

        updateCacheSize()
    }

    /// Get cache statistics
    func getCacheStatistics() -> CacheStatistics {
        let totalRequests = cacheHits + cacheMisses
        let hitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0

        return CacheStatistics(
            cacheHits: cacheHits,
            cacheMisses: cacheMisses,
            hitRate: hitRate,
            totalEntries: cacheSize,
            conversionEntries: conversionCache.count,
            validationEntries: validationCache.count,
            representationEntries: colorRepresentationCache.count
        )
    }

    // MARK: - Private Methods

    private func conversionCacheKey(
        from sourceFormat: ColorFormat, to targetFormat: ColorFormat, input: String
    ) -> String {
        return "\(sourceFormat.rawValue)_to_\(targetFormat.rawValue)_\(input.lowercased())"
    }

    private func validationCacheKey(input: String, format: ColorFormat) -> String {
        return "validation_\(format.rawValue)_\(input.lowercased())"
    }

    private func colorRepresentationCacheKey(input: String, format: ColorFormat) -> String {
        return "representation_\(format.rawValue)_\(input.lowercased())"
    }

    private func isExpired(_ timestamp: Date, relativeTo now: Date = Date()) -> Bool {
        return now.timeIntervalSince(timestamp) > cacheExpirationTime
    }

    private func updateCacheSize() {
        cacheSize = conversionCache.count + validationCache.count + colorRepresentationCache.count
    }

    private func resetStatistics() {
        cacheHits = 0
        cacheMisses = 0
    }

    private func cleanupOldestEntries() {
        let sortedEntries = conversionCache.sorted { $0.value.timestamp < $1.value.timestamp }
        let entriesToRemove = sortedEntries.prefix(maxCacheSize / 10)  // Remove 10% of oldest entries

        for (key, _) in entriesToRemove {
            conversionCache.removeValue(forKey: key)
        }

        updateCacheSize()
    }

    private func cleanupOldestValidationEntries() {
        let sortedEntries = validationCache.sorted { $0.value.timestamp < $1.value.timestamp }
        let entriesToRemove = sortedEntries.prefix(maxCacheSize / 10)

        for (key, _) in entriesToRemove {
            validationCache.removeValue(forKey: key)
        }

        updateCacheSize()
    }

    private func cleanupOldestRepresentationEntries() {
        let sortedEntries = colorRepresentationCache.sorted {
            $0.value.timestamp < $1.value.timestamp
        }
        let entriesToRemove = sortedEntries.prefix(maxCacheSize / 10)

        for (key, _) in entriesToRemove {
            colorRepresentationCache.removeValue(forKey: key)
        }

        updateCacheSize()
    }

    private func startCacheCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.clearExpiredEntries()
            }
        }
    }
}

// MARK: - Cache Data Models

private struct CachedConversion {
    let sourceFormat: ColorFormat
    let targetFormat: ColorFormat
    let input: String
    let result: Result<String, ColorProcessingError>
    let timestamp: Date
}

private struct CachedValidation {
    let input: String
    let format: ColorFormat
    let result: ValidationResult
    let timestamp: Date
}

private struct CachedColorRepresentation {
    let input: String
    let format: ColorFormat
    let representation: ColorRepresentation
    let timestamp: Date
}

// MARK: - Cache Statistics

struct CacheStatistics {
    let cacheHits: Int
    let cacheMisses: Int
    let hitRate: Double
    let totalEntries: Int
    let conversionEntries: Int
    let validationEntries: Int
    let representationEntries: Int
}

// MARK: - Cache Integration Extensions

extension ColorConversionService {

    /// Create a cached version of the color conversion service
    func withCache(cache: ColorProcessingCache) -> CachedColorConversionService {
        return CachedColorConversionService(conversionService: self, cache: cache)
    }
}

/// Cached wrapper for ColorConversionService
@MainActor
class CachedColorConversionService: ObservableObject {

    private let conversionService: ColorConversionService
    private let cache: ColorProcessingCache

    init(conversionService: ColorConversionService, cache: ColorProcessingCache) {
        self.conversionService = conversionService
        self.cache = cache
    }

    /// Convert color with caching
    func convertColor(
        from sourceFormat: ColorFormat,
        to targetFormat: ColorFormat,
        value: String
    ) -> Result<String, ColorProcessingError> {
        // Check cache first
        if let cachedResult = cache.getCachedConversion(
            from: sourceFormat,
            to: targetFormat,
            input: value
        ) {
            return cachedResult
        }

        // Perform conversion
        let result = conversionService.convertColor(
            from: sourceFormat,
            to: targetFormat,
            value: value
        )

        // Cache the result
        cache.cacheConversion(
            from: sourceFormat,
            to: targetFormat,
            input: value,
            result: result
        )

        return result
    }
}
