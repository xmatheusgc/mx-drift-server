ALTER TABLE player_progression ADD COLUMN IF NOT EXISTS selected_icon VARCHAR(32) NOT NULL DEFAULT 'auto';
ALTER TABLE player_progression ADD COLUMN IF NOT EXISTS selected_title VARCHAR(32) NOT NULL DEFAULT 'novato';
UPDATE player_preferences SET document=JSON_REMOVE(document,'$.icon','$.title');
