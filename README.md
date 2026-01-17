# Campaign Dispatcher

A Rails application for automating customer feedback collection campaigns with real-time progress tracking.

## Prerequisites

- Ruby 3.2.2 or higher
- PostgreSQL
- Redis (required for Sidekiq)

## Setup

### Option 1: Full Docker Setup (Recommended)

Runs the entire stack в Docker (PostgreSQL, Redis, Rails, Sidekiq):

```bash
# Start all services
docker-compose up

# Or in the background
docker-compose up -d

# View logs
docker-compose logs -f web

# Stop services
docker-compose down
```

The application will be available on http://localhost:3000

### Option 2: Docker for Db, localy for Rails

1. **Start PostgreSQL and Redis:**
   ```bash
   docker-compose up -d postgres redis
   ```

2. **Install dependencies:**
   ```bash
   bundle install
   ```

3. **Setup database:**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

4. **Run the application:**
   ```bash
   bin/dev
   ```

### Option 2: Manual Setup

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Setup PostgreSQL and Redis:**
   
   **PostgreSQL:**
   - Install PostgreSQL locally or use Docker: `docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15-alpine`
   
   **Redis:**
   - **On macOS (using Homebrew):**
     ```bash
     brew install redis
     brew services start redis
     ```
   - **On Linux:**
     ```bash
     redis-server
     ```
   - **Or using Docker:**
     ```bash
     docker run -d -p 6379:6379 redis:latest
     ```

3. **Setup database:**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

4. **Run the application:**
   ```bash
   bin/dev
   ```

This will start:
- Rails server (http://localhost:3000)
- Tailwind CSS watcher
- Sidekiq worker

### Docker Commands

```bash
# Start all services
docker-compose up

# Start in the background
docker-compose up -d

# Stop all services
docker-compose down

# Stop and clean database
docker-compose down -v

# Rebuild images
docker-compose build

# View logs
docker-compose logs -f web
docker-compose logs -f sidekiq

# Run a command in a container
docker-compose exec web bin/rails console
docker-compose exec web bin/rails db:migrate
```

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models
bundle exec rspec spec/requests
bundle exec rspec spec/jobs
bundle exec rspec spec/system
```

## Features

- Create campaigns with multiple recipients
- Background job processing with Sidekiq
- Real-time UI updates using Hotwire (Turbo Streams & Turbo Frames)
- Track campaign progress without page refresh

## Tech Stack

- Ruby on Rails 7.2.3
- PostgreSQL
- Hotwire (Turbo & Stimulus)
- Sidekiq + Redis
- Tailwind CSS
- RSpec + Capybara

## Architectural Decisions

### Real-time Updates with Hotwire
- **Turbo Streams**: Used for broadcasting individual recipient status updates and campaign progress changes. Each recipient update triggers a broadcast via `after_commit` callback to ensure data consistency.
- **Turbo Frames**: Used for updating specific UI components (campaign status, start button, progress bar) without full page reloads.
- **Action Cable**: Configured with Redis adapter in development/production for reliable WebSocket connections. Uses async adapter in tests to avoid Redis dependency.

### Background Processing
- **Sidekiq**: Handles campaign dispatch jobs asynchronously. Each recipient is processed with a simulated delay (1-3 seconds) to demonstrate real-world scenarios.
- **Job Design**: `DispatchCampaignJob` processes recipients sequentially to maintain order and allow for proper error handling per recipient.

### Data Model
- **Campaigns**: Have status enum (pending, processing, completed) and track overall progress.
- **Recipients**: Belong to campaigns with status enum (queued, sent, failed). Default statuses are set via `after_initialize` callbacks.
- **Progress Calculation**: Uses direct SQL queries in `Campaign#sent_count` to bypass ActiveRecord association caching and ensure fresh data for real-time updates.

### Error Handling
- Recipients that fail during processing are marked as `failed` status, allowing campaigns to complete even if some recipients fail.
- Campaign status transitions: `pending` → `processing` → `completed`.

### Testing Strategy
- **Request Specs**: Test controller actions and parameter handling.
- **Unit Specs**: Test model validations, associations, and job logic.
- **System Specs**: Test end-to-end user flows with Capybara and headless Chrome. Uses inline job adapter for synchronous execution in tests.

## Future Improvements

If given 40 hours instead of 6, here's what I would add or improve:

### 1. **Enhanced Error Handling & Retry Logic**
- Implement exponential backoff retry mechanism for failed recipients
- Add dead letter queue for permanently failed recipients
- Email/SMS notification system for campaign failures
- Detailed error logging and error tracking (e.g., Sentry)

### 2. **Real Email/SMS Integration**
- Integrate with actual email providers (SendGrid, Mailgun) and SMS providers (Twilio)
- Add email/SMS templates with variable substitution
- Implement rate limiting to respect provider limits
- Add delivery status tracking and webhook handling

### 3. **Advanced Campaign Features**
- Scheduled campaigns (start at specific date/time)
- Campaign templates for reusability
- Bulk recipient import via CSV/Excel
- Campaign analytics dashboard with charts and metrics
- A/B testing capabilities for different message variants

### 4. **User Authentication & Authorization**
- Add Devise or similar for user authentication
- Multi-tenant support (organizations/teams)
- Role-based access control (admin, manager, user)
- Audit logs for all campaign actions

### 5. **Performance & Scalability**
- Implement database indexing optimization
- Add caching layer (Redis) for frequently accessed data
- Background job prioritization and queue management
- Horizontal scaling support for Sidekiq workers
- Database connection pooling optimization

### 6. **UI/UX Enhancements**
- Responsive design improvements for mobile devices
- Dark mode support
- Advanced filtering and search for campaigns/recipients
- Export functionality (CSV, PDF reports)
- Drag-and-drop recipient management
- Real-time notifications (browser notifications)

### 7. **Testing & Quality**
- Increase test coverage to 95%+
- Add performance/load testing
- Integration tests for external API providers
- E2E tests with Playwright for better reliability
- Visual regression testing

### 8. **Monitoring & Observability**
- Application performance monitoring (APM)
- Sidekiq dashboard for job monitoring
- Health check endpoints
- Metrics collection (Prometheus/Grafana)
- Structured logging with correlation IDs

### 9. **API Development**
- RESTful API for campaign management
- GraphQL API option
- API authentication (JWT tokens)
- API rate limiting
- Webhook support for external integrations

### 10. **DevOps & Deployment**
- CI/CD pipeline with GitHub Actions
- Docker optimization (multi-stage builds, smaller images)
- Kubernetes deployment configurations
- Environment-specific configurations
- Database migration strategies for zero-downtime deployments
