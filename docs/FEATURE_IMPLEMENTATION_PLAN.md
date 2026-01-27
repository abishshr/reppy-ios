# Reppy Feature Implementation Plan

This document outlines the implementation plan for features to achieve parity with MyFitnessPal.

---

## Executive Summary

| Priority | Features | Status |
|----------|----------|--------|
| **High** | Barcode Scanner, Food Database | Not Started |
| **Easy Win** | Streak Counter, Water Tracking | Water exists (needs UI), Streak not started |
| **Medium** | Recipe Database, Social Community, Challenges, Fasting Timer, Food Group Insights, Device Integrations, Friends, Progress Photos, Nutrition Reports | Not Started |
| **Low** | Voice Logging | Already has speech-to-text |

---

## Phase 1: Easy Wins (Foundation)

### 1.1 Streak Counter
**Status**: Not implemented
**Effort**: Small
**Dependencies**: None

#### Backend Changes

**New Fields in `UserProfile` model** (`backend/app/infrastructure/database/models.py`):
```python
current_streak = Column(Integer, default=0)
longest_streak = Column(Integer, default=0)
last_activity_date = Column(Date, nullable=True)
```

**New Endpoint** (`backend/app/api/v1/progress.py`):
- `GET /progress/streak` - Return current streak, longest streak, last activity date

**Streak Logic**:
- Increment streak when user logs a meal OR workout on a new day
- Reset to 1 if gap > 1 day
- Update `longest_streak` if `current_streak` exceeds it
- Hook into `MealLog` and `WorkoutLog` creation

**Database Migration**:
```bash
alembic revision --autogenerate -m "add_streak_fields_to_user_profile"
```

#### iOS Changes
- Add streak badge component to dashboard
- Display flame icon with streak count
- Show celebration animation on streak milestones (7, 30, 100 days)

---

### 1.2 Water Tracking Enhancement
**Status**: Backend exists, needs iOS UI and daily goal tracking
**Effort**: Small
**Dependencies**: None

#### Current State
- `POST /water` - Log water intake ✅
- `GET /water/summary/today` - Get today's total ✅
- `water_goal_ml` in `UserProfile` ✅
- `WaterLog` model exists ✅

#### Backend Enhancements

**New Endpoints** (`backend/app/api/v1/water.py`):
- `GET /water/history?days=7` - Water history for charts
- `DELETE /water/{id}` - Delete water log entry

**Enhanced Response** for `GET /water/summary/today`:
```python
{
    "total_ml": 1500,
    "goal_ml": 2500,
    "percentage": 60,
    "logs": [
        {"id": "...", "amount_ml": 250, "logged_at": "..."},
        ...
    ]
}
```

#### iOS Changes
- Water tracking widget on dashboard (circular progress)
- Quick-add buttons: 250ml, 500ml, custom
- Animated water fill effect
- Reminder notification integration (local notifications)

---

## Phase 2: High Priority Features

### 2.1 Food Database Integration
**Status**: Not implemented (AI estimates only)
**Effort**: Large
**Dependencies**: External API (Open Food Facts / USDA / Nutritionix)

#### Recommended API Options
1. **Open Food Facts** (Free, open-source, good international coverage)
2. **USDA FoodData Central** (Free, US government, very accurate)
3. **Nutritionix** (Paid, best coverage, natural language parsing)

**Recommended**: Start with Open Food Facts (free, extensive) + USDA as fallback

#### Backend Changes

**New External Client** (`backend/app/infrastructure/external/food_database.py`):
```python
class FoodDatabaseClient:
    async def search_foods(query: str, limit: int = 20) -> List[FoodItem]
    async def get_food_by_barcode(barcode: str) -> Optional[FoodItem]
    async def get_food_details(food_id: str) -> FoodItem
```

**New Model** (`backend/app/infrastructure/database/models.py`):
```python
class FoodItem(Base):
    id = Column(UUID, primary_key=True)
    external_id = Column(String, nullable=True)  # Open Food Facts ID
    barcode = Column(String, nullable=True, index=True)
    name = Column(String, nullable=False)
    brand = Column(String, nullable=True)
    serving_size = Column(String)
    serving_size_g = Column(Float)
    calories_per_serving = Column(Float)
    protein_g = Column(Float)
    carbs_g = Column(Float)
    fat_g = Column(Float)
    fiber_g = Column(Float, nullable=True)
    sodium_mg = Column(Float, nullable=True)
    sugar_g = Column(Float, nullable=True)
    image_url = Column(String, nullable=True)
    source = Column(String)  # 'open_food_facts', 'usda', 'user_created'
    is_verified = Column(Boolean, default=False)
    created_by_user_id = Column(UUID, ForeignKey("users.id"), nullable=True)
```

**New Endpoints** (`backend/app/api/v1/foods.py`):
- `GET /foods/search?q=chicken&limit=20` - Search foods
- `GET /foods/barcode/{barcode}` - Lookup by barcode
- `GET /foods/{id}` - Get food details
- `POST /foods` - User-created food (for foods not in DB)
- `GET /foods/recent` - User's recently logged foods
- `GET /foods/frequent` - User's most-logged foods

**Enhance MealLog** to reference FoodItem:
```python
# In MealLog.items JSON, add optional food_id reference
items = [
    {
        "name": "Chicken Breast",
        "food_id": "uuid-here",  # NEW: Reference to FoodItem
        "quantity": 1,
        "unit": "serving",
        "calories": 165,
        ...
    }
]
```

#### iOS Changes
- Food search screen with autocomplete
- Recent foods quick-add
- Frequent foods suggestions
- Food detail view with full nutrition breakdown
- Serving size selector (1 serving, 100g, custom)

---

### 2.2 Barcode Scanner
**Status**: Not implemented
**Effort**: Medium
**Dependencies**: Food Database (2.1)

#### iOS Implementation

**Required Frameworks**:
- `AVFoundation` for camera access
- `Vision` for barcode detection (or use AVCaptureMetadataOutput)

**New Views**:
```swift
// BarcodeScannerView.swift
struct BarcodeScannerView: View {
    @StateObject var viewModel: BarcodeScannerViewModel
    // Camera preview
    // Barcode overlay frame
    // Flash toggle
    // Manual entry fallback
}

// BarcodeScannerViewModel.swift
class BarcodeScannerViewModel: ObservableObject {
    func processBarcode(_ code: String) async
    func lookupFood(barcode: String) async -> FoodItem?
}
```

**Flow**:
1. User taps barcode icon in meal logging
2. Camera opens with scanning frame
3. On detection, vibrate + lookup via `GET /foods/barcode/{code}`
4. If found → show food with serving selector → add to meal
5. If not found → offer to create custom food OR use AI estimation

#### Backend Changes
- `GET /foods/barcode/{barcode}` endpoint (from 2.1)
- Cache frequently scanned barcodes in Redis

---

## Phase 3: Medium Priority Features

### 3.1 Recipe Database
**Status**: Not implemented
**Effort**: Medium
**Dependencies**: Food Database (2.1)

#### Backend Changes

**New Model**:
```python
class Recipe(Base):
    id = Column(UUID, primary_key=True)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=True)  # Null = system recipe
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    image_url = Column(String, nullable=True)
    prep_time_min = Column(Integer, nullable=True)
    cook_time_min = Column(Integer, nullable=True)
    servings = Column(Integer, default=1)
    ingredients = Column(JSON)  # List of {food_id, name, quantity, unit}
    instructions = Column(JSON)  # List of steps

    # Calculated nutrition per serving
    calories = Column(Float)
    protein_g = Column(Float)
    carbs_g = Column(Float)
    fat_g = Column(Float)

    # Categorization
    tags = Column(JSON)  # ['high-protein', 'vegetarian', 'quick', etc.]
    cuisine = Column(String, nullable=True)
    meal_types = Column(JSON)  # ['breakfast', 'lunch', 'dinner', 'snack']

    source = Column(String)  # 'spoonacular', 'user_created', 'ai_generated'
    external_id = Column(String, nullable=True)
    is_public = Column(Boolean, default=False)

    created_at = Column(DateTime, server_default=func.now())
```

**New Endpoints** (`backend/app/api/v1/recipes.py`):
- `GET /recipes?q=&tags=&cuisine=&max_calories=` - Search recipes
- `GET /recipes/{id}` - Recipe details
- `POST /recipes` - Create user recipe
- `PUT /recipes/{id}` - Update user recipe
- `DELETE /recipes/{id}` - Delete user recipe
- `GET /recipes/my` - User's saved recipes
- `POST /recipes/{id}/log` - Log recipe as meal

**Spoonacular Integration Enhancement**:
- Fetch popular recipes on app launch
- Cache in database for fast search
- Import nutrition data per serving

#### iOS Changes
- Recipe browser with filters
- Recipe detail view with:
  - Ingredients list (with shopping list add)
  - Step-by-step instructions
  - Nutrition breakdown
  - "Log as Meal" button with serving selector
- Recipe creation form
- Recipe import from URL (future enhancement)

---

### 3.2 Intermittent Fasting Timer
**Status**: Not implemented
**Effort**: Medium
**Dependencies**: None

#### Backend Changes

**New Model**:
```python
class FastingSession(Base):
    id = Column(UUID, primary_key=True)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False)

    protocol = Column(String)  # '16:8', '18:6', '20:4', '5:2', 'custom'
    fast_hours = Column(Integer)  # Duration of fast in hours
    eat_hours = Column(Integer)  # Eating window in hours

    started_at = Column(DateTime, nullable=True)
    target_end_at = Column(DateTime, nullable=True)
    actual_end_at = Column(DateTime, nullable=True)

    status = Column(String)  # 'active', 'completed', 'broken'

    created_at = Column(DateTime, server_default=func.now())
```

**New Fields in `UserProfile`**:
```python
fasting_enabled = Column(Boolean, default=False)
fasting_protocol = Column(String, nullable=True)  # Default protocol
fasting_start_time = Column(Time, nullable=True)  # Usual start time
```

**New Endpoints** (`backend/app/api/v1/fasting.py`):
- `POST /fasting/start` - Start fasting session
- `POST /fasting/end` - End fasting session (complete or break)
- `GET /fasting/current` - Get current fasting status
- `GET /fasting/history?days=30` - Fasting history
- `GET /fasting/stats` - Average fast duration, completion rate
- `PATCH /fasting/settings` - Update fasting preferences

#### iOS Changes
- Fasting widget on dashboard:
  - Circular timer showing time remaining/elapsed
  - Quick start/stop buttons
  - Protocol selector
- Fasting history view
- Fasting stats (average duration, streak, completion %)
- Notification when fast complete
- Optional: Lock meal logging during fast (with override)

---

### 3.3 Food Group Insights / Nutrition Reports
**Status**: Not implemented
**Effort**: Medium
**Dependencies**: Food Database (2.1) for best results

#### Backend Changes

**New Analytics Logic**:
```python
# In new file: backend/app/services/analytics.py
class NutritionAnalytics:
    async def get_weekly_report(user_id: UUID, week_start: date) -> WeeklyReport
    async def get_monthly_report(user_id: UUID, month: int, year: int) -> MonthlyReport
    async def get_food_group_breakdown(user_id: UUID, days: int = 7) -> FoodGroupBreakdown
    async def get_macro_trends(user_id: UUID, days: int = 30) -> MacroTrends
```

**New Endpoints** (`backend/app/api/v1/insights.py`):
- `GET /insights/weekly` - Weekly nutrition report
- `GET /insights/monthly` - Monthly nutrition report
- `GET /insights/food-groups?days=7` - Food group breakdown
- `GET /insights/trends?metric=calories&days=30` - Trend data for charts
- `GET /insights/recommendations` - AI-powered recommendations based on patterns

**Report Data Structure**:
```python
WeeklyReport = {
    "period": {"start": "2025-01-01", "end": "2025-01-07"},
    "summary": {
        "avg_calories": 1850,
        "avg_protein": 120,
        "avg_carbs": 180,
        "avg_fat": 65,
        "goal_adherence_percent": 82
    },
    "food_groups": {
        "protein": {"servings": 25, "recommended": 28, "pct": 89},
        "vegetables": {"servings": 14, "recommended": 21, "pct": 67},
        "fruits": {"servings": 10, "recommended": 14, "pct": 71},
        "grains": {"servings": 21, "recommended": 24, "pct": 88},
        "dairy": {"servings": 7, "recommended": 14, "pct": 50}
    },
    "highlights": [
        {"type": "achievement", "text": "Hit protein goal 6/7 days!"},
        {"type": "improvement", "text": "Consider adding more vegetables"}
    ],
    "daily_breakdown": [...]
}
```

#### iOS Changes
- Weekly/Monthly report views
- Food group pie chart
- Macro trend line charts
- Nutrition calendar (green/yellow/red days)
- Push notification: "Your weekly report is ready!"

---

### 3.4 Progress Photos
**Status**: Not implemented
**Effort**: Medium
**Dependencies**: Image storage (Supabase client exists)

#### Backend Changes

**New Model**:
```python
class ProgressPhoto(Base):
    id = Column(UUID, primary_key=True)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False)

    image_url = Column(String, nullable=False)
    thumbnail_url = Column(String, nullable=True)

    photo_type = Column(String)  # 'front', 'side', 'back'
    taken_at = Column(DateTime, nullable=False)

    weight_kg = Column(Float, nullable=True)  # Weight at time of photo
    notes = Column(Text, nullable=True)

    is_private = Column(Boolean, default=True)

    created_at = Column(DateTime, server_default=func.now())
```

**New Endpoints** (`backend/app/api/v1/progress_photos.py`):
- `POST /progress/photos` - Upload progress photo
- `GET /progress/photos` - List photos (with filters)
- `GET /progress/photos/{id}` - Get photo details
- `DELETE /progress/photos/{id}` - Delete photo
- `GET /progress/photos/compare?photo1_id=&photo2_id=` - Comparison view data

**Image Storage**:
- Use existing Supabase client for storage
- Generate thumbnails on upload
- Store original + thumbnail URLs

#### iOS Changes
- Camera capture optimized for progress photos:
  - Grid overlay for consistent positioning
  - Timer for hands-free capture
  - Mirror toggle
- Photo gallery with timeline view
- Side-by-side comparison view
- Before/after slider comparison
- Link photos to weigh-ins

---

### 3.5 Device Integrations (Beyond HealthKit)
**Status**: HealthKit only
**Effort**: Large
**Dependencies**: External OAuth integrations

#### Priority Order
1. **Google Fit** (Android parity)
2. **Fitbit** (popular, owned by Google)
3. **Garmin** (fitness-focused users)
4. **Samsung Health** (Android users)

#### Backend Changes

**New OAuth Flow Support**:
```python
# backend/app/api/v1/integrations.py

class IntegrationProvider(str, Enum):
    GOOGLE_FIT = "google_fit"
    FITBIT = "fitbit"
    GARMIN = "garmin"
    SAMSUNG_HEALTH = "samsung_health"

# New endpoints
- `GET /integrations` - List available integrations + user's connection status
- `POST /integrations/{provider}/connect` - Start OAuth flow
- `GET /integrations/{provider}/callback` - OAuth callback
- `DELETE /integrations/{provider}` - Disconnect
- `POST /integrations/{provider}/sync` - Manual sync trigger
```

**New Model**:
```python
class IntegrationConnection(Base):
    id = Column(UUID, primary_key=True)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False)
    provider = Column(String, nullable=False)  # 'google_fit', 'fitbit', etc.
    access_token = Column(String, nullable=False)  # Encrypted
    refresh_token = Column(String, nullable=True)  # Encrypted
    token_expires_at = Column(DateTime, nullable=True)
    scopes = Column(JSON)
    last_sync_at = Column(DateTime, nullable=True)
    sync_status = Column(String)  # 'active', 'error', 'expired'
    created_at = Column(DateTime, server_default=func.now())
```

**Sync Worker** (Background job):
- Periodic sync of data from connected services
- Import: steps, workouts, sleep, heart rate
- Map external data types to Reppy models

#### iOS Changes
- Integrations settings screen
- Connection status indicators
- Manual sync button
- Data source priority selector

---

### 3.6 Social Community / Forums
**Status**: Not implemented
**Effort**: Large
**Dependencies**: User profiles, moderation system

#### Backend Changes

**New Models**:
```python
class CommunityPost(Base):
    id = Column(UUID, primary_key=True)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False)

    post_type = Column(String)  # 'discussion', 'progress', 'recipe', 'question'
    title = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    image_urls = Column(JSON, nullable=True)

    category_id = Column(UUID, ForeignKey("community_categories.id"))
    tags = Column(JSON, nullable=True)

    likes_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)

    is_pinned = Column(Boolean, default=False)
    is_deleted = Column(Boolean, default=False)

    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())

class CommunityComment(Base):
    id = Column(UUID, primary_key=True)
    post_id = Column(UUID, ForeignKey("community_posts.id"), nullable=False)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False)
    parent_comment_id = Column(UUID, ForeignKey("community_comments.id"), nullable=True)

    content = Column(Text, nullable=False)
    likes_count = Column(Integer, default=0)

    is_deleted = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())

class PostLike(Base):
    id = Column(UUID, primary_key=True)
    post_id = Column(UUID, ForeignKey("community_posts.id"), nullable=False)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    __table_args__ = (UniqueConstraint('post_id', 'user_id'),)

class CommunityCategory(Base):
    id = Column(UUID, primary_key=True)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    icon = Column(String, nullable=True)
    sort_order = Column(Integer, default=0)
```

**New Endpoints** (`backend/app/api/v1/community.py`):
- `GET /community/feed?category=&sort=&page=` - Paginated feed
- `POST /community/posts` - Create post
- `GET /community/posts/{id}` - Get post with comments
- `PUT /community/posts/{id}` - Update post
- `DELETE /community/posts/{id}` - Delete post
- `POST /community/posts/{id}/like` - Like/unlike post
- `POST /community/posts/{id}/comments` - Add comment
- `DELETE /community/comments/{id}` - Delete comment
- `GET /community/categories` - List categories
- `POST /community/posts/{id}/report` - Report post

#### iOS Changes
- Community tab in app
- Feed view with infinite scroll
- Post detail view with comments
- Create post screen
- Category browser
- Search within community
- Report/block functionality

---

### 3.7 Friends / Following
**Status**: Not implemented
**Effort**: Medium
**Dependencies**: User discovery mechanism

#### Backend Changes

**New Models**:
```python
class Friendship(Base):
    id = Column(UUID, primary_key=True)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False)
    friend_id = Column(UUID, ForeignKey("users.id"), nullable=False)

    status = Column(String)  # 'pending', 'accepted', 'blocked'

    created_at = Column(DateTime, server_default=func.now())
    accepted_at = Column(DateTime, nullable=True)

    __table_args__ = (UniqueConstraint('user_id', 'friend_id'),)

class ActivityFeedItem(Base):
    id = Column(UUID, primary_key=True)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False)

    activity_type = Column(String)  # 'workout_completed', 'streak_milestone', 'weight_goal', etc.
    content = Column(JSON)

    is_visible_to_friends = Column(Boolean, default=True)

    created_at = Column(DateTime, server_default=func.now())
```

**Enhance UserProfile**:
```python
# Add social fields
display_name = Column(String, nullable=True)
bio = Column(Text, nullable=True)
avatar_url = Column(String, nullable=True)
is_profile_public = Column(Boolean, default=False)
share_workouts = Column(Boolean, default=True)
share_meals = Column(Boolean, default=False)  # More private
share_weight = Column(Boolean, default=False)  # Very private
```

**New Endpoints** (`backend/app/api/v1/friends.py`):
- `GET /friends` - List friends
- `GET /friends/requests` - Pending friend requests
- `POST /friends/request` - Send friend request
- `POST /friends/accept/{user_id}` - Accept request
- `POST /friends/reject/{user_id}` - Reject request
- `DELETE /friends/{user_id}` - Remove friend
- `POST /friends/block/{user_id}` - Block user
- `GET /friends/activity` - Friends' activity feed
- `GET /users/search?q=` - Search users by name
- `GET /users/{id}/profile` - View public profile

#### iOS Changes
- Friends tab or section
- Friend activity feed
- Friend profile view
- Friend request management
- Privacy settings for sharing
- Invite friends (share link)

---

### 3.8 Challenges / Competitions
**Status**: Not implemented
**Effort**: Medium
**Dependencies**: Friends (3.7) for friend challenges

#### Backend Changes

**New Models**:
```python
class Challenge(Base):
    id = Column(UUID, primary_key=True)
    created_by_user_id = Column(UUID, ForeignKey("users.id"), nullable=True)  # Null = system challenge

    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    image_url = Column(String, nullable=True)

    challenge_type = Column(String)  # 'steps', 'workouts', 'streak', 'calories', 'water'
    goal_value = Column(Float)  # e.g., 70000 steps
    goal_unit = Column(String)  # 'steps', 'workouts', 'days', 'ml'

    duration_days = Column(Integer)
    start_date = Column(Date, nullable=True)  # Null = join anytime
    end_date = Column(Date, nullable=True)

    visibility = Column(String)  # 'public', 'friends_only', 'private'
    max_participants = Column(Integer, nullable=True)

    is_official = Column(Boolean, default=False)  # System-created challenges

    created_at = Column(DateTime, server_default=func.now())

class ChallengeParticipant(Base):
    id = Column(UUID, primary_key=True)
    challenge_id = Column(UUID, ForeignKey("challenges.id"), nullable=False)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False)

    current_progress = Column(Float, default=0)
    completed = Column(Boolean, default=False)
    completed_at = Column(DateTime, nullable=True)

    joined_at = Column(DateTime, server_default=func.now())

    __table_args__ = (UniqueConstraint('challenge_id', 'user_id'),)
```

**New Endpoints** (`backend/app/api/v1/challenges.py`):
- `GET /challenges` - List available challenges
- `GET /challenges/my` - User's active challenges
- `GET /challenges/{id}` - Challenge details with leaderboard
- `POST /challenges` - Create challenge
- `POST /challenges/{id}/join` - Join challenge
- `POST /challenges/{id}/leave` - Leave challenge
- `GET /challenges/{id}/leaderboard` - Full leaderboard

**Background Worker**:
- Update participant progress based on logged activities
- Mark challenges as complete
- Send notifications for milestones

#### iOS Changes
- Challenges tab
- Challenge browser (filter by type, duration)
- Challenge detail with leaderboard
- Create challenge flow
- Invite friends to challenge
- Progress tracking widget
- Celebration animations for completion

---

## Phase 4: Low Priority

### 4.1 Voice Logging Enhancement
**Status**: Has speech-to-text, similar to competitor
**Effort**: Small (already mostly there)

The app already has:
- Speech-to-text via Pipecat for voice input
- Natural language processing via Gemini

**Minor Enhancements**:
- Add dedicated "Voice Log" button for quick access
- Improve voice parsing accuracy with few-shot examples
- Add voice confirmation: "I heard chicken salad, 400 calories. Is that correct?"

---

## Implementation Order (Recommended)

### Sprint 1-2: Foundation
1. ✅ Streak Counter (easy win, high visibility)
2. ✅ Water Tracking UI (backend exists, needs iOS)

### Sprint 3-5: Core Nutrition
3. Food Database Integration (Open Food Facts + USDA)
4. Barcode Scanner (depends on #3)
5. Recipe Database (depends on #3)

### Sprint 6-7: Insights & Tracking
6. Nutrition Reports / Food Group Insights
7. Progress Photos

### Sprint 8-9: Lifestyle Features
8. Intermittent Fasting Timer
9. Voice Logging Enhancement

### Sprint 10-12: Social Features
10. Friends / Following System
11. Challenges / Competitions
12. Community Forums (largest effort, do last)

### Sprint 13+: Integrations
13. Google Fit integration
14. Fitbit integration
15. Other device integrations

---

## Technical Considerations

### Database Migrations Strategy
- Each feature gets its own migration file
- Use `alembic revision --autogenerate` for initial migration
- Always review auto-generated migrations before applying
- Test migrations on staging database first

### API Versioning
- All new endpoints under `/api/v1/`
- If breaking changes needed, create `/api/v2/` namespace

### Rate Limiting
- Add rate limiting for:
  - Barcode lookups (external API)
  - Food search (external API)
  - Community posts (spam prevention)

### Caching Strategy
- Redis cache for:
  - Food database search results (TTL: 24h)
  - Barcode lookups (TTL: 7d)
  - Leaderboard data (TTL: 5min)
  - Weekly reports (TTL: 1h)

### Image Storage
- Use Supabase Storage (already integrated)
- Generate thumbnails for:
  - Progress photos
  - Community post images
  - Recipe images

### Push Notifications (New System Needed)
- Implement for:
  - Streak reminders
  - Fasting timer completion
  - Challenge milestones
  - Friend requests
  - Weekly reports ready

**Options**:
- Apple Push Notification service (APNs) directly
- Firebase Cloud Messaging (cross-platform ready)
- OneSignal (easier setup)

---

## External Services Required

| Feature | Service | Cost |
|---------|---------|------|
| Food Database | Open Food Facts | Free |
| Food Database Backup | USDA FoodData Central | Free |
| Barcode Data | Open Food Facts | Free |
| Push Notifications | APNs / FCM | Free tier available |
| Image Storage | Supabase | Existing |
| Device Integrations | Google Fit API | Free |
| Device Integrations | Fitbit API | Free |
| Device Integrations | Garmin API | Free (with approval) |

---

## Metrics to Track

- **Streak Counter**: % users with 7+ day streak
- **Water Tracking**: Daily active users for water logging
- **Barcode Scanner**: Scans per user, success rate
- **Food Database**: Search success rate, user-created foods
- **Recipes**: Recipes logged as meals, user-created recipes
- **Fasting**: Completion rate, average fast duration
- **Progress Photos**: Photos uploaded per user
- **Social**: DAU for community, posts per day, engagement rate
- **Challenges**: Join rate, completion rate, retention impact
- **Integrations**: Connection rate, sync success rate

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Food database accuracy | Show confidence scores, allow user corrections |
| Barcode not found | Fallback to AI estimation, user-created foods |
| API rate limits | Implement caching, request queuing |
| Community moderation | Automated filters + report system |
| Privacy concerns (photos) | End-to-end encryption option, clear privacy controls |
| Integration token expiry | Proactive refresh, graceful degradation |

---

## Success Criteria

### Phase 1 Complete When:
- [ ] Streak counter visible on dashboard
- [ ] Water logging with goal tracking live
- [ ] Users can see streak/water widgets

### Phase 2 Complete When:
- [ ] Food search returns accurate results
- [ ] Barcode scanner works for common products
- [ ] 80%+ scan success rate for US products

### Phase 3 Complete When:
- [ ] All medium priority features deployed
- [ ] 70%+ user adoption of at least 2 new features
- [ ] Social features have active engagement

### Full Parity When:
- [ ] Feature parity with MyFitnessPal free tier
- [ ] Competitive advantage through AI coaching
- [ ] Strong user retention metrics
