-- BinerMention cross-platform features: quote posts, profile pinning, post reports.
-- Run once against the existing database after taking a backup.
ALTER TABLE posts
  ADD COLUMN quote_post_id BIGINT UNSIGNED NULL AFTER reply_to_id,
  ADD KEY idx_posts_quote (quote_post_id),
  ADD CONSTRAINT fk_posts_quote FOREIGN KEY (quote_post_id) REFERENCES posts(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS pinned_posts (
  user_id BIGINT UNSIGNED NOT NULL,
  post_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_pinned_post (post_id),
  CONSTRAINT fk_pinned_posts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_pinned_posts_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS post_reports (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  reporter_user_id BIGINT UNSIGNED NOT NULL,
  post_id BIGINT UNSIGNED NOT NULL,
  reported_user_id BIGINT UNSIGNED NOT NULL,
  reason VARCHAR(500) NOT NULL,
  status ENUM('pending','reviewed','dismissed') NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_post_reporter (reporter_user_id, post_id),
  KEY idx_post_reports_status (status, created_at),
  KEY idx_post_reports_post (post_id, created_at),
  CONSTRAINT fk_post_reports_reporter FOREIGN KEY (reporter_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_post_reports_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  CONSTRAINT fk_post_reports_owner FOREIGN KEY (reported_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
