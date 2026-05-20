package auth

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"ilkf_backend/internal/db"
)

type Service interface {
	RegisterOrLogin(ctx context.Context, username string) (*db.User, error)
	Register(ctx context.Context, username, email, password string) (*db.User, error)
	Login(ctx context.Context, usernameOrEmail, password string) (*db.User, error)
	ForgotPassword(ctx context.Context, email string) (string, error)
	ResetPassword(ctx context.Context, token, newPassword string) error
}

type service struct {
	queries db.Querier
}

func NewService(queries db.Querier) Service {
	return &service{queries: queries}
}

func (s *service) RegisterOrLogin(ctx context.Context, username string) (*db.User, error) {
	if username == "" {
		return nil, ErrInvalidInput
	}

	user, err := s.queries.GetUserByUsername(ctx, username)
	if err == nil {
		return &user, nil
	}

	if !errors.Is(err, sql.ErrNoRows) {
		return nil, err
	}

	// User doesn't exist, create one without email/password (legacy support)
	newID := uuid.New().String()
	createdUser, err := s.queries.CreateUser(ctx, db.CreateUserParams{
		ID:           newID,
		Username:     username,
		Email:        sql.NullString{Valid: false},
		PasswordHash: sql.NullString{Valid: false},
	})
	if err != nil {
		return nil, err
	}

	return &createdUser, nil
}

func (s *service) Register(ctx context.Context, username, email, password string) (*db.User, error) {
	if username == "" || email == "" || password == "" {
		return nil, errors.New("username, email, and password are required")
	}

	// Check if username already exists
	_, err := s.queries.GetUserByUsername(ctx, username)
	if err == nil {
		return nil, ErrUserExists
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return nil, err
	}

	// Check if email already exists
	_, err = s.queries.GetUserByEmail(ctx, sql.NullString{String: email, Valid: true})
	if err == nil {
		return nil, ErrEmailExists
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return nil, err
	}

	// Hash password using bcrypt
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	newID := uuid.New().String()
	createdUser, err := s.queries.CreateUser(ctx, db.CreateUserParams{
		ID:           newID,
		Username:     username,
		Email:        sql.NullString{String: email, Valid: true},
		PasswordHash: sql.NullString{String: string(hashed), Valid: true},
	})
	if err != nil {
		return nil, err
	}

	return &createdUser, nil
}

func (s *service) Login(ctx context.Context, usernameOrEmail, password string) (*db.User, error) {
	if usernameOrEmail == "" || password == "" {
		return nil, errors.New("credentials are required")
	}

	var user db.User
	var err error

	// Try fetching by username first, then by email
	user, err = s.queries.GetUserByUsername(ctx, usernameOrEmail)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			// Try fetching by email
			user, err = s.queries.GetUserByEmail(ctx, sql.NullString{String: usernameOrEmail, Valid: true})
			if err != nil {
				if errors.Is(err, sql.ErrNoRows) {
					return nil, ErrInvalidCredentials
				}
				return nil, err
			}
		} else {
			return nil, err
		}
	}

	// If the user exists but has no password (e.g. registered via legacy mock), we deny password-based login
	if !user.PasswordHash.Valid || user.PasswordHash.String == "" {
		return nil, ErrInvalidCredentials
	}

	// Compare bcrypt password hash
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash.String), []byte(password))
	if err != nil {
		return nil, ErrInvalidCredentials
	}

	return &user, nil
}

func (s *service) ForgotPassword(ctx context.Context, email string) (string, error) {
	if email == "" {
		return "", errors.New("email is required")
	}

	// Periodically clean up old expired tokens
	_ = s.queries.DeleteExpiredPasswordResets(ctx, time.Now())

	user, err := s.queries.GetUserByEmail(ctx, sql.NullString{String: email, Valid: true})
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return "", ErrUserNotFound
		}
		return "", err
	}

	// Generate secure token (UUID v4 is safe for this setup)
	token := uuid.New().String()
	expiresAt := time.Now().Add(15 * time.Minute)

	err = s.queries.CreatePasswordReset(ctx, db.CreatePasswordResetParams{
		UserID:    user.ID,
		Token:     token,
		ExpiresAt: expiresAt,
	})
	if err != nil {
		return "", err
	}

	// Simulate sending email
	resetLink := fmt.Sprintf("http://localhost:8080/api/auth/reset-password?token=%s", token)
	emailContent := fmt.Sprintf(
		"From: ILKF Postmaster <postmaster@ilkf.local>\n"+
			"To: %s <%s>\n"+
			"Subject: Password Reset Request\n\n"+
			"Dearest Friend,\n\n"+
			"We received a request to reset your writing desk key (password) for ILKF.\n"+
			"If you made this request, please use the following reset token to set a new password:\n\n"+
			"Token: %s\n\n"+
			"Or reset directly via this link:\n"+
			"%s\n\n"+
			"This token shall expire in fifteen minutes, after which it will return to dust.\n\n"+
			"Yours faithfully,\n"+
			"The ILKF Postmaster\n",
		user.Username, email, token, resetLink,
	)

	// Print to terminal console log
	fmt.Printf("\n--- [SIMULATED EMAIL DISPATCH] ---\n%s----------------------------------\n\n", emailContent)

	// Write to last_reset_email.txt in the workspace root for local environment testing
	workspaceRoot := "/Users/daliborpovolny/coding/ilkf"
	filePath := filepath.Join(workspaceRoot, "last_reset_email.txt")
	err = os.WriteFile(filePath, []byte(emailContent), 0644)
	if err != nil {
		fmt.Printf("Warning: Failed to write simulated email to file: %v\n", err)
	}

	return token, nil
}

func (s *service) ResetPassword(ctx context.Context, token, newPassword string) error {
	if token == "" || newPassword == "" {
		return errors.New("token and new password are required")
	}

	// Periodically clean up expired resets
	_ = s.queries.DeleteExpiredPasswordResets(ctx, time.Now())

	reset, err := s.queries.GetPasswordResetByToken(ctx, token)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return ErrInvalidResetToken
		}
		return err
	}

	// Verify expiration
	if time.Now().After(reset.ExpiresAt) {
		_ = s.queries.DeletePasswordReset(ctx, token)
		return ErrResetExpired
	}

	// Hash the new password
	hashed, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	// Update user's password
	err = s.queries.UpdateUserPassword(ctx, db.UpdateUserPasswordParams{
		PasswordHash: sql.NullString{String: string(hashed), Valid: true},
		ID:           reset.UserID,
	})
	if err != nil {
		return err
	}

	// Delete used token to invalidate it immediately
	_ = s.queries.DeletePasswordReset(ctx, token)

	return nil
}
