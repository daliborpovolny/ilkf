package auth

import (
	"errors"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"ilkf_backend/internal/db"
)

type Handler interface {
	RegisterRoutes(g *echo.Group)
}

type handler struct {
	svc Service
}

func NewHandler(svc Service) Handler {
	return &handler{svc: svc}
}

func (h *handler) RegisterRoutes(g *echo.Group) {
	g.POST("/auth", h.Auth) // Keep this legacy route intact for test suites
	g.POST("/auth/register", h.Register)
	g.POST("/auth/login", h.Login)
	g.POST("/auth/forgot-password", h.ForgotPassword)
	g.POST("/auth/reset-password", h.ResetPassword)
}

type UserResponse struct {
	ID        string    `json:"id"`
	Username  string    `json:"username"`
	Email     *string   `json:"email"`
	CreatedAt time.Time `json:"created_at"`
}

func ToUserResponse(u *db.User) UserResponse {
	var email *string
	if u.Email.Valid {
		val := u.Email.String
		email = &val
	}
	return UserResponse{
		ID:        u.ID,
		Username:  u.Username,
		Email:     email,
		CreatedAt: u.CreatedAt,
	}
}

type AuthRequest struct {
	Username string `json:"username"`
}

func (h *handler) Auth(c echo.Context) error {
	var req AuthRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, echo.Map{"error": "Invalid request body"})
	}

	user, err := h.svc.RegisterOrLogin(c.Request().Context(), req.Username)
	if err != nil {
		if errors.Is(err, ErrInvalidInput) {
			return c.JSON(http.StatusBadRequest, echo.Map{"error": err.Error()})
		}
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": "Internal server error"})
	}

	return c.JSON(http.StatusOK, ToUserResponse(user))
}

type RegisterRequest struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *handler) Register(c echo.Context) error {
	var req RegisterRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, echo.Map{"error": "Invalid request body"})
	}

	user, err := h.svc.Register(c.Request().Context(), req.Username, req.Email, req.Password)
	if err != nil {
		if errors.Is(err, ErrUserExists) || errors.Is(err, ErrEmailExists) {
			return c.JSON(http.StatusConflict, echo.Map{"error": err.Error()})
		}
		return c.JSON(http.StatusBadRequest, echo.Map{"error": err.Error()})
	}

	return c.JSON(http.StatusCreated, ToUserResponse(user))
}

type LoginRequest struct {
	UsernameOrEmail string `json:"username_or_email"`
	Password        string `json:"password"`
}

func (h *handler) Login(c echo.Context) error {
	var req LoginRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, echo.Map{"error": "Invalid request body"})
	}

	user, err := h.svc.Login(c.Request().Context(), req.UsernameOrEmail, req.Password)
	if err != nil {
		if errors.Is(err, ErrInvalidCredentials) {
			return c.JSON(http.StatusUnauthorized, echo.Map{"error": err.Error()})
		}
		return c.JSON(http.StatusBadRequest, echo.Map{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, ToUserResponse(user))
}

type ForgotPasswordRequest struct {
	Email string `json:"email"`
}

func (h *handler) ForgotPassword(c echo.Context) error {
	var req ForgotPasswordRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, echo.Map{"error": "Invalid request body"})
	}

	_, err := h.svc.ForgotPassword(c.Request().Context(), req.Email)
	if err != nil {
		if errors.Is(err, ErrUserNotFound) {
			return c.JSON(http.StatusNotFound, echo.Map{"error": err.Error()})
		}
		return c.JSON(http.StatusBadRequest, echo.Map{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, echo.Map{"message": "If this email is registered, a password reset link has been sent."})
}

type ResetPasswordRequest struct {
	Token       string `json:"token"`
	NewPassword string `json:"new_password"`
}

func (h *handler) ResetPassword(c echo.Context) error {
	var req ResetPasswordRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, echo.Map{"error": "Invalid request body"})
	}

	err := h.svc.ResetPassword(c.Request().Context(), req.Token, req.NewPassword)
	if err != nil {
		if errors.Is(err, ErrResetExpired) || errors.Is(err, ErrInvalidResetToken) {
			return c.JSON(http.StatusBadRequest, echo.Map{"error": err.Error()})
		}
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": "Internal server error"})
	}

	return c.JSON(http.StatusOK, echo.Map{"message": "Your password has been successfully reset."})
}
