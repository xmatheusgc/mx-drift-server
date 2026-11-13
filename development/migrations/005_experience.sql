CREATE TABLE IF NOT EXISTS player_experience (
 player_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
 character_completed BOOLEAN NOT NULL DEFAULT 0,
 vehicle_completed BOOLEAN NOT NULL DEFAULT 0,
 selected_id CHAR(36) NULL,
 revision INT NOT NULL DEFAULT 1,
 FOREIGN KEY(player_id) REFERENCES players(id)
) ENGINE=InnoDB;
INSERT IGNORE INTO player_experience(player_id,vehicle_completed) SELECT p.id,EXISTS(SELECT 1 FROM garage_presets g WHERE g.player_id=p.id) FROM players p;
CREATE TABLE IF NOT EXISTS player_appearance (
 player_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
 schema_version INT NOT NULL DEFAULT 1,
 document LONGTEXT NOT NULL CHECK(JSON_VALID(document)),
 revision INT NOT NULL DEFAULT 1,
 FOREIGN KEY(player_id) REFERENCES players(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS experience_operations (
 player_id BIGINT UNSIGNED NOT NULL,
 operation_id CHAR(36) NOT NULL,
 kind VARCHAR(32) NOT NULL,
 result LONGTEXT NOT NULL CHECK(JSON_VALID(result)),
 created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 PRIMARY KEY(player_id,operation_id),
 FOREIGN KEY(player_id) REFERENCES players(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS garage_usage (
 preset_id CHAR(36) NOT NULL PRIMARY KEY,
 used_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
 FOREIGN KEY(preset_id) REFERENCES garage_presets(id) ON DELETE CASCADE
) ENGINE=InnoDB;
