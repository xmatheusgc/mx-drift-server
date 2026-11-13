CREATE TABLE IF NOT EXISTS player_friendships (
 low_player_id BIGINT UNSIGNED NOT NULL,
 high_player_id BIGINT UNSIGNED NOT NULL,
 requested_by BIGINT UNSIGNED NOT NULL,
 status ENUM('pending','accepted') NOT NULL DEFAULT 'pending',
 created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 accepted_at TIMESTAMP(3) NULL,
 PRIMARY KEY(low_player_id,high_player_id),
 INDEX friend_high(high_player_id,status),
 FOREIGN KEY(low_player_id) REFERENCES players(id) ON DELETE CASCADE,
 FOREIGN KEY(high_player_id) REFERENCES players(id) ON DELETE CASCADE,
 FOREIGN KEY(requested_by) REFERENCES players(id) ON DELETE CASCADE,
 CHECK(low_player_id<high_player_id),
 CHECK(requested_by=low_player_id OR requested_by=high_player_id)
) ENGINE=InnoDB;
