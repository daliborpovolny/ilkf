package auth

import "errors"

var (
	ErrInvalidInput = errors.New("username cannot be empty")
)
