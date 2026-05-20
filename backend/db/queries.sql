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
SELECT 
    l.id,
    l.sender_id,
    su.username AS sender_username,
    l.recipient_id,
    ru.username AS recipient_username,
    l.recipient_name_unregistered,
    l.subject,
    l.content,
    l.delivery_at,
    l.created_at,
    l.read_at
FROM letters l
JOIN users su ON l.sender_id = su.id
LEFT JOIN users ru ON l.recipient_id = ru.id
WHERE l.id = ? LIMIT 1;

-- name: MarkLetterAsRead :exec
UPDATE letters
SET read_at = ?
WHERE id = ? AND read_at IS NULL;

-- name: GetInbox :many
SELECT 
    l.id, 
    l.sender_id, 
    u.username AS sender_username,
    l.recipient_id, 
    l.recipient_name_unregistered, 
    l.subject, 
    l.content, 
    l.delivery_at, 
    l.created_at,
    l.read_at
FROM letters l
JOIN users u ON l.sender_id = u.id
WHERE l.recipient_id = ? AND l.delivery_at <= ?
ORDER BY l.delivery_at DESC;

-- name: GetPendingIncoming :many
-- Retrieve metadata for incoming letters that are still in transit (content is NOT returned)
SELECT 
    l.id, 
    l.sender_id, 
    u.username AS sender_username,
    l.recipient_id, 
    l.subject, 
    l.delivery_at, 
    l.created_at
FROM letters l
JOIN users u ON l.sender_id = u.id
WHERE l.recipient_id = ? AND l.delivery_at > ?
ORDER BY l.delivery_at ASC;

-- name: GetOutbox :many
SELECT 
    l.id,
    l.sender_id,
    l.recipient_id,
    u.username AS recipient_username,
    l.recipient_name_unregistered,
    l.subject,
    l.content,
    l.delivery_at,
    l.created_at,
    l.read_at
FROM letters l
LEFT JOIN users u ON l.recipient_id = u.id
WHERE l.sender_id = ?
ORDER BY l.created_at DESC;

-- name: GetOpenLettersForUnregistered :many
SELECT 
    l.id, 
    l.sender_id, 
    u.username AS sender_username,
    l.recipient_name_unregistered, 
    l.subject, 
    l.content, 
    l.delivery_at, 
    l.created_at,
    l.read_at
FROM letters l
JOIN users u ON l.sender_id = u.id
WHERE l.recipient_id IS NULL 
  AND l.recipient_name_unregistered = ? 
  AND l.delivery_at <= ?
ORDER BY l.delivery_at DESC;

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
