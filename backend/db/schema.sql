-- Database schema for SQLite

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    email TEXT UNIQUE,
    password_hash TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS password_resets (
    user_id TEXT NOT NULL,
    token TEXT PRIMARY KEY,
    expires_at DATETIME NOT NULL,
    FOREIGN KEY(user_id) REFERENCES users(id)
);


CREATE TABLE IF NOT EXISTS letters (
    id TEXT PRIMARY KEY,
    sender_id TEXT NOT NULL,
    recipient_id TEXT, -- NULL if addressed to an unregistered user
    recipient_name_unregistered TEXT, -- Name for the open board
    subject TEXT NOT NULL,
    content TEXT NOT NULL,
    delivery_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    read_at DATETIME, -- NULL if not read yet
    FOREIGN KEY(sender_id) REFERENCES users(id),
    FOREIGN KEY(recipient_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS contacts (
    user_id TEXT NOT NULL,
    contact_id TEXT NOT NULL,
    last_interaction_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(user_id, contact_id),
    FOREIGN KEY(user_id) REFERENCES users(id),
    FOREIGN KEY(contact_id) REFERENCES users(id)
);

-- Index for searching unregistered open letters
CREATE INDEX IF NOT EXISTS idx_letters_unregistered ON letters(recipient_name_unregistered) 
WHERE recipient_id IS NULL;

-- Index for scanning delayed letter deliveries
CREATE INDEX IF NOT EXISTS idx_letters_delivery ON letters(delivery_at);
