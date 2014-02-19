CREATE TABLE IF NOT EXISTS `superban` (
  `banid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sid` varchar(64) COLLATE utf8_bin NOT NULL DEFAULT '',
  `ip` varchar(64) COLLATE utf8_bin NOT NULL DEFAULT '',
  `ipcookie` varchar(64) COLLATE utf8_bin NOT NULL DEFAULT '',
  `uid` varchar(64) COLLATE utf8_bin NOT NULL DEFAULT '',
  `banname` varchar(64) COLLATE utf8_bin NOT NULL DEFAULT '',
  `name` varchar(64) COLLATE utf8_bin NOT NULL DEFAULT '',
  `admin` varchar(64) COLLATE utf8_bin NOT NULL DEFAULT '',
  `reason` varchar(255) COLLATE utf8_bin NOT NULL DEFAULT '',
  `time` int(11) NOT NULL,
  `bantime` int(11) NOT NULL,
  `unbantime` int(11) NOT NULL,
  PRIMARY KEY (`banid`),
  KEY `sid` (`sid`),
  KEY `ip` (`ip`),
  KEY `ipcookie` (`ipcookie`),
  KEY `uid` (`uid`),
  KEY `banname` (`banname`),
  KEY `name` (`name`),
  KEY `unbantime` (`unbantime`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_bin AUTO_INCREMENT=28 ;