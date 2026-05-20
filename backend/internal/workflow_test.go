package internal

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"testing"
	"time"

	"github.com/labstack/echo/v4"
	_ "github.com/mattn/go-sqlite3"

	"ilkf_backend/internal/auth"
	"ilkf_backend/internal/contacts"
	"ilkf_backend/internal/db"
	"ilkf_backend/internal/letters"
)

// Helper function to start the live test server on a random port
func startTestServer(t *testing.T, dbPath string) (string, func()) {
	// Clean up any old files
	_ = os.Remove(dbPath)
	_ = os.Remove(dbPath + "-shm")
	_ = os.Remove(dbPath + "-wal")

	// Open connection
	dbConn, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		t.Fatalf("failed to open database: %v", err)
	}

	// Execute schema migrations
	schemaPath := filepath.Join("..", "db", "schema.sql")
	schemaBytes, err := os.ReadFile(schemaPath)
	if err != nil {
		t.Fatalf("failed to read schema.sql: %v", err)
	}

	if _, err := dbConn.Exec(string(schemaBytes)); err != nil {
		t.Fatalf("failed to execute schema: %v", err)
	}

	queries := db.New(dbConn)

	// Create Echo app
	e := echo.New()
	e.HideBanner = true
	e.HidePort = true

	apiGroup := e.Group("/api")

	// Wire auth feature
	authSvc := auth.NewService(queries)
	authHandler := auth.NewHandler(authSvc)
	authHandler.RegisterRoutes(apiGroup)

	// Wire letters feature
	lettersSvc := letters.NewService(dbConn)
	lettersHandler := letters.NewHandler(lettersSvc)
	lettersHandler.RegisterRoutes(apiGroup.Group("/letters"))

	// Wire contacts feature
	contactsSvc := contacts.NewService(queries)
	contactsHandler := contacts.NewHandler(contactsSvc)
	contactsHandler.RegisterRoutes(apiGroup.Group("/contacts"))

	// Listen on a random available port
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("failed to listen on port 0: %v", err)
	}
	addr := listener.Addr().String()

	e.Listener = listener

	// Start Echo server in a separate goroutine
	go func() {
		_ = e.Start("")
	}()

	cleanup := func() {
		_ = e.Close()
		_ = dbConn.Close()
		_ = os.Remove(dbPath)
		_ = os.Remove(dbPath + "-shm")
		_ = os.Remove(dbPath + "-wal")
	}

	return "http://" + addr, cleanup
}

// JSON request runner helper
func doJSONRequest(t *testing.T, method, url string, body interface{}, headers map[string]string) (int, []byte) {
	var bodyReader io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			t.Fatalf("failed to marshal request body: %v", err)
		}
		bodyReader = bytes.NewReader(data)
	}

	req, err := http.NewRequest(method, url, bodyReader)
	if err != nil {
		t.Fatalf("failed to create http request: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")
	for k, v := range headers {
		req.Header.Set(k, v)
	}

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("failed to perform request to %s: %v", url, err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("failed to read response body: %v", err)
	}

	return resp.StatusCode, respBody
}

func TestEndToEndAPIWorkflow(t *testing.T) {
	serverURL, cleanup := startTestServer(t, "workflow_test.db")
	defer cleanup()

	// Ensure any old postmaster emails are cleared before test
	os.Remove("/Users/daliborpovolny/coding/ilkf/last_reset_email.txt")

	ctx := context.Background()
	_ = ctx // unused, but here for structural consistency

	// ==========================================
	// 1. REGISTER ALICE & BOB
	// ==========================================
	aliceRegBody := map[string]string{
		"username": "alice",
		"email":    "alice@ilkf.local",
		"password": "alicepassword",
	}
	code, body := doJSONRequest(t, "POST", serverURL+"/api/auth/register", aliceRegBody, nil)
	if code != http.StatusCreated {
		t.Fatalf("expected 201 Created for Alice register, got %d. Body: %s", code, string(body))
	}

	var aliceUser struct {
		ID       string `json:"id"`
		Username string `json:"username"`
	}
	if err := json.Unmarshal(body, &aliceUser); err != nil {
		t.Fatalf("failed to unmarshal alice registration response: %v", err)
	}

	bobRegBody := map[string]string{
		"username": "bob",
		"email":    "bob@ilkf.local",
		"password": "bobpassword",
	}
	code, body = doJSONRequest(t, "POST", serverURL+"/api/auth/register", bobRegBody, nil)
	if code != http.StatusCreated {
		t.Fatalf("expected 201 Created for Bob register, got %d. Body: %s", code, string(body))
	}

	var bobUser struct {
		ID       string `json:"id"`
		Username string `json:"username"`
	}
	if err := json.Unmarshal(body, &bobUser); err != nil {
		t.Fatalf("failed to unmarshal bob registration response: %v", err)
	}

	// ==========================================
	// 2. LOGIN VERIFICATION
	// ==========================================
	aliceLoginBody := map[string]string{
		"username_or_email": "alice@ilkf.local",
		"password":          "alicepassword",
	}
	code, body = doJSONRequest(t, "POST", serverURL+"/api/auth/login", aliceLoginBody, nil)
	if code != http.StatusOK {
		t.Fatalf("expected 200 OK for Alice login, got %d", code)
	}

	bobLoginBody := map[string]string{
		"username_or_email": "bob",
		"password":          "bobpassword",
	}
	code, body = doJSONRequest(t, "POST", serverURL+"/api/auth/login", bobLoginBody, nil)
	if code != http.StatusOK {
		t.Fatalf("expected 200 OK for Bob login, got %d", code)
	}

	// ==========================================
	// 3. ALICE SENDS A DELAYED LETTER TO BOB
	// ==========================================
	sendLetterBody := map[string]interface{}{
		"recipient_username":          "bob",
		"recipient_name_unregistered": "",
		"subject":                     "Dearest Bob",
		"content":                     "The wind blows cold across the parchment page.",
		"delivery_delay_seconds":      2,
	}
	code, body = doJSONRequest(t, "POST", serverURL+"/api/letters", sendLetterBody, map[string]string{"X-User-ID": aliceUser.ID})
	if code != http.StatusCreated {
		t.Fatalf("expected 201 Created for SendLetter, got %d. Body: %s", code, string(body))
	}

	var createdLetter struct {
		ID string `json:"id"`
	}
	if err := json.Unmarshal(body, &createdLetter); err != nil {
		t.Fatalf("failed to unmarshal created letter: %v", err)
	}

	// ==========================================
	// 4. CHECK ALICE'S OUTBOX
	// ==========================================
	code, body = doJSONRequest(t, "GET", serverURL+"/api/letters/outbox", nil, map[string]string{"X-User-ID": aliceUser.ID})
	if code != http.StatusOK {
		t.Fatalf("expected 200 OK for outbox request, got %d", code)
	}

	var outboxList []struct {
		ID      string      `json:"id"`
		Subject string      `json:"subject"`
		ReadAt  interface{} `json:"read_at"`
	}
	if err := json.Unmarshal(body, &outboxList); err != nil {
		t.Fatalf("failed to parse outbox list: %v", err)
	}
	if len(outboxList) != 1 || outboxList[0].ID != createdLetter.ID {
		t.Fatalf("expected Alice's outbox to contain exactly 1 letter with ID %s, got %v", createdLetter.ID, outboxList)
	}
	if outboxList[0].ReadAt != nil {
		t.Fatalf("expected letter to be unread initially, got read_at: %v", outboxList[0].ReadAt)
	}

	// ==========================================
	// 5. BOB CHECKS INBOX BEFORE 2 SECONDS (Empty)
	// ==========================================
	code, body = doJSONRequest(t, "GET", serverURL+"/api/letters/inbox", nil, map[string]string{"X-User-ID": bobUser.ID})
	if code != http.StatusOK {
		t.Fatalf("expected 200 OK for Bob's inbox request, got %d", code)
	}

	var inboxList []interface{}
	if err := json.Unmarshal(body, &inboxList); err != nil {
		t.Fatalf("failed to parse Bob's inbox list: %v", err)
	}
	if len(inboxList) != 0 {
		t.Fatalf("expected Bob's inbox to be empty before delivery timer, got: %d items", len(inboxList))
	}

	// ==========================================
	// 6. BOB CHECKS PENDING (1 En-Route Carrier)
	// ==========================================
	code, body = doJSONRequest(t, "GET", serverURL+"/api/letters/pending", nil, map[string]string{"X-User-ID": bobUser.ID})
	if code != http.StatusOK {
		t.Fatalf("expected 200 OK for Bob's pending carriers request, got %d", code)
	}

	var pendingList []struct {
		ID      string `json:"id"`
		Subject string `json:"subject"`
	}
	if err := json.Unmarshal(body, &pendingList); err != nil {
		t.Fatalf("failed to parse Bob's pending list: %v", err)
	}
	if len(pendingList) != 1 || pendingList[0].ID != createdLetter.ID {
		t.Fatalf("expected 1 pending letter for Bob, got: %v", pendingList)
	}

	// ==========================================
	// 7. WAIT FOR TRANSIT CARRIER
	// ==========================================
	time.Sleep(2500 * time.Millisecond)

	// ==========================================
	// 8. BOB CHECKS INBOX AFTER 2 SECONDS (Delivered)
	// ==========================================
	code, body = doJSONRequest(t, "GET", serverURL+"/api/letters/inbox", nil, map[string]string{"X-User-ID": bobUser.ID})
	if code != http.StatusOK {
		t.Fatalf("expected 200 OK for Bob's inbox, got %d", code)
	}

	var inboxListAfter []struct {
		ID      string      `json:"id"`
		Subject string      `json:"subject"`
		ReadAt  interface{} `json:"read_at"`
	}
	if err := json.Unmarshal(body, &inboxListAfter); err != nil {
		t.Fatalf("failed to parse Bob's inbox list: %v", err)
	}
	if len(inboxListAfter) != 1 || inboxListAfter[0].ID != createdLetter.ID {
		t.Fatalf("expected Bob's inbox to contain exactly 1 letter with ID %s, got: %v", createdLetter.ID, inboxListAfter)
	}
	if inboxListAfter[0].ReadAt != nil {
		t.Fatalf("expected inbox letter to show unread, got: %v", inboxListAfter[0].ReadAt)
	}

	// ==========================================
	// 9. BOB READS THE LETTER (Triggers Receipt)
	// ==========================================
	code, body = doJSONRequest(t, "GET", serverURL+"/api/letters/"+createdLetter.ID, nil, map[string]string{"X-User-ID": bobUser.ID})
	if code != http.StatusOK {
		t.Fatalf("expected 200 OK when Bob reads letter, got %d. Body: %s", code, string(body))
	}

	var readLetter struct {
		ID     string      `json:"id"`
		ReadAt interface{} `json:"read_at"`
	}
	if err := json.Unmarshal(body, &readLetter); err != nil {
		t.Fatalf("failed to unmarshal read letter details: %v", err)
	}
	if readLetter.ReadAt == nil {
		t.Fatal("expected letter to be marked read in the returned model")
	}

	// ==========================================
	// 10. ALICE VERIFIES READ-RECEIPT STATUS
	// ==========================================
	code, body = doJSONRequest(t, "GET", serverURL+"/api/letters/outbox", nil, map[string]string{"X-User-ID": aliceUser.ID})
	if code != http.StatusOK {
		t.Fatalf("expected 200 OK for Alice outbox check, got %d", code)
	}

	var outboxListAfter []struct {
		ID     string      `json:"id"`
		ReadAt interface{} `json:"read_at"`
	}
	if err := json.Unmarshal(body, &outboxListAfter); err != nil {
		t.Fatalf("failed to parse outbox list: %v", err)
	}
	if outboxListAfter[0].ReadAt == nil {
		t.Fatal("expected Alice's outbox to show the letter has been read by Bob")
	}

	// ==========================================
	// 11. PASSWORD RESET FLOW E2E
	// ==========================================
	forgotBody := map[string]string{"email": "alice@ilkf.local"}
	code, body = doJSONRequest(t, "POST", serverURL+"/api/auth/forgot-password", forgotBody, nil)
	if code != http.StatusOK {
		t.Fatalf("expected 200 OK for forgot-password, got %d. Body: %s", code, string(body))
	}

	// Read last_reset_email.txt from workspace root
	emailFilePath := "/Users/daliborpovolny/coding/ilkf/last_reset_email.txt"
	emailBytes, err := os.ReadFile(emailFilePath)
	if err != nil {
		t.Fatalf("failed to read mock email file at %s: %v", emailFilePath, err)
	}

	// Extract reset token UUID using regex
	re := regexp.MustCompile(`Token: ([a-f0-9\-]+)`)
	matches := re.FindStringSubmatch(string(emailBytes))
	if len(matches) < 2 {
		t.Fatalf("could not extract token from mock email:\n%s", string(emailBytes))
	}
	resetToken := matches[1]

	// Reset password with token
	resetBody := map[string]string{
		"token":        resetToken,
		"new_password": "alicenewpassword",
	}
	code, body = doJSONRequest(t, "POST", serverURL+"/api/auth/reset-password", resetBody, nil)
	if code != http.StatusOK {
		t.Fatalf("expected 200 OK for reset-password, got %d. Body: %s", code, string(body))
	}

	// Old login fails
	code, body = doJSONRequest(t, "POST", serverURL+"/api/auth/login", aliceLoginBody, nil)
	if code != http.StatusUnauthorized {
		t.Fatalf("expected 412/401 Unauthorized for old password, got %d", code)
	}

	// New login succeeds
	aliceNewLoginBody := map[string]string{
		"username_or_email": "alice",
		"password":          "alicenewpassword",
	}
	code, body = doJSONRequest(t, "POST", serverURL+"/api/auth/login", aliceNewLoginBody, nil)
	if code != http.StatusOK {
		t.Fatalf("expected 200 OK for login with new password, got %d. Body: %s", code, string(body))
	}
}
