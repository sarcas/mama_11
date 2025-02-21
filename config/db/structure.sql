CREATE TABLE `schema_migrations`(`filename` varchar(255) NOT NULL PRIMARY KEY);
CREATE TABLE `teammates`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `name` text NOT NULL
);
INSERT INTO schema_migrations (filename) VALUES
('20250220164242_create_teammates.rb');
