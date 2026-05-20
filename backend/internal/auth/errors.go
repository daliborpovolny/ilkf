package auth

import "errors"

var (
	ErrInvalidInput       = errors.New("username cannot be empty")
	ErrUserExists         = errors.New("username already exists")
	ErrEmailExists        = errors.New("email already exists")
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrUserNotFound       = errors.New("no user found with this email")
	ErrResetExpired       = errors.New("password reset token has expired")
	ErrInvalidResetToken  = errors.New("invalid password reset token")
)
