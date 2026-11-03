-- BinerMention additive features migration (MariaDB / MySQL 8+)
-- Back up the database before applying. Safe to run once on an existing installation.
CREATE TABLE IF NOT EXISTS analytics_events (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
 actor_user_id BIGINT UNSIGNED NOT NULL,
 owner_user_id BIGINT UNSIGNED NOT NULL,
 post_id BIGINT UNSIGNED NOT NULL,
 event_type ENUM('post_view','post_dwell') NOT NULL,
 dwell_ms INT UNSIGNED NOT NULL DEFAULT 0,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (id), KEY idx_analytics_owner_date (owner_user_id,created_at), KEY idx_analytics_post_event (post_id,event_type,created_at),
 CONSTRAINT fk_analytics_actor FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE CASCADE,
 CONSTRAINT fk_analytics_owner FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE,
 CONSTRAINT fk_analytics_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS bm_groups (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
 title VARCHAR(80) NOT NULL,
 description VARCHAR(500) NOT NULL DEFAULT '',
 invite_code CHAR(16) NOT NULL,
 created_by BIGINT UNSIGNED NOT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (id), UNIQUE KEY uq_bm_groups_invite (invite_code), KEY idx_bm_groups_updated (updated_at),
 CONSTRAINT fk_bm_groups_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS group_members (
 group_id BIGINT UNSIGNED NOT NULL,
 user_id BIGINT UNSIGNED NOT NULL,
 role ENUM('owner','admin','member') NOT NULL DEFAULT 'member',
 joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (group_id,user_id), KEY idx_group_members_user (user_id,group_id),
 CONSTRAINT fk_group_members_group FOREIGN KEY (group_id) REFERENCES bm_groups(id) ON DELETE CASCADE,
 CONSTRAINT fk_group_members_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS group_messages (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
 group_id BIGINT UNSIGNED NOT NULL,
 sender_id BIGINT UNSIGNED NOT NULL,
 body VARCHAR(4000) NOT NULL DEFAULT '',
 media_id BIGINT UNSIGNED NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (id), KEY idx_group_messages_timeline (group_id,id),
 CONSTRAINT fk_group_messages_group FOREIGN KEY (group_id) REFERENCES bm_groups(id) ON DELETE CASCADE,
 CONSTRAINT fk_group_messages_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
 CONSTRAINT fk_group_messages_media FOREIGN KEY (media_id) REFERENCES media(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
