package letters

import (
	"time"
	"ilkf_backend/internal/db"
)

type LetterResponse struct {
	ID                        string     `json:"id"`
	SenderID                  string     `json:"sender_id"`
	SenderUsername            string     `json:"sender_username"`
	RecipientID               *string    `json:"recipient_id"`
	RecipientUsername         *string    `json:"recipient_username"`
	RecipientNameUnregistered *string    `json:"recipient_name_unregistered"`
	Subject                   string     `json:"subject"`
	Content                   string     `json:"content"`
	DeliveryAt                time.Time  `json:"delivery_at"`
	CreatedAt                 time.Time  `json:"created_at"`
	ReadAt                    *time.Time `json:"read_at"`
}

type PendingLetterResponse struct {
	ID             string    `json:"id"`
	SenderID       string    `json:"sender_id"`
	SenderUsername string    `json:"sender_username"`
	RecipientID    *string   `json:"recipient_id"`
	Subject        string    `json:"subject"`
	DeliveryAt     time.Time `json:"delivery_at"`
	CreatedAt      time.Time `json:"created_at"`
}

func ToLetterResponse(l db.GetLetterByIDRow) LetterResponse {
	var recipientID *string
	if l.RecipientID.Valid {
		val := l.RecipientID.String
		recipientID = &val
	}
	var recipientUsername *string
	if l.RecipientUsername.Valid {
		val := l.RecipientUsername.String
		recipientUsername = &val
	}
	var recipientNameUnreg *string
	if l.RecipientNameUnregistered.Valid {
		val := l.RecipientNameUnregistered.String
		recipientNameUnreg = &val
	}
	var readAt *time.Time
	if l.ReadAt.Valid {
		val := l.ReadAt.Time
		readAt = &val
	}
	return LetterResponse{
		ID:                        l.ID,
		SenderID:                  l.SenderID,
		SenderUsername:            l.SenderUsername,
		RecipientID:               recipientID,
		RecipientUsername:         recipientUsername,
		RecipientNameUnregistered: recipientNameUnreg,
		Subject:                    l.Subject,
		Content:                    l.Content,
		DeliveryAt:                 l.DeliveryAt,
		CreatedAt:                  l.CreatedAt,
		ReadAt:                     readAt,
	}
}

func ToInboxLettersResponse(list []db.GetInboxRow) []LetterResponse {
	res := make([]LetterResponse, len(list))
	for i, l := range list {
		var recipientID *string
		if l.RecipientID.Valid {
			val := l.RecipientID.String
			recipientID = &val
		}
		var recipientNameUnreg *string
		if l.RecipientNameUnregistered.Valid {
			val := l.RecipientNameUnregistered.String
			recipientNameUnreg = &val
		}
		var readAt *time.Time
		if l.ReadAt.Valid {
			val := l.ReadAt.Time
			readAt = &val
		}
		res[i] = LetterResponse{
			ID:                        l.ID,
			SenderID:                  l.SenderID,
			SenderUsername:            l.SenderUsername,
			RecipientID:               recipientID,
			RecipientUsername:         nil, // Not needed for inbox (current user is recipient)
			RecipientNameUnregistered: recipientNameUnreg,
			Subject:                    l.Subject,
			Content:                    l.Content,
			DeliveryAt:                 l.DeliveryAt,
			CreatedAt:                  l.CreatedAt,
			ReadAt:                     readAt,
		}
	}
	return res
}

func ToOutboxLettersResponse(list []db.GetOutboxRow) []LetterResponse {
	res := make([]LetterResponse, len(list))
	for i, l := range list {
		var recipientID *string
		if l.RecipientID.Valid {
			val := l.RecipientID.String
			recipientID = &val
		}
		var recipientUsername *string
		if l.RecipientUsername.Valid {
			val := l.RecipientUsername.String
			recipientUsername = &val
		}
		var recipientNameUnreg *string
		if l.RecipientNameUnregistered.Valid {
			val := l.RecipientNameUnregistered.String
			recipientNameUnreg = &val
		}
		var readAt *time.Time
		if l.ReadAt.Valid {
			val := l.ReadAt.Time
			readAt = &val
		}
		res[i] = LetterResponse{
			ID:                        l.ID,
			SenderID:                  l.SenderID,
			SenderUsername:            "", // Not needed for outbox (current user is sender)
			RecipientID:               recipientID,
			RecipientUsername:         recipientUsername,
			RecipientNameUnregistered: recipientNameUnreg,
			Subject:                    l.Subject,
			Content:                    l.Content,
			DeliveryAt:                 l.DeliveryAt,
			CreatedAt:                  l.CreatedAt,
			ReadAt:                     readAt,
		}
	}
	return res
}

func ToPendingLetterResponse(l db.GetPendingIncomingRow) PendingLetterResponse {
	var recipientID *string
	if l.RecipientID.Valid {
		val := l.RecipientID.String
		recipientID = &val
	}
	return PendingLetterResponse{
		ID:             l.ID,
		SenderID:       l.SenderID,
		SenderUsername: l.SenderUsername,
		RecipientID:    recipientID,
		Subject:        l.Subject,
		DeliveryAt:     l.DeliveryAt,
		CreatedAt:      l.CreatedAt,
	}
}

func ToPendingLettersResponse(list []db.GetPendingIncomingRow) []PendingLetterResponse {
	res := make([]PendingLetterResponse, len(list))
	for i, l := range list {
		res[i] = ToPendingLetterResponse(l)
	}
	return res
}

func ToOpenLettersResponse(list []db.GetOpenLettersForUnregisteredRow) []LetterResponse {
	res := make([]LetterResponse, len(list))
	for i, l := range list {
		var recipientNameUnreg *string
		if l.RecipientNameUnregistered.Valid {
			val := l.RecipientNameUnregistered.String
			recipientNameUnreg = &val
		}
		var readAt *time.Time
		if l.ReadAt.Valid {
			val := l.ReadAt.Time
			readAt = &val
		}
		res[i] = LetterResponse{
			ID:                        l.ID,
			SenderID:                  l.SenderID,
			SenderUsername:            l.SenderUsername,
			RecipientID:               nil,
			RecipientUsername:         nil,
			RecipientNameUnregistered: recipientNameUnreg,
			Subject:                    l.Subject,
			Content:                    l.Content,
			DeliveryAt:                 l.DeliveryAt,
			CreatedAt:                  l.CreatedAt,
			ReadAt:                     readAt,
		}
	}
	return res
}
