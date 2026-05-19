# Feature-Scoped Go Backend Architecture Guide

This document defines a clean, modular, and highly reusable Go backend architecture pattern using **Echo** and **SQLC**. It enforces strict separation of concerns, decoupling via interfaces, and feature-scoped subfolders.

---

## 1. Directory Structure

The backend is structured by **feature sets** rather than raw technical layers (like controllers, models, services). All domain-specific logic resides under `/internal/<feature>`.

```
/backend
  ├── /cmd
  │    └── /api
  │         └── main.go       # Boots db, instantiates features, registers subrouters
  ├── /db
  │    ├── schema.sql         # DB migrations/schema
  │    └── queries.sql        # raw SQL queries for SQLC
  └── /internal
       ├── /db                # Auto-generated SQLC code (common data layer)
       │    ├── db.go
       │    └── models.go
       ├── /auth              # Feature: Authentication
       │    ├── errors.go      # Feature-specific error definitions
       │    ├── service.go     # Service interface & struct (business logic)
       │    └── handler.go     # Handler interface & struct (Echo endpoints)
       └── /letters           # Feature: Letters / Messaging
            ├── errors.go
            ├── service.go
            └── handler.go
```

---

## 2. Feature Folder Design Rules

Every feature subfolder (e.g., `/internal/letters`) contains exactly three primary layers:

### A. errors.go
Defines domain-specific errors that the service layer returns and handlers inspect to return appropriate HTTP status codes.

```go
package letters

import "errors"

var (
	ErrLetterNotFound   = errors.New("letter not found")
	ErrLetterUndelivered = errors.New("letter is still in transit")
)
```

### B. service.go
Defines the **business logic**. It declares an **interface** describing all operations and a concrete struct that implements it. The constructor accepts any required dependencies (like the SQLC `Querier` or base `*sql.DB`).

```go
package letters

import (
	"context"
	"ilkf_backend/internal/db"
)

// Service defines the business operations for this feature.
type Service interface {
	GetInbox(ctx context.Context, userID string) ([]db.Letter, error)
}

type service struct {
	queries db.Querier
}

// NewService instantiates the concrete service struct.
func NewService(queries db.Querier) Service {
	return &service{queries: queries}
}

func (s *service) GetInbox(ctx context.Context, userID string) ([]db.Letter, error) {
	// ... business logic ...
	return nil, nil
}
```

### C. handler.go
Defines the **HTTP layer**. It declares an **interface** for route registration and a concrete struct that implements it. It accepts the `Service` interface as a dependency (enabling easy mocking in tests).

```go
package letters

import (
	"github.com/labstack/echo/v4"
)

// Handler defines the router attachment method for this feature.
type Handler interface {
	RegisterRoutes(g *echo.Group)
}

type handler struct {
	svc Service
}

// NewHandler instantiates the concrete handler struct.
func NewHandler(svc Service) Handler {
	return &handler{svc: svc}
}

func (h *handler) RegisterRoutes(g *echo.Group) {
	g.GET("/inbox", h.GetInbox)
}

func (h *handler) GetInbox(c echo.Context) error {
	// 1. Get auth details
	// 2. Call h.svc.GetInbox()
	// 3. Render JSON
	return nil
}
```

---

## 3. Server Bootstrapping (`cmd/api/main.go`)

The entrypoint initializes the shared database, builds the global Echo router, and attaches each feature set's subrouter.

```go
package main

import (
	"database/sql"
	"log"
	
	"github.com/labstack/echo/v4"
	_ "github.com/mattn/go-sqlite3"
	
	"ilkf_backend/internal/db"
	"ilkf_backend/internal/letters"
)

func main() {
	dbConn, _ := sql.Open("sqlite3", "app.db")
	defer dbConn.Close()

	queries := db.New(dbConn)
	e := echo.New()

	// Base API Group
	apiGroup := e.Group("/api")

	// 1. Bootstrap Letters Feature
	lettersSvc := letters.NewService(queries)
	lettersHandler := letters.NewHandler(lettersSvc)
	lettersHandler.RegisterRoutes(apiGroup.Group("/letters"))

	// Start Server
	log.Fatal(e.Start(":8080"))
}
```

---

## 4. Reusability Benefits

1. **Perfect Decoupling**: Handlers do not depend on concrete services, and services do not depend on web routers or HTTP concepts. Everything is bounded by interfaces.
2. **Simplified Mocking**: Handlers can be unit tested in isolation by passing a mock implementation of the `Service` interface.
3. **No Circular Dependencies**: By grouping handlers, services, and errors into a single package per feature, Go package imports remain completely unidirectional and clean.
4. **Locality of Change**: When modifying a feature (e.g. adding a field to Letter), all modifications occur strictly within that feature's directory.
