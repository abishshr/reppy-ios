import Foundation

/// HTTP API client for backend communication
final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let keychainService: KeychainService
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(keychainService: KeychainService) {
        self.baseURL = URL(string: Constants.API.baseURL)!
        self.keychainService = keychainService
        self.session = URLSession.shared

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Auth Endpoints

    func signInWithApple(identityToken: String, userName: String?, email: String?) async throws -> AuthResponse {
        let body = AppleSignInRequest(
            identityToken: identityToken,
            authorizationCode: nil,
            userName: userName,
            email: email
        )
        return try await post("/auth/apple", body: body)
    }

    /// Dev login for simulator testing (only works in development environment)
    func devLogin() async throws -> AuthResponse {
        try await post("/auth/dev", body: EmptyBody())
    }

    // MARK: - Profile Endpoints

    func fetchProfile() async throws -> UserProfile {
        try await get("/profile/me")
    }

    func createProfile(_ profile: ProfileCreate) async throws -> UserProfile {
        try await post("/profile/me", body: profile)
    }

    func updateProfile(_ profile: ProfileUpdate) async throws -> UserProfile {
        try await patch("/profile/me", body: profile)
    }

    // MARK: - Meal Endpoints

    func fetchMeals(days: Int = 7) async throws -> [Meal] {
        try await get("/meals/?days=\(days)")
    }

    func createMeal(_ meal: MealLogCreate) async throws -> Meal {
        try await post("/meals/", body: meal)
    }

    func getTodayMealSummary() async throws -> MealSummary {
        try await get("/meals/summary/today")
    }

    func quickAddCalories(
        calories: Int,
        description: String = "Quick Add",
        mealType: String = "snack",
        proteinG: Double? = nil,
        carbsG: Double? = nil,
        fatG: Double? = nil,
        loggedAt: Date = Date()
    ) async throws -> Meal {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let loggedAtStr = formatter.string(from: loggedAt).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        var query = "/meals/quick-add?calories=\(calories)&description=\(description.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? description)&meal_type=\(mealType)&logged_at=\(loggedAtStr)"
        if let protein = proteinG { query += "&protein_g=\(protein)" }
        if let carbs = carbsG { query += "&carbs_g=\(carbs)" }
        if let fat = fatG { query += "&fat_g=\(fat)" }
        return try await post(query, body: EmptyBody())
    }

    func getRecentUniqueMeals(days: Int = 7, limit: Int = 20) async throws -> [Meal] {
        try await get("/meals/recent-unique?days=\(days)&limit=\(limit)")
    }

    func getTestosteroneSummary() async throws -> TestosteroneSummary {
        try await get("/meals/testosterone-summary/today")
    }

    func copyMeal(mealId: String, mealType: String? = nil) async throws -> Meal {
        var query = "/meals/\(mealId)/copy"
        if let type = mealType { query += "?meal_type=\(type)" }
        return try await post(query, body: EmptyBody())
    }

    // MARK: - Food Database Endpoints

    func createCustomFood(_ food: CustomFoodCreate) async throws -> CustomFood {
        try await post("/foods", body: food)
    }

    func getMyCustomFoods() async throws -> [CustomFood] {
        let response: CustomFoodsResponse = try await get("/foods/my-foods")
        return response.foods
    }

    func searchFoodsDatabase(query: String, limit: Int = 20) async throws -> FoodSearchDatabaseResponse {
        try await get("/foods/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&limit=\(limit)")
    }

    func lookupBarcode(_ barcode: String) async throws -> BarcodeLookupResponse {
        try await get("/foods/barcode/\(barcode)")
    }

    func getRecentFoods(limit: Int = 20) async throws -> CustomFoodsResponse {
        try await get("/foods/recent?limit=\(limit)")
    }

    func getFrequentFoods(limit: Int = 20) async throws -> CustomFoodsResponse {
        try await get("/foods/frequent?limit=\(limit)")
    }

    func getFood(id: String) async throws -> CustomFood {
        try await get("/foods/\(id)")
    }

    func recordFoodUsage(foodId: String) async throws {
        let _: EmptyResponse = try await post("/foods/\(foodId)/log", body: EmptyBody())
    }

    func deleteCustomFood(id: String) async throws {
        let _: SuccessResponse = try await delete("/foods/\(id)")
    }

    // MARK: - Workout Endpoints

    func fetchWorkouts(days: Int = 7) async throws -> [Workout] {
        try await get("/workouts/?days=\(days)")
    }

    func createWorkout(_ workout: WorkoutLogCreate) async throws -> Workout {
        try await post("/workouts/", body: workout)
    }

    func getWeekWorkoutSummary() async throws -> WorkoutSummary {
        try await get("/workouts/summary/week")
    }

    // MARK: - Personal Records Endpoints

    func getPersonalRecords(limit: Int = 50) async throws -> [PersonalRecord] {
        try await get("/workouts/personal-records?limit=\(limit)")
    }

    func getRecentPRs(days: Int = 7) async throws -> [PersonalRecord] {
        try await get("/workouts/personal-records/recent?days=\(days)")
    }

    func getExercisePR(exerciseName: String) async throws -> PersonalRecord {
        let encoded = exerciseName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? exerciseName
        return try await get("/workouts/exercise/\(encoded)/pr")
    }

    func getExerciseHistory(exerciseName: String, limit: Int = 20) async throws -> [ExerciseAttempt] {
        let encoded = exerciseName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? exerciseName
        return try await get("/workouts/exercise/\(encoded)/history?limit=\(limit)")
    }

    func getLastExerciseAttempt(exerciseName: String) async throws -> ExerciseAttempt {
        let encoded = exerciseName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? exerciseName
        return try await get("/workouts/exercise/\(encoded)/last")
    }

    // MARK: - Activity Endpoints

    func syncSteps(date: Date, steps: Int) async throws -> DailyActivity {
        let body = StepsSyncRequest(date: date, steps: steps, source: "apple_health")
        return try await post("/activity/steps/sync", body: body)
    }

    func getActivitySummary() async throws -> ActivitySummary {
        try await get("/activity/summary")
    }

    // MARK: - Chat Endpoints

    func sendMessage(_ message: String, sessionId: String?, imageBase64: String? = nil) async throws -> ChatAPIResponse {
        let body = ChatRequest(
            message: message,
            sessionId: sessionId,
            imageUrl: nil,
            imageBase64: imageBase64,
            imageMimeType: imageBase64 != nil ? "image/jpeg" : nil
        )
        return try await post("/chat", body: body)
    }

    func confirmSuggestion(type: String, suggestionId: String, sessionId: String?) async throws -> ConfirmationResponse {
        try await post("/chat/confirm?suggestion_type=\(type)&suggestion_id=\(suggestionId)&session_id=\(sessionId ?? "")", body: EmptyBody())
    }

    // MARK: - Meal Plan Endpoints

    func fetchMealPlans(activeOnly: Bool = true) async throws -> [MealPlanSummary] {
        try await get("/meal-plans?active_only=\(activeOnly)")
    }

    func fetchActiveMealPlan() async throws -> MealPlan? {
        try await get("/meal-plans/active")
    }

    func fetchTodaysMeals() async throws -> MealPlanDay? {
        try await get("/meal-plans/today")
    }

    func fetchMealPlan(id: String) async throws -> MealPlan {
        try await get("/meal-plans/\(id)")
    }

    func deleteMealPlan(id: String) async throws {
        let _: SuccessResponse = try await delete("/meal-plans/\(id)")
    }

    func deactivateMealPlan(id: String) async throws {
        let _: SuccessResponse = try await patch("/meal-plans/\(id)/deactivate", body: EmptyBody())
    }

    func getRecipe(mealName: String, mealType: String) async throws -> MealRecipe {
        let body = RecipeRequest(mealName: mealName, mealType: mealType)
        return try await post("/meal-plans/recipe", body: body)
    }

    // MARK: - Grocery List Endpoints

    func fetchGroceryLists() async throws -> [GroceryList] {
        try await get("/meal-plans/grocery-lists")
    }

    func fetchGroceryList(id: String) async throws -> GroceryList {
        try await get("/meal-plans/grocery-lists/\(id)")
    }

    func toggleGroceryItem(listId: String, itemIndex: Int, checked: Bool) async throws {
        let body = GroceryItemUpdateRequest(itemIndex: itemIndex, checked: checked)
        let _: SuccessResponse = try await patch("/meal-plans/grocery-lists/\(listId)/item", body: body)
    }

    func deleteGroceryList(id: String) async throws {
        let _: SuccessResponse = try await delete("/meal-plans/grocery-lists/\(id)")
    }

    // MARK: - Workout Plan Endpoints

    func fetchWorkoutPlans(activeOnly: Bool = true) async throws -> [WorkoutPlanSummary] {
        try await get("/workout-plans?active_only=\(activeOnly)")
    }

    func fetchActiveWorkoutPlan() async throws -> WorkoutPlan? {
        try await get("/workout-plans/active")
    }

    func fetchWorkoutPlan(id: String) async throws -> WorkoutPlan {
        try await get("/workout-plans/\(id)")
    }

    func fetchTodaysWorkout() async throws -> WorkoutPlanDay? {
        try await get("/workout-plans/today")
    }

    func fetchWeekWorkouts(planId: String, weekNumber: Int) async throws -> [WorkoutPlanDay] {
        try await get("/workout-plans/\(planId)/week/\(weekNumber)")
    }

    func completeWorkoutDay(planId: String, dayId: String) async throws {
        let body = CompleteWorkoutDayRequest(workoutDayId: dayId)
        let _: SuccessResponse = try await post("/workout-plans/\(planId)/complete-day", body: body)
    }

    func deleteWorkoutPlan(id: String) async throws {
        let _: SuccessResponse = try await delete("/workout-plans/\(id)")
    }

    func deactivateWorkoutPlan(id: String) async throws {
        let _: SuccessResponse = try await patch("/workout-plans/\(id)/deactivate", body: EmptyBody())
    }

    func searchExercises(query: String, muscleGroup: String? = nil, equipment: String? = nil, limit: Int = 20) async throws -> [ExerciseSearchResult] {
        var path = "/workout-plans/exercises/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&limit=\(limit)"
        if let muscleGroup = muscleGroup {
            path += "&muscle_group=\(muscleGroup)"
        }
        if let equipment = equipment {
            path += "&equipment=\(equipment)"
        }
        return try await get(path)
    }

    func createWorkoutPlan(_ request: WorkoutPlanCreateRequest) async throws -> WorkoutPlan {
        try await post("/workout-plans", body: request)
    }

    // MARK: - Food Search & Manual Meal Plan Creation

    func searchFoods(query: String, diet: String? = nil, limit: Int = 20) async throws -> [FoodSearchResult] {
        var path = "/meal-plans/foods/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&limit=\(limit)"
        if let diet = diet {
            path += "&diet=\(diet)"
        }
        return try await get(path)
    }

    func createMealPlan(_ request: MealPlanCreateRequest) async throws -> MealPlan {
        try await post("/meal-plans", body: request)
    }

    // MARK: - Water Tracking

    func logWater(amountMl: Int, source: String = "manual") async throws -> WaterLog {
        let body = WaterLogCreateRequest(amountMl: amountMl, source: source)
        return try await post("/water", body: body)
    }

    func getTodayWater() async throws -> WaterSummary {
        try await get("/water/today")
    }

    func getWaterStats() async throws -> WaterStats {
        try await get("/water/stats")
    }

    func getWaterHistory(days: Int = 7) async throws -> [WaterSummary] {
        try await get("/water/history?days=\(days)")
    }

    func deleteWaterLog(id: String) async throws {
        let _: EmptyResponse = try await delete("/water/\(id)")
    }

    func updateWaterGoal(goalMl: Int) async throws {
        let _: SuccessResponse = try await patch("/water/goal?goal_ml=\(goalMl)", body: EmptyBody())
    }

    // MARK: - Progress Endpoints

    func logWeight(weightKg: Double, notes: String? = nil) async throws -> WeightLog {
        let body = WeightLogCreateRequest(weightKg: weightKg, notes: notes)
        return try await post("/progress/weight", body: body)
    }

    func fetchWeightHistory(days: Int = 30) async throws -> [WeightLog] {
        try await get("/progress/weight?days=\(days)")
    }

    func deleteWeightLog(id: String) async throws {
        let _: SuccessResponse = try await delete("/progress/weight/\(id)")
    }

    func fetchWeightAnalytics(days: Int = 30) async throws -> WeightProgress {
        try await get("/progress/weight/analytics?days=\(days)")
    }

    func fetchWorkoutProgress(days: Int = 30) async throws -> WorkoutProgress {
        try await get("/progress/workouts/analytics?days=\(days)")
    }

    func fetchNutritionProgress(days: Int = 30) async throws -> NutritionProgress {
        try await get("/progress/nutrition/analytics?days=\(days)")
    }

    func fetchStepsProgress(days: Int = 30) async throws -> StepsProgress {
        try await get("/progress/steps/analytics?days=\(days)")
    }

    func fetchProgressSummary(days: Int = 30) async throws -> ProgressSummary {
        try await get("/progress/summary?days=\(days)")
    }

    // MARK: - Streak Endpoints

    func getStreak() async throws -> StreakInfo {
        try await get("/streak/")
    }

    func recordActivity() async throws -> StreakUpdateResponse {
        try await post("/streak/record", body: EmptyBody())
    }

    // MARK: - Body Measurements Endpoints

    func fetchMeasurements(limit: Int = 50) async throws -> [BodyMeasurement] {
        try await get("/measurements/?limit=\(limit)")
    }

    func createMeasurement(_ measurement: BodyMeasurementCreate) async throws -> BodyMeasurement {
        try await post("/measurements/", body: measurement)
    }

    func getLatestMeasurement() async throws -> BodyMeasurement {
        try await get("/measurements/latest")
    }

    func compareMeasurements() async throws -> MeasurementComparison {
        try await get("/measurements/compare")
    }

    func calculateBodyFat(waistCm: Double, neckCm: Double, hipsCm: Double? = nil) async throws -> BodyFatCalculation {
        var query = "/measurements/calculate-body-fat?waist_cm=\(waistCm)&neck_cm=\(neckCm)"
        if let hips = hipsCm {
            query += "&hips_cm=\(hips)"
        }
        return try await post(query, body: EmptyBody())
    }

    func deleteMeasurement(id: String) async throws {
        let _: EmptyResponse = try await delete("/measurements/\(id)")
    }

    // MARK: - Menstrual Cycle Endpoints (Female Users Only)

    func logCycleData(_ data: MenstrualLogCreate) async throws -> MenstrualCycleLog {
        try await post("/cycle/log", body: data)
    }

    func getTodayCycleLog() async throws -> MenstrualCycleLog? {
        do {
            return try await get("/cycle/today")
        } catch {
            // Returns nil if no log exists for today
            return nil
        }
    }

    func getCycleStatus() async throws -> CycleStatus {
        try await get("/cycle/status")
    }

    func getCycleRecommendations() async throws -> CycleRecommendations {
        try await get("/cycle/recommendations")
    }

    func getCycleHistory(days: Int = 90) async throws -> CycleHistory {
        try await get("/cycle/history?days=\(days)")
    }

    func getCycleCalendar(month: Int, year: Int) async throws -> [CycleCalendarDay] {
        try await get("/cycle/calendar?month=\(month)&year=\(year)")
    }

    func getCycleSettings() async throws -> CycleSettings {
        try await get("/cycle/settings")
    }

    func updateCycleSettings(_ settings: CycleSettingsUpdate) async throws -> CycleSettings {
        try await patch("/cycle/settings", body: settings)
    }

    func deleteCycleLog(id: String) async throws {
        let _: EmptyResponse = try await delete("/cycle/log/\(id)")
    }

    // MARK: - Fasting Endpoints

    func startFast(protocol fastingProtocol: FastingProtocol, durationHours: Double? = nil, notes: String? = nil) async throws -> FastingSession {
        let body = StartFastRequest(protocol: fastingProtocol, durationHours: durationHours, notes: notes)
        return try await post("/fasting", body: body)
    }

    func stopFast(completed: Bool = true, notes: String? = nil) async throws -> FastingSession {
        let body = StopFastRequest(completed: completed, notes: notes)
        return try await post("/fasting/stop", body: body)
    }

    func getActiveFast() async throws -> ActiveFastResponse {
        try await get("/fasting/active")
    }

    func getFastingHistory(page: Int = 1, pageSize: Int = 20) async throws -> FastingHistoryResponse {
        try await get("/fasting/history?page=\(page)&page_size=\(pageSize)")
    }

    func getFastingStats() async throws -> FastingStats {
        try await get("/fasting/stats")
    }

    func getFastingSettings() async throws -> FastingSettings {
        try await get("/fasting/settings")
    }

    func updateFastingSettings(_ settings: UpdateFastingSettingsRequest) async throws -> FastingSettings {
        try await patch("/fasting/settings", body: settings)
    }

    func getFastingProtocols() async throws -> [FastingProtocolInfo] {
        try await get("/fasting/protocols")
    }

    func deleteFastingSession(id: String) async throws {
        let _: EmptyResponse = try await delete("/fasting/\(id)")
    }

    // MARK: - Goal Prediction Endpoints

    func getGoalSettings() async throws -> GoalSettings {
        try await get("/progress/weight/goal-settings")
    }

    func updateGoalSettings(_ settings: UpdateGoalSettingsRequest) async throws -> GoalSettings {
        try await patch("/progress/weight/goal-settings", body: settings)
    }

    func clearGoalSettings() async throws {
        let _: EmptyResponse = try await delete("/progress/weight/goal-settings")
    }

    func getWeightPrediction(days: Int = 90) async throws -> GoalPrediction {
        try await get("/progress/weight/prediction?days=\(days)")
    }

    // MARK: - Health Score Endpoints

    func analyzeMealHealth(mealId: String) async throws -> MealHealthAnalysis {
        try await post("/meals/\(mealId)/analyze-health", body: EmptyBody())
    }

    func getTodayHealthSummary() async throws -> DailyHealthSummary {
        try await get("/meals/health-summary/today")
    }

    // MARK: - Nutrient Synergy Endpoints

    func getMealSynergies(mealId: String) async throws -> MealSynergyAnalysis {
        try await get("/meals/\(mealId)/synergy")
    }

    // MARK: - Circadian Rhythm Endpoints

    func getCircadianAnalysis(days: Int = 14) async throws -> CircadianAnalysis {
        try await get("/circadian/analysis?days=\(days)")
    }

    func getCircadianRecommendations(days: Int = 14) async throws -> [CircadianRecommendation] {
        try await get("/circadian/recommendations?days=\(days)")
    }

    func getOptimalMealTimes(wakeTime: String, sleepTime: String) async throws -> OptimalMealTimes {
        let body = OptimalMealTimesRequest(wakeTime: wakeTime, sleepTime: sleepTime)
        return try await post("/circadian/optimal-times", body: body)
    }

    func getEatingWindowStats(days: Int = 7) async throws -> EatingWindowStats {
        try await get("/circadian/eating-window?days=\(days)")
    }

    // MARK: - Supplement Endpoints

    func getSupplements(activeOnly: Bool = true) async throws -> [Supplement] {
        try await get("/supplements?active_only=\(activeOnly)")
    }

    func createSupplement(_ request: SupplementCreateRequest) async throws -> Supplement {
        try await post("/supplements", body: request)
    }

    func updateSupplement(id: String, update: SupplementUpdateRequest) async throws -> Supplement {
        try await patch("/supplements/\(id)", body: update)
    }

    func deleteSupplement(id: String) async throws {
        let _: SuccessResponse = try await delete("/supplements/\(id)")
    }

    func logSupplement(_ request: SupplementLogRequest) async throws -> SupplementLog {
        try await post("/supplements/log", body: request)
    }

    func getTodaySupplementLogs() async throws -> [SupplementLog] {
        try await get("/supplements/logs/today")
    }

    func getTodaySupplementSummary() async throws -> TodaySupplementSummary {
        try await get("/supplements/today")
    }

    func deleteSupplementLog(id: String) async throws {
        let _: SuccessResponse = try await delete("/supplements/log/\(id)")
    }

    func getSupplementHistory(days: Int = 7) async throws -> [SupplementLog] {
        try await get("/supplements/logs/history?days=\(days)")
    }

    // MARK: - Blood Work Endpoints

    func getBloodWorkPanels(limit: Int = 10) async throws -> [BloodWorkPanel] {
        try await get("/blood-work?limit=\(limit)")
    }

    func getBloodWorkPanel(id: String) async throws -> BloodWorkPanel {
        try await get("/blood-work/\(id)")
    }

    func createBloodWorkPanel(_ request: BloodWorkPanelCreate) async throws -> BloodWorkPanel {
        try await post("/blood-work", body: request)
    }

    func deleteBloodWorkPanel(id: String) async throws {
        let _: SuccessResponse = try await delete("/blood-work/\(id)")
    }

    func getBloodWorkSummary() async throws -> BloodWorkSummary {
        try await get("/blood-work/latest/summary")
    }

    func extractBloodWorkOCR(imageBase64: String?, imageUrl: String?, mimeType: String = "image/jpeg") async throws -> BloodWorkOCRResponse {
        let request = BloodWorkOCRRequest(imageBase64: imageBase64, imageUrl: imageUrl, mimeType: mimeType)
        return try await post("/blood-work/ocr", body: request)
    }

    func confirmBloodWorkOCR(_ request: BloodWorkConfirmOCRRequest) async throws -> BloodWorkPanel {
        try await post("/blood-work/confirm-ocr", body: request)
    }

    func analyzeBloodWorkPanel(id: String) async throws -> BloodWorkAnalysis {
        try await post("/blood-work/\(id)/analyze", body: EmptyBody())
    }

    func applyBloodWorkRecommendations(panelId: String, applySupplements: Bool, applyTargets: Bool) async throws -> ApplyRecommendationsResponse {
        let request = ApplyRecommendationsRequest(applySupplements: applySupplements, applyTargets: applyTargets)
        return try await post("/blood-work/\(panelId)/apply-recommendations", body: request)
    }

    func getBloodWorkTrend(markerKey: String, months: Int = 12) async throws -> BloodWorkTrend {
        try await get("/blood-work/trends/\(markerKey)?months=\(months)")
    }

    // MARK: - Export Endpoints

    func exportMealsCSV(days: Int = 30) async throws -> Data {
        try await downloadCSV("/export/meals?days=\(days)")
    }

    func exportWorkoutsCSV(days: Int = 30) async throws -> Data {
        try await downloadCSV("/export/workouts?days=\(days)")
    }

    func exportWaterCSV(days: Int = 30) async throws -> Data {
        try await downloadCSV("/export/water?days=\(days)")
    }

    func exportAllCSV(days: Int = 30) async throws -> Data {
        try await downloadCSV("/export/all?days=\(days)")
    }

    private func downloadCSV(_ path: String) async throws -> Data {
        guard let url = URL(string: baseURL.absoluteString + path) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = keychainService.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }

        return data
    }

    // MARK: - Generic Request Methods

    private func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(path, method: "GET", body: nil as EmptyBody?)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: "POST", body: body)
    }

    private func patch<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: "PATCH", body: body)
    }

    private func delete<T: Decodable>(_ path: String) async throws -> T {
        try await request(path, method: "DELETE", body: nil as EmptyBody?)
    }

    private func request<T: Decodable, B: Encodable>(
        _ path: String,
        method: String,
        body: B?
    ) async throws -> T {
        // Use string concatenation to avoid encoding issues with query params
        guard let url = URL(string: baseURL.absoluteString + path) else {
            print("[APIClient] Invalid URL: \(baseURL.absoluteString + path)")
            throw APIError.invalidResponse
        }

        print("[APIClient] \(method) \(path)")

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = keychainService.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body if present
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[APIClient] Invalid response type")
            throw APIError.invalidResponse
        }

        print("[APIClient] Response: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200..<300:
            do {
                let result = try decoder.decode(T.self, from: data)
                return result
            } catch {
                print("[APIClient] Decode error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[APIClient] Raw JSON: \(jsonString.prefix(500))")
                }
                throw error
            }
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 400..<500:
            let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
            print("[APIClient] Client error: \(errorResponse?.detail ?? "Unknown")")
            throw APIError.clientError(errorResponse?.detail ?? "Request failed")
        case 500..<600:
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[APIClient] Server error response: \(jsonString.prefix(500))")
            }
            throw APIError.serverError
        default:
            throw APIError.unknown(httpResponse.statusCode)
        }
    }
}

// MARK: - Request/Response Types

struct EmptyBody: Encodable {}

struct AppleSignInRequest: Encodable {
    let identityToken: String
    let authorizationCode: String?
    let userName: String?
    let email: String?
}

struct ProfileCreate: Encodable {
    let name: String
    let age: Int?
    let sex: String?
    let heightCm: Double?
    let weightKg: Double?
    let activityLevel: String?
    let goals: [String]?
    let dietStyle: String?
    let allergies: [String]?
    let injuries: [String]?
    let medicalConditions: [String]?
    let preferredIngredients: [String]?
    let equipment: [String]?
    let dailyStepsGoal: Int?
}

struct ProfileUpdate: Encodable {
    var name: String?
    var age: Int?
    var sex: String?
    var heightCm: Double?
    var weightKg: Double?
    var activityLevel: String?
    var goals: [String]?
    var dietStyle: String?
    var allergies: [String]?
    var injuries: [String]?
    var medicalConditions: [String]?
    var preferredIngredients: [String]?
    var onboardingCompleted: Bool?
    // Daily targets
    var dailyCalorieTarget: Int?
    var dailyProteinTarget: Double?
    var dailyCarbsTarget: Double?
    var dailyFatTarget: Double?
    // Micronutrient targets
    var dailySugarTargetG: Double?
    var dailyFiberTargetG: Double?
    var dailySodiumTargetMg: Double?
    var dailySaturatedFatTargetG: Double?
    var dailyStepsGoal: Int?
}

struct MealLogCreate: Encodable {
    let items: [MealItem]
    let mealType: String?
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let sugarGEst: Double?
    let fiberGEst: Double?
    let confidence: Double
    let notes: String?
}

struct WorkoutLogCreate: Encodable {
    let exercises: [Exercise]
    let workoutType: String?
    let durationMin: Int?
    let caloriesBurnedEst: Int?
    let confidence: Double
    let notes: String?
}

struct RecipeRequest: Encodable {
    let mealName: String
    let mealType: String
}

struct StepsSyncRequest: Encodable {
    let date: String  // YYYY-MM-DD format
    let steps: Int
    let source: String

    init(date: Date, steps: Int, source: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.date = formatter.string(from: date)
        self.steps = steps
        self.source = source
    }
}

struct ChatRequest: Encodable {
    let message: String
    let sessionId: String?
    let imageUrl: String?
    let imageBase64: String?
    let imageMimeType: String?

    init(message: String, sessionId: String?, imageUrl: String? = nil, imageBase64: String? = nil, imageMimeType: String? = nil) {
        self.message = message
        self.sessionId = sessionId
        self.imageUrl = imageUrl
        self.imageBase64 = imageBase64
        self.imageMimeType = imageMimeType
    }
}

struct ChatAPIResponse: Decodable {
    let message: String
    let sessionId: String
    let toolCalls: [ToolCallResult]
    let pendingConfirmation: [String: AnyCodable]?
}

struct ConfirmationResponse: Decodable {
    let success: Bool
    let message: String
    let data: [String: AnyCodable]?
}

struct MealSummary: Decodable {
    let date: String
    let mealCount: Int
    let totalCalories: Int
    let totalProteinG: Double
    let totalCarbsG: Double
    let totalFatG: Double
    let totalSugarGEst: Double?
    let totalFiberGEst: Double?
    let totalSodiumMgEst: Double?
    let totalSaturatedFatGEst: Double?
    let totalCholesterolMgEst: Double?
    let exerciseCalories: Int?
    let workoutCount: Int?
}

struct TestosteroneSummary: Decodable {
    let boostingCount: Int
    let reducingCount: Int
    let neutralCount: Int
    let overallRating: String  // "great", "good", "neutral", "poor"
}

struct WorkoutSummary: Decodable {
    let periodStart: String
    let periodEnd: String
    let workoutCount: Int
    let totalDurationMin: Int
    let totalCaloriesBurned: Int
    let byType: [String: Int]
}

struct ErrorResponse: Decodable {
    let detail: String
}

struct SuccessResponse: Decodable {
    let success: Bool
}

struct GroceryItemUpdateRequest: Encodable {
    let itemIndex: Int
    let checked: Bool
}

struct CompleteWorkoutDayRequest: Encodable {
    let workoutDayId: String
}

struct WeightLogCreateRequest: Encodable {
    let weightKg: Double
    let notes: String?
    let source: String = "manual"
}

struct WaterLogCreateRequest: Encodable {
    let amountMl: Int
    let source: String
}

struct EmptyResponse: Decodable {}

// MARK: - Exercise Search Types

struct ExerciseSearchResult: Codable, Identifiable, Equatable {
    let name: String
    let targetMuscle: String?
    let secondaryMuscles: [String]?
    let equipment: String?
    let difficulty: String?
    let gifUrl: String?
    let videoUrl: String?
    let instructions: [String]?

    // Generate id from name for Identifiable conformance
    var id: String { name }
}

// MARK: - Food Search Types

struct FoodSearchResult: Codable, Identifiable, Equatable {
    let name: String
    let calories: Int?
    let proteinG: Double?
    let carbsG: Double?
    let fatG: Double?
    let imageUrl: String?
    let imageSource: String?
    let readyInMinutes: Int?
    let servings: Int?

    // Generate id from name for Identifiable conformance
    var id: String { name }
}

// MARK: - Food Database Types

struct FoodSearchDatabaseResponse: Codable {
    let foods: [CustomFood]
    let total: Int
    let query: String
}

struct BarcodeLookupResponse: Codable {
    let found: Bool
    let food: CustomFood?
    let barcode: String
}

// MARK: - Manual Plan Creation Types

struct WorkoutPlanCreateRequest: Encodable {
    let name: String
    let description: String?
    let durationWeeks: Int
    let daysPerWeek: Int
    let goal: String?
    let difficulty: String?
    let splitType: String?
    let days: [WorkoutDayCreateRequest]
}

struct WorkoutDayCreateRequest: Encodable {
    let weekNumber: Int
    let dayNumber: Int
    let dayName: String?
    let workoutType: String?
    let exercises: [ExerciseCreateRequest]
    let isRestDay: Bool
    let notes: String?
}

struct ExerciseCreateRequest: Encodable {
    let name: String
    let sets: Int?
    let reps: Int?
    let repsRange: String?
    let weightKg: Double?
    let restSec: Int?
    let notes: String?
}

struct MealPlanCreateRequest: Encodable {
    let name: String
    let durationDays: Int
    let goal: String?
    let dailyCalorieTarget: Int?
    let dailyProteinTarget: Double?
    let dailyCarbsTarget: Double?
    let dailyFatTarget: Double?
    let days: [MealDayCreateRequest]
}

struct MealDayCreateRequest: Encodable {
    let dayNumber: Int
    let meals: [MealCreateRequest]
    let notes: String?
}

struct MealCreateRequest: Encodable {
    let type: String
    let name: String
    let description: String?
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let servings: Int?
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case notFound
    case clientError(String)
    case serverError
    case unknown(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Please sign in again"
        case .notFound:
            return "Resource not found"
        case .clientError(let message):
            return message
        case .serverError:
            return "Server error. Please try again later."
        case .unknown(let code):
            return "Unknown error (code: \(code))"
        }
    }
}
