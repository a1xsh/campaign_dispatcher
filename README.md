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
