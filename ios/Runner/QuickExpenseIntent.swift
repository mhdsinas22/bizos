import AppIntents
import Foundation
import Security

// MARK: - Category Entity

struct ExpenseCategory: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Expense Category")
    }

    static var defaultQuery = ExpenseCategoryQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
struct PaymentMethod: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Payment Method")
    }

    static var defaultQuery = PaymentMethodQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
enum BuiltInPaymentMethod{
    static let all:[PaymentMethod]=[
        PaymentMethod(id: "1", name: "Cash"),
        PaymentMethod(id: "2", name: "UPI"),
        PaymentMethod(id: "3", name: "Bank Transfer"),
        PaymentMethod(id: "4", name: "Credit Card"),
        PaymentMethod(id: "5", name: "Debit Card"),
        PaymentMethod(id: "6", name: "Cheque"),
        PaymentMethod(id: "7", name: "Wallet"),
        PaymentMethod(id: "8", name: "Other"),
    ]
}
enum BuiltInCategories{
    static let all:[ExpenseCategory]=[
        ExpenseCategory(id:"1",name:"Food"),
        ExpenseCategory(id: "2", name: "Travel"),
        ExpenseCategory(id:"3",name:"Fuel"),
        ExpenseCategory(id:"4",name:"Shopping"),
        ExpenseCategory(id:"5",name:"Medical"),
        ExpenseCategory(id:"6",name:"Family"),
        ExpenseCategory(id:"7",name:"Education"),
        ExpenseCategory(id:"8",name:"Entertainment"),
        ExpenseCategory(id:"9",name:"Bills"),
        ExpenseCategory(id:"10",name:"Investment"),
        ExpenseCategory(id:"11",name:"Other"),
    ]
}
struct PaymentMethodQuery:
    EntityQuery,
    EnumerableEntityQuery,
    EntityStringQuery{
    func entities(for identifiers:[PaymentMethod.ID])async throws ->[PaymentMethod]{
        BuiltInPaymentMethod.all.filter{
            identifiers.contains($0.id)
        }
    }
    func suggestedEntities() async throws -> [PaymentMethod] {
        BuiltInPaymentMethod.all
    }
    func allEntities() async throws -> [PaymentMethod] {
        BuiltInPaymentMethod.all
    }
    func entities(matching string:String)async throws ->[PaymentMethod]{
        let query=string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return BuiltInPaymentMethod.all
        }
        return BuiltInPaymentMethod.all.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    
}

// MARK: - Category Cache

private actor CategoryCache {
    static let shared = CategoryCache()
    private var cachedCategories: [ExpenseCategory] = []
    private var lastFetchTime: Date?

    func get() -> [ExpenseCategory]? {
        guard let lastFetch = lastFetchTime, Date().timeIntervalSince(lastFetch) < 60 else {
            return nil
        }
        return cachedCategories.isEmpty ? nil : cachedCategories
    }

    func set(_ categories: [ExpenseCategory]) {
        self.cachedCategories = categories
        self.lastFetchTime = Date()
    }

    func clear() {
        self.cachedCategories = []
        self.lastFetchTime = nil
    }
}

// MARK: - Dynamic Category Query

struct ExpenseCategoryQuery: EntityQuery, EnumerableEntityQuery, EntityStringQuery {
    func entities(for identifiers: [ExpenseCategory.ID]) async throws -> [ExpenseCategory] {
        let all = (try? await fetchCategories()) ?? []
        return identifiers.compactMap { id in
            if let match = all.first(where: {
                $0.id == id || $0.name.caseInsensitiveCompare(id) == .orderedSame
            }) {
                return match
            }
            let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return ExpenseCategory(id: trimmed, name: trimmed)
        }
    }

    func suggestedEntities() async throws -> [ExpenseCategory] {
        return try await fetchCategories()
    }

    func allEntities() async throws -> [ExpenseCategory] {
        return try await fetchCategories()
    }

    func entities(matching string: String) async throws -> [ExpenseCategory] {
        let all = try await fetchCategories()

        let query = string.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if query.isEmpty {
            return all
        }

        return all.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    private func fetchCategories() async throws -> [ExpenseCategory] {
        if let cached = await CategoryCache.shared.get() {
            let combined = BuiltInCategories.all + cached

            return combined.reduce(into: [ExpenseCategory]()) {
                result, category in

                if !result.contains(where: {
                    $0.name.caseInsensitiveCompare(category.name) == .orderedSame
                }) {
                    result.append(category)
                }
            }
        }

        let token: String
        do {
            token = try ShortcutKeychain.readToken()
        } catch {
            throw ExpenseIntentError.tokenNotFound
        }

        guard let url = URL(
            string: "https://kbflmchliolaqkyouaxd.supabase.co/functions/v1/get-quick-categories"
        ) else {
            throw ExpenseIntentError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "x-shortcut-token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw ExpenseIntentError.networkError(error.localizedDescription)
        } catch {
            throw ExpenseIntentError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ExpenseIntentError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw ExpenseIntentError.authenticationFailed
            }
            throw ExpenseIntentError.categoryFetchFailed(http.statusCode)
        }

        var parsedItems: [CategoryResponseItem] = []

        if let wrapper = try? JSONDecoder().decode(CategoriesResponseWrapper.self, from: data) {
            parsedItems = wrapper.categories ?? wrapper.data ?? []
        } else if let array = try? JSONDecoder().decode([CategoryResponseItem].self, from: data) {
            parsedItems = array
        } else {
            throw ExpenseIntentError.invalidResponse
        }

        let categories = parsedItems.compactMap { item -> ExpenseCategory? in
            let cleanId = item.id.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanId.isEmpty, !cleanName.isEmpty else { return nil }
            return ExpenseCategory(id: cleanId, name: cleanName)
        }

  
        let combined = BuiltInCategories.all + categories
        let allCategories=combined.reduce(into:[ExpenseCategory]()){
            result,category in if !result.contains(where:{
                $0.name.caseInsensitiveCompare(category.name) == .orderedSame
            }){
                result.append(category)
            }
        }
        await CategoryCache.shared.set(allCategories)
        return allCategories
    }
}

// MARK: - Category Response Decoding Models

private struct CategoriesResponseWrapper: Decodable {
    let success: Bool?
    let categories: [CategoryResponseItem]?
    let data: [CategoryResponseItem]?
}

private struct CategoryResponseItem: Decodable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringId = try? container.decode(String.self, forKey: .id) {
            self.id = stringId
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = UUID().uuidString
        }
        self.name = try container.decode(String.self, forKey: .name)
    }
}

// MARK: - Quick Expense Intent

struct QuickExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Voryn Expenses"

    static var description = IntentDescription(
        "Add an expense to your Voryn account."
    )

    @Parameter(
        title: "Amount",
        description: "The expense amount",
        requestValueDialog: IntentDialog("What is the expense amount?")
    )
    var amount: Double

    @Parameter(
        title: "Category",
        description: "The expense category",
        requestValueDialog: IntentDialog("Which category would you like to assign this to?")
    )
    var category: ExpenseCategory
    @Parameter(
        title: "Payment Method",
        description: "Choose how you paid"
    )
    var paymentMethod: PaymentMethod
    static var parameterSummary: some ParameterSummary {
        Summary(
            "Add expense of \(\.$amount) for \(\.$category) using \(\.$paymentMethod)"
        )
    }

    private let supabaseURL =
        "https://kbflmchliolaqkyouaxd.supabase.co/functions/v1/quick-expense"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0, amount.isFinite else {
            throw ExpenseIntentError.invalidAmount
        }

        let cleanCategory = category.name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !cleanCategory.isEmpty else {
            throw ExpenseIntentError.invalidCategory
        }

        let token: String
        do {
            token = try ShortcutKeychain.readToken()
        } catch {
            throw ExpenseIntentError.tokenNotFound
        }

        guard let url = URL(string: supabaseURL) else {
            throw ExpenseIntentError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "x-shortcut-token")

        let body: [String: Any] = [
            "amount": amount,
            "category": cleanCategory,
            "payment_method":paymentMethod.name,
            "idempotency_key": UUID().uuidString
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw ExpenseIntentError.invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw ExpenseIntentError.networkError(error.localizedDescription)
        } catch {
            throw ExpenseIntentError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExpenseIntentError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw ExpenseIntentError.authenticationFailed
            }
            throw ExpenseIntentError.serverFailed(httpResponse.statusCode)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let success = json["success"] as? Bool, !success {
                let msg = json["error"] as? String ?? json["message"] as? String ?? "Server rejected the expense."
                throw ExpenseIntentError.networkError(msg)
            }
        }

        let formattedAmount: String = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        }()

        return .result(
            dialog: IntentDialog("Expense saved: \(formattedAmount) for \(cleanCategory).")
        )
    }
}

// MARK: - Shared Keychain Reader

enum ShortcutKeychain {
    static func readToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "voryn_shortcut_token",
            kSecAttrService as String: "flutter_secure_storage_service",
            kSecAttrAccessGroup as String: "8X62925YPH.com.voryn.erp",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty else {
            throw ExpenseIntentError.tokenNotFound
        }

        return token
    }
}

// MARK: - Intent Errors

private enum ExpenseIntentError: LocalizedError, CustomLocalizedStringResourceConvertible {
    case invalidAmount
    case invalidCategory
    case tokenNotFound
    case authenticationFailed
    case invalidResponse
    case categoryFetchFailed(Int)
    case serverFailed(Int)
    case noCategoriesFound
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Enter an amount greater than zero."
        case .invalidCategory:
            return "Please select a valid expense category."
        case .tokenNotFound:
            return "Voryn is not connected. Please open Voryn and pair your device."
        case .authenticationFailed:
            return "Voryn authentication failed. Please open Voryn to re-pair."
        case .invalidResponse:
            return "Voryn returned an invalid response. Please try again."
        case .categoryFetchFailed(let status):
            return "Unable to load categories from Voryn (Status: \(status))."
        case .serverFailed(let status):
            return "Unable to save expense. Voryn server status: \(status)."
        case .noCategoriesFound:
            return "No expense categories found. Please create categories in Voryn first."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }

    var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: errorDescription ?? "An unknown error occurred.")
    }
}

typealias VorynQuickAddExpenseIntent = QuickExpenseIntent

// MARK: - Siri Shortcut

struct VorynAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickExpenseIntent(),
            phrases: [
                "Add expense in \(.applicationName)",
                "Log expense in \(.applicationName)",
                "Add expense with \(.applicationName)",
                "Quick add expense in \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "creditcard"
        )
    }
}

