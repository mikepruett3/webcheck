BEGIN TRANSACTION;
CREATE TABLE sites (id INTEGER PRIMARY KEY, md5 TEXT, stamp TEXT, url TEXT);
COMMIT;
