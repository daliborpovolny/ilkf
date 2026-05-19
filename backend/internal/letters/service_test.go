package letters

import (
	"context"
	"database/sql"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"

	_ "github.com/mattn/go-sqlite3"
	"ilkf_backend/internal/auth"
	"ilkf_backend/internal/db"
)

func setupTestDB(t *testing.T) (*sql.DB, Service, auth.Service) {
	// Connect to in-memory SQLite
	dbConn, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatalf("failed to open database: %v", err)
	}

	// Read schema
	schemaPath := filepath.Join("..", "..", "db", "schema.sql")
	schemaBytes, err := os.ReadFile(schemaPath)
	if err != nil {
		t.Fatalf("failed to read schema.sql: %v", err)
	}

	if _, err := dbConn.Exec(string(schemaBytes)); err != nil {
		t.Fatalf("failed to execute schema: %v", err)
	}

	queries := db.New(dbConn)
	lettersSvc := NewService(dbConn)
	authSvc := auth.NewService(queries)
	return dbConn, lettersSvc, authSvc
}


func TestDelayedLetterDelivery(t *testing.T) {
	dbConn, lettersSvc, authSvc := setupTestDB(t)
	defer dbConn.Close()

	ctx := context.Background()

	// 1. Create users
	alice, err := authSvc.RegisterOrLogin(ctx, "alice")
	if err != nil {
		t.Fatalf("failed to register alice: %v", err)
	}

	bob, err := authSvc.RegisterOrLogin(ctx, "bob")
	if err != nil {
		t.Fatalf("failed to register bob: %v", err)
	}

	// 2. Send a letter with 24 hours delay (future letter)
	futureLetter, err := lettersSvc.SendLetter(
		ctx,
		alice.ID,
		"bob",
		"",
		"Secret Message",
		"This is secret content!",
		24*time.Hour,
	)
	if err != nil {
		t.Fatalf("failed to send future letter: %v", err)
	}

	// 3. Send a letter with 0 seconds delay (instant letter)
	instantLetter, err := lettersSvc.SendLetter(
		ctx,
		alice.ID,
		"bob",
		"",
		"Hello Bob",
		"Welcome to the slow app!",
		0,
	)
	if err != nil {
		t.Fatalf("failed to send instant letter: %v", err)
	}

	// 4. Test GetInbox for Bob: Should ONLY return the instant letter
	inbox, err := lettersSvc.GetInbox(ctx, bob.ID)
	if err != nil {
		t.Fatalf("failed to get inbox: %v", err)
	}

	if len(inbox) != 1 {
		t.Errorf("expected inbox to have 1 letter, got %d", len(inbox))
	} else {
		if inbox[0].ID != instantLetter.ID {
			t.Errorf("expected inbox letter ID to be %s, got %s", instantLetter.ID, inbox[0].ID)
		}
		if inbox[0].Content != "Welcome to the slow app!" {
			t.Errorf("unexpected content: %s", inbox[0].Content)
		}
	}

	// 5. Test GetPendingIncoming for Bob: Should return the future letter metadata
	pending, err := lettersSvc.GetPendingIncoming(ctx, bob.ID)
	if err != nil {
		t.Fatalf("failed to get pending incoming: %v", err)
	}

	if len(pending) != 1 {
		t.Errorf("expected pending incoming to have 1 letter, got %d", len(pending))
	} else {
		if pending[0].ID != futureLetter.ID {
			t.Errorf("expected pending letter ID to be %s, got %s", futureLetter.ID, pending[0].ID)
		}
		if pending[0].Subject != "Secret Message" {
			t.Errorf("unexpected subject: %s", pending[0].Subject)
		}
	}

	// 6. Test direct letter retrieval: Bob trying to read the future letter
	_, err = lettersSvc.GetLetterByID(ctx, futureLetter.ID, bob.ID)
	if !errors.Is(err, ErrLetterUndelivered) {
		t.Errorf("expected ErrLetterUndelivered when bob reads undelivered letter, got: %v", err)
	}

	// 7. Test direct letter retrieval: Bob reading the instant letter
	readInstant, err := lettersSvc.GetLetterByID(ctx, instantLetter.ID, bob.ID)
	if err != nil {
		t.Fatalf("failed to read instant letter: %v", err)
	}
	if readInstant.Content != "Welcome to the slow app!" {
		t.Errorf("expected read content to match, got %s", readInstant.Content)
	}

	// 8. Test direct letter retrieval: Alice reading her own future letter (she sent it)
	readFutureAlice, err := lettersSvc.GetLetterByID(ctx, futureLetter.ID, alice.ID)
	if err != nil {
		t.Fatalf("alice failed to read her own future letter: %v", err)
	}
	if readFutureAlice.Content != "This is secret content!" {
		t.Errorf("expected alice to see full content of her own sent letter, got %s", readFutureAlice.Content)
	}
}
