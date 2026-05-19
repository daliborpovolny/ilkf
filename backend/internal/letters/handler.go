package letters

import (
	"errors"
	"net/http"
	"time"

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
	g.POST("", h.SendLetter)
	g.GET("/inbox", h.GetInbox)
	g.GET("/pending", h.GetPendingIncoming)
	g.GET("/outbox", h.GetOutbox)
	g.GET("/:id", h.GetLetterByID)
	g.GET("/open/:name", h.GetOpenLetters)
}

func getUserID(c echo.Context) string {
	return c.Request().Header.Get("X-User-ID")
}

type SendLetterRequest struct {
	RecipientUsername         string `json:"recipient_username"`
	RecipientNameUnregistered string `json:"recipient_name_unregistered"`
	Subject                   string `json:"subject"`
	Content                   string `json:"content"`
	DeliveryDelaySeconds      int64  `json:"delivery_delay_seconds"`
}

func (h *handler) SendLetter(c echo.Context) error {
	userID := getUserID(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, echo.Map{"error": "X-User-ID header required"})
	}

	var req SendLetterRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, echo.Map{"error": "Invalid request body"})
	}

	delay := time.Duration(req.DeliveryDelaySeconds) * time.Second
	letter, err := h.svc.SendLetter(
		c.Request().Context(),
		userID,
		req.RecipientUsername,
		req.RecipientNameUnregistered,
		req.Subject,
		req.Content,
		delay,
	)
	if err != nil {
		if errors.Is(err, ErrInvalidInput) || errors.Is(err, ErrUserNotFound) {
			return c.JSON(http.StatusBadRequest, echo.Map{"error": err.Error()})
		}
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": err.Error()})
	}

	return c.JSON(http.StatusCreated, letter)
}

func (h *handler) GetInbox(c echo.Context) error {
	userID := getUserID(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, echo.Map{"error": "X-User-ID header required"})
	}

	letters, err := h.svc.GetInbox(c.Request().Context(), userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, letters)
}

func (h *handler) GetPendingIncoming(c echo.Context) error {
	userID := getUserID(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, echo.Map{"error": "X-User-ID header required"})
	}

	pending, err := h.svc.GetPendingIncoming(c.Request().Context(), userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, pending)
}

func (h *handler) GetOutbox(c echo.Context) error {
	userID := getUserID(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, echo.Map{"error": "X-User-ID header required"})
	}

	letters, err := h.svc.GetOutbox(c.Request().Context(), userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, letters)
}

func (h *handler) GetLetterByID(c echo.Context) error {
	userID := getUserID(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, echo.Map{"error": "X-User-ID header required"})
	}

	letterID := c.Param("id")
	letter, err := h.svc.GetLetterByID(c.Request().Context(), letterID, userID)
	if err != nil {
		if errors.Is(err, ErrLetterNotFound) {
			return c.JSON(http.StatusNotFound, echo.Map{"error": "Letter not found"})
		}
		if errors.Is(err, ErrLetterUndelivered) {
			return c.JSON(http.StatusForbidden, echo.Map{"error": "Letter is still in transit"})
		}
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, letter)
}

func (h *handler) GetOpenLetters(c echo.Context) error {
	name := c.Param("name")
	letters, err := h.svc.GetOpenLetters(c.Request().Context(), name)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, letters)
}

