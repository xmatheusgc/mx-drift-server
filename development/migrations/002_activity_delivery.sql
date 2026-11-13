CREATE TABLE IF NOT EXISTS activity_delivery (
 result_id CHAR(36) NOT NULL PRIMARY KEY,
 processed BOOLEAN NOT NULL DEFAULT 0,
 FOREIGN KEY(result_id) REFERENCES activity_results(id)
) ENGINE=InnoDB;
INSERT IGNORE INTO activity_delivery(result_id) SELECT id FROM activity_results;
