package auth

import (
	"context"
	"database/sql"
	"errors"

	"github.com/google/uuid"
	"ilkf_backend/internal/db"
)

type Service interface {
	RegisterOrLogin(ctx context.Context, username string) (*db.User, error)
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

	// User doesn't exist, create one
	newID := uuid.New().String()
	createdUser, err := s.queries.CreateUser(ctx, db.CreateUserParams{
		ID:       newID,
		Username: username,
	})
	if err != nil {
		return nil, err
	}

	return &createdUser, nil
}
