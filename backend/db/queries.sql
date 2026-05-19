-- name: GetUserByID :one
SELECT * FROM users
WHERE id = ? LIMIT 1;

-- name: GetUserByUsername :one
SELECT * FROM users
WHERE username = ? LIMIT 1;

-- name: CreateUser :one
INSERT INTO users (id, username)
VALUES (?, ?)
RETURNING *;

-- name: CreateLetter :one
INSERT INTO letters (id, sender_id, recipient_id, recipient_name_unregistered, subject, content, delivery_at)
VALUES (?, ?, ?, ?, ?, ?, ?)
RETURNING *;

-- name: GetLetterByID :one
SELECT * FROM letters
WHERE id = ? LIMIT 1;

-- name: GetInbox :many
SELECT id, sender_id, recipient_id, recipient_name_unregistered, subject, content, delivery_at, created_at
FROM letters
WHERE recipient_id = ? AND delivery_at <= ?
ORDER BY delivery_at DESC;

-- name: GetPendingIncoming :many
-- Retrieve metadata for incoming letters that are still in transit (content is NOT returned)
SELECT id, sender_id, recipient_id, subject, delivery_at, created_at
FROM letters
WHERE recipient_id = ? AND delivery_at > ?
ORDER BY delivery_at ASC;

-- name: GetOutbox :many
SELECT * FROM letters
WHERE sender_id = ?
ORDER BY created_at DESC;

-- name: GetOpenLettersForUnregistered :many
SELECT id, sender_id, recipient_name_unregistered, subject, content, delivery_at, created_at
FROM letters
WHERE recipient_id IS NULL 
  AND recipient_name_unregistered = ? 
  AND delivery_at <= ?
ORDER BY delivery_at DESC;

-- name: UpsertContact :exec
INSERT INTO contacts (user_id, contact_id, last_interaction_at)
VALUES (?, ?, ?)
ON CONFLICT(user_id, contact_id) DO UPDATE SET
last_interaction_at = excluded.last_interaction_at;

-- name: GetContactsWithLastLetterMetadata :many
SELECT 
    c.contact_id,
    u.username AS contact_username,
    c.last_interaction_at,
    l.id AS last_letter_id,
    l.sender_id AS last_letter_sender_id,
    l.delivery_at AS last_letter_delivery_at,
    l.created_at AS last_letter_created_at
FROM contacts c
JOIN users u ON c.contact_id = u.id
LEFT JOIN letters l ON l.id = (
    SELECT id FROM letters 
    WHERE (sender_id = c.user_id AND recipient_id = c.contact_id)
       OR (sender_id = c.contact_id AND recipient_id = c.user_id)
    ORDER BY created_at DESC 
    LIMIT 1
)
WHERE c.user_id = ?;
