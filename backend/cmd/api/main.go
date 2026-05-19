package main

import (
	"database/sql"
	"log"
	"os"
	"path/filepath"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	_ "github.com/mattn/go-sqlite3"

	"ilkf_backend/internal/auth"
	"ilkf_backend/internal/contacts"
	"ilkf_backend/internal/db"
	"ilkf_backend/internal/letters"
)

func main() {
	// Determine the port
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Determine the database file path
	dbPath := os.Getenv("DATABASE_PATH")
	if dbPath == "" {
		dbPath = "ilkf.db"
	}

	log.Printf("Initializing database at: %s", dbPath)

	// Ensure the parent directory of the database file exists
	dbDir := filepath.Dir(dbPath)
	if dbDir != "." && dbDir != "" {
		if err := os.MkdirAll(dbDir, 0755); err != nil {
			log.Fatalf("Failed to create database directory: %v", err)
		}
	}

	// Connect to SQLite with WAL mode enabled for concurrent read/write performance
	dbConn, err := sql.Open("sqlite3", dbPath+"?_journal_mode=WAL&_busy_timeout=5000")
	if err != nil {
		log.Fatalf("Failed to open database: %v", err)
	}
	defer dbConn.Close()

	// Verify database connection
	if err := dbConn.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	// Auto-initialize database schema
	schemaPath := "db/schema.sql"
	schemaBytes, err := os.ReadFile(schemaPath)
	if err != nil {
		// Try fallback if executed from cmd/api
		fallbackPath := filepath.Join("..", "..", "db", "schema.sql")
		schemaBytes, err = os.ReadFile(fallbackPath)
		if err != nil {
			log.Fatalf("Failed to read schema.sql from %s or %s: %v", schemaPath, fallbackPath, err)
		}
	}

	log.Printf("Executing schema migrations from schema.sql...")
	if _, err := dbConn.Exec(string(schemaBytes)); err != nil {
		log.Fatalf("Failed to execute schema: %v", err)
	}
	log.Println("Database initialized successfully.")

	queries := db.New(dbConn)

	// Setup Echo Server
	e := echo.New()
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{"*"},
		AllowHeaders: []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAccept, "X-User-ID"},
		AllowMethods: []string{echo.GET, echo.POST, echo.PUT, echo.DELETE, echo.OPTIONS},
	}))

	// Base API Group
	apiGroup := e.Group("/api")

	// 1. Auth Feature Group
	authSvc := auth.NewService(queries)
	authHandler := auth.NewHandler(authSvc)
	authHandler.RegisterRoutes(apiGroup)

	// 2. Letters Feature Group
	lettersSvc := letters.NewService(dbConn)
	lettersHandler := letters.NewHandler(lettersSvc)
	lettersHandler.RegisterRoutes(apiGroup.Group("/letters"))

	// 3. Contacts Feature Group
	contactsSvc := contacts.NewService(queries)
	contactsHandler := contacts.NewHandler(contactsSvc)
	contactsHandler.RegisterRoutes(apiGroup.Group("/contacts"))

	// Start server
	log.Printf("Starting ILKF Restructured Backend Server on port %s...", port)
	if err := e.Start(":" + port); err != nil {
		log.Fatalf("Server stopped: %v", err)
	}
}
