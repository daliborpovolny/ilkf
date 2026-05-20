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

	// Development Mode: Drop the existing database on startup to recreate fresh schema
	appEnv := os.Getenv("APP_ENV")
	if appEnv != "production" {
		log.Printf("Development Mode (APP_ENV=%s): Dropping existing database at %s to start fresh...", appEnv, dbPath)
		_ = os.Remove(dbPath)
		_ = os.Remove(dbPath + "-shm")
		_ = os.Remove(dbPath + "-wal")
	} else {
		log.Printf("Production Mode: Keeping existing database at %s persistent.", dbPath)
	}

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
	// Auto-upgrade database schema with read_at column if it does not already exist
	_, _ = dbConn.Exec("ALTER TABLE letters ADD COLUMN read_at DATETIME;")
	addColumnIfNotExists(dbConn, "users", "email", "TEXT UNIQUE")
	addColumnIfNotExists(dbConn, "users", "password_hash", "TEXT")
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

func addColumnIfNotExists(dbConn *sql.DB, tableName, columnName, columnDefinition string) {
	rows, err := dbConn.Query("PRAGMA table_info(" + tableName + ")")
	if err != nil {
		log.Printf("Failed to check table info for %s: %v", tableName, err)
		return
	}
	defer rows.Close()

	exists := false
	for rows.Next() {
		var cid int
		var name, ctype string
		var notnull, pk int
		var dfltVal interface{}
		if err := rows.Scan(&cid, &name, &ctype, &notnull, &dfltVal, &pk); err != nil {
			continue
		}
		if name == columnName {
			exists = true
			break
		}
	}
	if !exists {
		query := "ALTER TABLE " + tableName + " ADD COLUMN " + columnName + " " + columnDefinition
		if _, err := dbConn.Exec(query); err != nil {
			log.Printf("Failed to add column %s to %s: %v", columnName, tableName, err)
		} else {
			log.Printf("Added column %s to %s successfully", columnName, tableName)
		}
	}
}
