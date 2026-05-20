package auth

import (
	"context"
	"database/sql"
	"errors"
	"os"
	"path/filepath"
	"testing"

	_ "github.com/mattn/go-sqlite3"
	"ilkf_backend/internal/db"
)

func setupTestDB(t *testing.T) (*sql.DB, Service) {
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
	authSvc := NewService(queries)
	return dbConn, authSvc
}

func TestRegisterAndLogin(t *testing.T) {
	dbConn, authSvc := setupTestDB(t)
	defer dbConn.Close()

	ctx := context.Background()

	// 1. Success Registration
	user, err := authSvc.Register(ctx, "clara", "clara@ilkf.local", "clarapassword")
	if err != nil {
		t.Fatalf("expected Clara registration to succeed, got: %v", err)
	}
	if user.Username != "clara" {
		t.Errorf("expected username to be clara, got: %s", user.Username)
	}
	if !user.Email.Valid || user.Email.String != "clara@ilkf.local" {
		t.Errorf("expected email to be clara@ilkf.local, got: %v", user.Email)
	}

	// 2. Duplicate Username Registration should fail
	_, err = authSvc.Register(ctx, "clara", "clara2@ilkf.local", "somepass")
	if !errors.Is(err, ErrUserExists) {
		t.Errorf("expected ErrUserExists error for duplicate username, got: %v", err)
	}

	// 3. Duplicate Email Registration should fail
	_, err = authSvc.Register(ctx, "clara_alternative", "clara@ilkf.local", "somepass")
	if !errors.Is(err, ErrEmailExists) {
		t.Errorf("expected ErrEmailExists error for duplicate email, got: %v", err)
	}

	// 4. Success Login with Username
	loginUser, err := authSvc.Login(ctx, "clara", "clarapassword")
	if err != nil {
		t.Fatalf("expected Clara login via username to succeed, got: %v", err)
	}
	if loginUser.ID != user.ID {
		t.Errorf("expected matching logged in user ID, got %s vs %s", loginUser.ID, user.ID)
	}

	// 5. Success Login with Email
	loginUserByEmail, err := authSvc.Login(ctx, "clara@ilkf.local", "clarapassword")
	if err != nil {
		t.Fatalf("expected Clara login via email to succeed, got: %v", err)
	}
	if loginUserByEmail.ID != user.ID {
		t.Errorf("expected matching logged in user ID, got %s vs %s", loginUserByEmail.ID, user.ID)
	}

	// 6. Failed Login - Wrong Password
	_, err = authSvc.Login(ctx, "clara", "wrongpassword")
	if !errors.Is(err, ErrInvalidCredentials) {
		t.Errorf("expected ErrInvalidCredentials for incorrect password, got: %v", err)
	}

	// 7. Failed Login - Nonexistent User
	_, err = authSvc.Login(ctx, "nobody", "somepassword")
	if !errors.Is(err, ErrInvalidCredentials) {
		t.Errorf("expected ErrInvalidCredentials for nonexistent user, got: %v", err)
	}
}

func TestForgotPasswordAndReset(t *testing.T) {
	dbConn, authSvc := setupTestDB(t)
	defer dbConn.Close()

	ctx := context.Background()

	// Register user
	user, err := authSvc.Register(ctx, "david", "david@ilkf.local", "davidpassword")
	if err != nil {
		t.Fatalf("failed to register david: %v", err)
	}

	// 1. Forgot password request for unregistered email should fail
	_, err = authSvc.ForgotPassword(ctx, "nobody@ilkf.local")
	if !errors.Is(err, ErrUserNotFound) {
		t.Errorf("expected ErrUserNotFound for missing email forgot password request, got: %v", err)
	}

	// 2. Successful forgot password request
	token, err := authSvc.ForgotPassword(ctx, "david@ilkf.local")
	if err != nil {
		t.Fatalf("expected forgot password request to succeed, got: %v", err)
	}
	if token == "" {
		t.Fatal("expected token to not be empty")
	}

	// 3. Reset password using invalid token should fail
	err = authSvc.ResetPassword(ctx, "fake-reset-token", "newpassword123")
	if !errors.Is(err, ErrInvalidResetToken) {
		t.Errorf("expected ErrInvalidResetToken for fake token, got: %v", err)
	}

	// 4. Reset password using valid token succeeds
	err = authSvc.ResetPassword(ctx, token, "newpassword123")
	if err != nil {
		t.Fatalf("expected password reset to succeed, got: %v", err)
	}

	// 5. Verifying token is invalidated after use (secondary reset should fail)
	err = authSvc.ResetPassword(ctx, token, "anotherpassword")
	if !errors.Is(err, ErrInvalidResetToken) {
		t.Errorf("expected token to be invalidated after use, got: %v", err)
	}

	// 6. Logging in with old password fails
	_, err = authSvc.Login(ctx, "david", "davidpassword")
	if !errors.Is(err, ErrInvalidCredentials) {
		t.Errorf("expected old password to fail, got: %v", err)
	}

	// 7. Logging in with new password succeeds
	loginUser, err := authSvc.Login(ctx, "david", "newpassword123")
	if err != nil {
		t.Fatalf("expected login with new password to succeed, got: %v", err)
	}
	if loginUser.ID != user.ID {
		t.Errorf("expected correct user ID, got: %s", loginUser.ID)
	}
}

func TestLegacyRegisterOrLoginCompatibility(t *testing.T) {
	dbConn, authSvc := setupTestDB(t)
	defer dbConn.Close()

	ctx := context.Background()

	// 1. Calling RegisterOrLogin should succeed without email and password
	user, err := authSvc.RegisterOrLogin(ctx, "legacy_alice")
	if err != nil {
		t.Fatalf("expected RegisterOrLogin mock to succeed, got: %v", err)
	}
	if user.Username != "legacy_alice" {
		t.Errorf("expected username to be legacy_alice, got: %s", user.Username)
	}
	if user.Email.Valid || user.PasswordHash.Valid {
		t.Errorf("expected legacy registers to have NULL email and password hash, got email: %v, hash: %v", user.Email, user.PasswordHash)
	}

	// 2. Calling RegisterOrLogin again on existing user returns the user
	user2, err := authSvc.RegisterOrLogin(ctx, "legacy_alice")
	if err != nil {
		t.Fatalf("expected subsequent mock calls to succeed, got: %v", err)
	}
	if user2.ID != user.ID {
		t.Errorf("expected matching legacy IDs, got %s vs %s", user2.ID, user.ID)
	}
}
