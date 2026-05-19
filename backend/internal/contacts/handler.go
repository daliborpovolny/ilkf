package contacts

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
	g.GET("", h.GetContacts)
}

func getUserID(c echo.Context) string {
	return c.Request().Header.Get("X-User-ID")
}

func (h *handler) GetContacts(c echo.Context) error {
	userID := getUserID(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, echo.Map{"error": "X-User-ID header required"})
	}

	sortBy := c.QueryParam("sort")
	contacts, err := h.svc.GetContacts(c.Request().Context(), userID, sortBy)
	if err != nil {
		if errors.Is(err, ErrInvalidInput) {
			return c.JSON(http.StatusBadRequest, echo.Map{"error": err.Error()})
		}
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, contacts)
}
