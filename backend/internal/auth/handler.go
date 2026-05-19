package auth

import (
	"errors"
	"net/http"

	"github.com/labstack/echo/v4"
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
	g.POST("/auth", h.Auth)
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

	return c.JSON(http.StatusOK, user)
}
