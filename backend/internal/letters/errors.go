package letters

import "errors"

var (
	ErrInvalidInput      = errors.New("sender, subject, and content are required")
	ErrUserNotFound      = errors.New("recipient username not found")
	ErrLetterNotFound    = errors.New("letter not found")
	ErrLetterUndelivered = errors.New("letter is still in transit")
)
