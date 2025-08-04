import Combine
import Foundation

/// Debouncer utility for optimizing color processing input validation
@MainActor
class ColorProcessingDebouncer: ObservableObject {

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval

    // MARK: - Published Properties

    @Published var debouncedValue: String = ""
    @Published var isDebouncing: Bool = false

    // MARK: - Initialization

    init(debounceInterval: TimeInterval = 0.3) {
        self.debounceInterval = debounceInterval
    }

    // MARK: - Debouncing Methods

    /// Debounce color input validation to reduce CPU usage
    func debounceColorInput(_ input: String, completion: @escaping (String) -> Void) {
        isDebouncing = true

        // Cancel previous debounce operations
        cancellables.removeAll()

        // Create a debounced publisher
        Just(input)
            .delay(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak self] debouncedInput in
                self?.isDebouncing = false
                self?.debouncedValue = debouncedInput
                completion(debouncedInput)
            }
            .store(in: &cancellables)
    }

    /// Debounce color validation with format detection
    func debounceColorValidation(
        _ input: String,
        completion: @escaping (String, ColorFormat?) -> Void
    ) {
        debounceColorInput(input) { debouncedInput in
            let detectedFormat = ColorFormatDetector.detectFormat(debouncedInput)
            completion(debouncedInput, detectedFormat)
        }
    }

    /// Debounce color conversion operations
    func debounceColorConversion(
        _ input: String,
        from sourceFormat: ColorFormat,
        to targetFormat: ColorFormat,
        completion: @escaping (String, Result<String, ColorProcessingError>) -> Void
    ) {
        debounceColorInput(input) { debouncedInput in
            let conversionService = ColorConversionService()
            let result = conversionService.convertColor(
                from: sourceFormat,
                to: targetFormat,
                value: debouncedInput
            )
            completion(debouncedInput, result)
        }
    }

    /// Cancel all pending debounce operations
    func cancelDebouncing() {
        cancellables.removeAll()
        isDebouncing = false
    }

    // MARK: - Batch Debouncing

    /// Debounce multiple color operations for batch processing
    func debounceBatchOperations<T>(
        operations: [T],
        debounceInterval: TimeInterval? = nil,
        completion: @escaping ([T]) -> Void
    ) {
        let interval = debounceInterval ?? self.debounceInterval
        isDebouncing = true

        cancellables.removeAll()

        Just(operations)
            .delay(for: .seconds(interval), scheduler: DispatchQueue.main)
            .sink { [weak self] debouncedOperations in
                self?.isDebouncing = false
                completion(debouncedOperations)
            }
            .store(in: &cancellables)
    }

    // MARK: - Memory Management

    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Debounced Color Processing Extensions

extension ColorConversionService {

    /// Create a debounced version of color conversion
    func createDebouncedConverter(debounceInterval: TimeInterval = 0.3) -> ColorProcessingDebouncer
    {
        return ColorProcessingDebouncer(debounceInterval: debounceInterval)
    }
}

extension ColorFormatDetector {

    /// Debounced format detection
    @MainActor
    static func debouncedDetectFormat(
        _ input: String,
        debouncer: ColorProcessingDebouncer,
        completion: @escaping (ColorFormat?) -> Void
    ) {
        debouncer.debounceColorInput(input) { debouncedInput in
            let format = ColorFormatDetector.detectFormat(debouncedInput)
            completion(format)
        }
    }

    /// Debounced input validation
    @MainActor
    static func debouncedValidateInput(
        _ input: String,
        expectedFormat: ColorFormat,
        debouncer: ColorProcessingDebouncer,
        completion: @escaping (ValidationResult) -> Void
    ) {
        debouncer.debounceColorInput(input) { debouncedInput in
            let result = ColorFormatDetector.validateInput(
                debouncedInput, expectedFormat: expectedFormat)
            completion(result)
        }
    }
}

// MARK: - Performance Monitoring

extension ColorProcessingDebouncer {

    /// Monitor debouncing performance
    func measureDebouncingPerformance<T>(
        operation: @escaping () -> T,
        completion: @escaping (T, TimeInterval) -> Void
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()

        debounceColorInput("") { _ in
            let result = operation()
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            completion(result, timeElapsed)
        }
    }
}
