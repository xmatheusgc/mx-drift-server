CREATE TABLE IF NOT EXISTS players (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 identifier VARCHAR(100) NOT NULL UNIQUE,
 name VARCHAR(48) NOT NULL,
 created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 last_seen TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS player_preferences (
 player_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
 schema_version INT NOT NULL DEFAULT 1,
 revision INT NOT NULL DEFAULT 1,
 document LONGTEXT NOT NULL CHECK(JSON_VALID(document)),
 FOREIGN KEY(player_id) REFERENCES players(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS garage_presets (
 id CHAR(36) NOT NULL PRIMARY KEY,
 player_id BIGINT UNSIGNED NOT NULL,
 name VARCHAR(48) NOT NULL,
 model VARCHAR(48) NOT NULL,
 schema_version INT NOT NULL DEFAULT 1,
 revision INT NOT NULL DEFAULT 1,
 properties LONGTEXT NOT NULL CHECK(JSON_VALID(properties)),
 created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 INDEX owner_idx(player_id), FOREIGN KEY(player_id) REFERENCES players(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS player_favorites (
 player_id BIGINT UNSIGNED NOT NULL, catalog_id VARCHAR(48) NOT NULL,
 PRIMARY KEY(player_id,catalog_id), FOREIGN KEY(player_id) REFERENCES players(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS track_versions (
 track_id VARCHAR(48) NOT NULL, revision INT NOT NULL, definition LONGTEXT NOT NULL CHECK(JSON_VALID(definition)),
 active BOOLEAN NOT NULL DEFAULT 0, PRIMARY KEY(track_id,revision)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS activity_results (
 id CHAR(36) NOT NULL PRIMARY KEY, player_id BIGINT UNSIGNED NOT NULL,
 track_id VARCHAR(48) NOT NULL, track_revision INT NOT NULL, direction VARCHAR(16) NOT NULL,
 mode VARCHAR(24) NOT NULL, rules VARCHAR(48) NOT NULL, model VARCHAR(48) NOT NULL,
 signature VARCHAR(255) NOT NULL, conditions VARCHAR(48) NOT NULL,
 duration_ms INT UNSIGNED NOT NULL, distance_m DOUBLE NOT NULL DEFAULT 0,
 eligible BOOLEAN NOT NULL, reason VARCHAR(120), revoked BOOLEAN NOT NULL DEFAULT 0,
 evidence LONGTEXT NOT NULL CHECK(JSON_VALID(evidence)),
 created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 INDEX pending_idx(created_at,id),
 INDEX ranking_idx(track_id,track_revision,mode,model,eligible,revoked,duration_ms),
 INDEX owner_results_idx(player_id,created_at), FOREIGN KEY(player_id) REFERENCES players(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS xp_ledger (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, player_id BIGINT UNSIGNED NOT NULL,
 origin VARCHAR(180) NOT NULL, result_id CHAR(36), delta INT NOT NULL, policy VARCHAR(32) NOT NULL,
 created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 UNIQUE KEY grant_once(player_id,origin), INDEX result_idx(result_id),
 FOREIGN KEY(player_id) REFERENCES players(id), FOREIGN KEY(result_id) REFERENCES activity_results(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS player_progression (
 player_id BIGINT UNSIGNED NOT NULL PRIMARY KEY, xp INT NOT NULL DEFAULT 0, revision INT NOT NULL DEFAULT 1,
 FOREIGN KEY(player_id) REFERENCES players(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS achievement_progress (
 player_id BIGINT UNSIGNED NOT NULL, achievement_id VARCHAR(48) NOT NULL, version INT NOT NULL,
 progress INT NOT NULL DEFAULT 0, granted BOOLEAN NOT NULL DEFAULT 0, result_id CHAR(36),
 PRIMARY KEY(player_id,achievement_id,version), FOREIGN KEY(player_id) REFERENCES players(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS weekly_challenges (
 id VARCHAR(48) NOT NULL PRIMARY KEY, starts_at DATETIME NOT NULL, ends_at DATETIME NOT NULL,
 definition LONGTEXT NOT NULL CHECK(JSON_VALID(definition))
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS challenge_claims (
 player_id BIGINT UNSIGNED NOT NULL, challenge_id VARCHAR(48) NOT NULL, result_id CHAR(36) NOT NULL,
 PRIMARY KEY(player_id,challenge_id), FOREIGN KEY(player_id) REFERENCES players(id),
 FOREIGN KEY(challenge_id) REFERENCES weekly_challenges(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS progression_receipts (
 result_id CHAR(36) NOT NULL PRIMARY KEY, processed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(result_id) REFERENCES activity_results(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS audit_log (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, actor VARCHAR(40) NOT NULL,
 action VARCHAR(48) NOT NULL, target VARCHAR(80), request_id VARCHAR(64), details LONGTEXT NOT NULL CHECK(JSON_VALID(details)),
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX retention_idx(created_at)
) ENGINE=InnoDB;
