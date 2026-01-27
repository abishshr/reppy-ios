# Reppy - AI Fitness Coaching App

Reppy is an iOS fitness app with AI-powered coaching for meal and workout logging, powered by Google Gemini and built with a FastAPI backend.

## Project Structure

```
Reppy/
├── backend/          # FastAPI Python backend
│   ├── app/          # Application code
│   ├── tests/        # Test suite
│   └── docker-compose.yml
├── ios/              # iOS SwiftUI app
│   └── Reppy/        # Main iOS app code
└── README.md
```

## Quick Start

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys:
   # - GEMINI_API_KEY (required)
   # - USDA_API_KEY (optional, for nutrition lookup)
   ```

3. **Start services with Docker:**
   ```bash
   docker-compose up -d
   ```

4. **Run migrations (if needed):**
   ```bash
   docker-compose exec api alembic upgrade head
   ```

5. **API is now running at:** `http://localhost:8000`
   - Docs: `http://localhost:8000/docs`
   - Health: `http://localhost:8000/health`

### iOS Setup

1. **Open in Xcode:**
   - Create a new iOS App project named "Reppy" in `ios/Reppy`
   - Copy all Swift files from `ios/Reppy/` into the project
   - Or use the Swift Package Manager approach below

2. **Configure signing:**
   - Set your Team ID
   - Set bundle identifier to `com.reppy.app` (or your own)
   - Enable Sign in with Apple capability
   - Enable HealthKit capability

3. **Run on simulator or device**

## Phase 1 Features (Current)

- [x] User authentication (Apple Sign-In)
- [x] Profile setup and onboarding
- [x] Voice/text chat with AI coach
- [x] Meal logging via voice or text
- [x] Workout logging via voice or text
- [x] Apple Health steps integration
- [x] Daily dashboard with macros and steps
- [x] MCP orchestration with tool calling

## API Endpoints

### Authentication
- `POST /api/v1/auth/apple` - Sign in with Apple

### Profile
- `GET /api/v1/profile/me` - Get current profile
- `POST /api/v1/profile/me` - Create profile
- `PATCH /api/v1/profile/me` - Update profile

### Meals
- `GET /api/v1/meals` - List meals
- `POST /api/v1/meals` - Log meal
- `GET /api/v1/meals/summary/today` - Today's summary

### Workouts
- `GET /api/v1/workouts` - List workouts
- `POST /api/v1/workouts` - Log workout
- `GET /api/v1/workouts/summary/week` - Week summary

### Activity
- `POST /api/v1/activity/steps/sync` - Sync steps
- `GET /api/v1/activity/summary` - Activity summary

### Chat
- `POST /api/v1/chat` - Send message to AI coach
- `POST /api/v1/chat/confirm` - Confirm suggestion

## Architecture

### Backend (MCP Pattern)
```
User Message → Context Assembly (RAG) → Gemini + Tools → Tool Execution → Response
```

- **MCP Orchestrator**: Coordinates AI model with tool calls
- **Context Assembler**: Retrieves relevant user data (profile, recent logs, steps)
- **Tools**: log_meal_suggestion, confirm_log_meal, log_workout_suggestion, etc.
- **Memory**: Redis for session state, Postgres for persistent data

### iOS (Clean Architecture)
```
Presentation (Views) → Domain (UseCases) → Data (Repositories) → Network (API)
```

- **SwiftUI**: Modern declarative UI
- **MVVM**: ViewModels handle presentation logic
- **Dependency Injection**: Services and repositories injected via container

## Environment Variables

### Backend (.env)
```
DATABASE_URL=postgresql+asyncpg://reppy:password@localhost:5432/reppy
REDIS_URL=redis://localhost:6379
GEMINI_API_KEY=your_api_key
GEMINI_MODEL=gemini-1.5-pro
JWT_SECRET=your_secret
```

## Development

### Backend
```bash
# Run locally (without Docker)
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload

# Run tests
pytest

# Format code
ruff format .
ruff check . --fix
```

### iOS
```bash
# Open in Xcode
open ios/Reppy.xcodeproj
```

## Future Phases

- **Phase 2**: Meal photo analysis, menu recommendations
- **Phase 3**: Weekly meal/workout plans
- **Phase 4**: Body video evaluation
- **Phase 5**: Real-time voice coaching (Pipecat)
- **Phase 6**: Live video trainer with rep counting
- **Phase 7**: Wearable integrations
- **Phase 8**: Biomarker tracking

## License

Private - All rights reserved.
