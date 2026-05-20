package letters

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/google/uuid"
	"ilkf_backend/internal/db"
)

type Service interface {
	SendLetter(ctx context.Context, senderID, recipientUsername, unregisteredName, subject, content string, deliveryDelay time.Duration) (*db.GetLetterByIDRow, error)
	GetInbox(ctx context.Context, userID string) ([]db.GetInboxRow, error)
	GetPendingIncoming(ctx context.Context, userID string) ([]db.GetPendingIncomingRow, error)
	GetOutbox(ctx context.Context, userID string) ([]db.GetOutboxRow, error)
	GetOpenLetters(ctx context.Context, unregisteredName string) ([]db.GetOpenLettersForUnregisteredRow, error)
	GetLetterByID(ctx context.Context, letterID, requestingUserID string) (*db.GetLetterByIDRow, error)
}

type service struct {
	dbConn  *sql.DB
	queries *db.Queries
}

func NewService(dbConn *sql.DB) Service {
	return &service{
		dbConn:  dbConn,
		queries: db.New(dbConn),
	}
}

func (s *service) SendLetter(
	ctx context.Context,
	senderID, recipientUsername, unregisteredName, subject, content string,
	deliveryDelay time.Duration,
) (*db.GetLetterByIDRow, error) {
	if senderID == "" || subject == "" || content == "" {
		return nil, ErrInvalidInput
	}

	deliveryAt := time.Now().Add(deliveryDelay)
	letterID := uuid.New().String()

	var recipientID sql.NullString
	var recipientNameUnreg sql.NullString

	tx, err := s.dbConn.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	txQueries := s.queries.WithTx(tx)

	if recipientUsername != "" {
		recipUser, err := txQueries.GetUserByUsername(ctx, recipientUsername)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				return nil, ErrUserNotFound
			}
			return nil, err
		}
		recipientID = sql.NullString{String: recipUser.ID, Valid: true}

		// Update contacts for both directions
		now := time.Now()
		if err = txQueries.UpsertContact(ctx, db.UpsertContactParams{
			UserID:            senderID,
			ContactID:         recipUser.ID,
			LastInteractionAt: now,
		}); err != nil {
			return nil, err
		}

		if err = txQueries.UpsertContact(ctx, db.UpsertContactParams{
			UserID:            recipUser.ID,
			ContactID:         senderID,
			LastInteractionAt: now,
		}); err != nil {
			return nil, err
		}
	} else if unregisteredName != "" {
		recipientNameUnreg = sql.NullString{String: unregisteredName, Valid: true}
	} else {
		return nil, ErrInvalidInput
	}

	_, err = txQueries.CreateLetter(ctx, db.CreateLetterParams{
		ID:                         letterID,
		SenderID:                   senderID,
		RecipientID:                recipientID,
		RecipientNameUnregistered: recipientNameUnreg,
		Subject:                    subject,
		Content:                    content,
		DeliveryAt:                 deliveryAt,
	})
	if err != nil {
		return nil, err
	}

	createdLetter, err := txQueries.GetLetterByID(ctx, letterID)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return &createdLetter, nil
}

func (s *service) GetInbox(ctx context.Context, userID string) ([]db.GetInboxRow, error) {
	return s.queries.GetInbox(ctx, db.GetInboxParams{
		RecipientID: sql.NullString{String: userID, Valid: true},
		DeliveryAt:  time.Now(),
	})
}

func (s *service) GetPendingIncoming(ctx context.Context, userID string) ([]db.GetPendingIncomingRow, error) {
	return s.queries.GetPendingIncoming(ctx, db.GetPendingIncomingParams{
		RecipientID: sql.NullString{String: userID, Valid: true},
		DeliveryAt:  time.Now(),
	})
}

func (s *service) GetOutbox(ctx context.Context, userID string) ([]db.GetOutboxRow, error) {
	return s.queries.GetOutbox(ctx, userID)
}

func (s *service) GetOpenLetters(ctx context.Context, unregisteredName string) ([]db.GetOpenLettersForUnregisteredRow, error) {
	return s.queries.GetOpenLettersForUnregistered(ctx, db.GetOpenLettersForUnregisteredParams{
		RecipientNameUnregistered: sql.NullString{String: unregisteredName, Valid: true},
		DeliveryAt:                 time.Now(),
	})
}

func (s *service) GetLetterByID(ctx context.Context, letterID, requestingUserID string) (*db.GetLetterByIDRow, error) {
	letter, err := s.queries.GetLetterByID(ctx, letterID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrLetterNotFound
		}
		return nil, err
	}

	if letter.SenderID == requestingUserID {
		return &letter, nil
	}

	if letter.RecipientID.Valid && letter.RecipientID.String == requestingUserID {
		if time.Now().Before(letter.DeliveryAt) {
			return nil, ErrLetterUndelivered
		}
		if !letter.ReadAt.Valid {
			now := time.Now()
			tx, err := s.dbConn.BeginTx(ctx, nil)
			if err == nil {
				defer tx.Rollback()
				txQueries := s.queries.WithTx(tx)
				if err = txQueries.MarkLetterAsRead(ctx, db.MarkLetterAsReadParams{
					ReadAt: sql.NullTime{Time: now, Valid: true},
					ID:     letter.ID,
				}); err == nil {
					if err = tx.Commit(); err == nil {
						letter.ReadAt = sql.NullTime{Time: now, Valid: true}
					}
				}
			}
		}
		return &letter, nil
	}

	if !letter.RecipientID.Valid && letter.RecipientNameUnregistered.Valid {
		if time.Now().Before(letter.DeliveryAt) {
			return nil, ErrLetterUndelivered
		}
		return &letter, nil
	}

	return nil, ErrLetterNotFound
}
