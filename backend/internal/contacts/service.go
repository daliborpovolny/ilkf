package contacts

import (
	"context"
	"sort"
	"time"

	"ilkf_backend/internal/db"
)

type ContactWithMetadata struct {
	ContactID          string     `json:"contact_id"`
	ContactUsername    string     `json:"contact_username"`
	LastInteractionAt  time.Time  `json:"last_interaction_at"`
	LastLetterID       *string    `json:"last_letter_id,omitempty"`
	LastLetterSenderID *string    `json:"last_letter_sender_id,omitempty"`
	LastLetterDelivery *time.Time `json:"last_letter_delivery_at,omitempty"`
	LastLetterCreated  *time.Time `json:"last_letter_created_at,omitempty"`
}

type Service interface {
	GetContacts(ctx context.Context, userID string, sortBy string) ([]ContactWithMetadata, error)
}

type service struct {
	queries db.Querier
}

func NewService(queries db.Querier) Service {
	return &service{queries: queries}
}

func (s *service) GetContacts(ctx context.Context, userID string, sortBy string) ([]ContactWithMetadata, error) {
	if userID == "" {
		return nil, ErrInvalidInput
	}

	rows, err := s.queries.GetContactsWithLastLetterMetadata(ctx, userID)
	if err != nil {
		return nil, err
	}

	contacts := make([]ContactWithMetadata, len(rows))
	for i, r := range rows {
		var lastLetterID, lastLetterSenderID *string
		var lastLetterDelivery, lastLetterCreated *time.Time

		if r.LastLetterID.Valid {
			idVal := r.LastLetterID.String
			lastLetterID = &idVal
		}
		if r.LastLetterSenderID.Valid {
			senderVal := r.LastLetterSenderID.String
			lastLetterSenderID = &senderVal
		}
		if r.LastLetterDeliveryAt.Valid {
			delivVal := r.LastLetterDeliveryAt.Time
			lastLetterDelivery = &delivVal
		}
		if r.LastLetterCreatedAt.Valid {
			createdVal := r.LastLetterCreatedAt.Time
			lastLetterCreated = &createdVal
		}

		contacts[i] = ContactWithMetadata{
			ContactID:          r.ContactID,
			ContactUsername:    r.ContactUsername,
			LastInteractionAt:  r.LastInteractionAt,
			LastLetterID:       lastLetterID,
			LastLetterSenderID: lastLetterSenderID,
			LastLetterDelivery: lastLetterDelivery,
			LastLetterCreated:  lastLetterCreated,
		}
	}

	switch sortBy {
	case "oldest":
		sort.Slice(contacts, func(i, j int) bool {
			return contacts[i].LastInteractionAt.Before(contacts[j].LastInteractionAt)
		})
	case "pending_reply":
		sort.Slice(contacts, func(i, j int) bool {
			iIsPending := contacts[i].LastLetterSenderID != nil && *contacts[i].LastLetterSenderID == contacts[i].ContactID
			jIsPending := contacts[j].LastLetterSenderID != nil && *contacts[j].LastLetterSenderID == contacts[j].ContactID
			if iIsPending != jIsPending {
				return iIsPending
			}
			return contacts[i].LastInteractionAt.After(contacts[j].LastInteractionAt)
		})
	case "most_recent":
		fallthrough
	default:
		sort.Slice(contacts, func(i, j int) bool {
			return contacts[i].LastInteractionAt.After(contacts[j].LastInteractionAt)
		})
	}

	return contacts, nil
}
