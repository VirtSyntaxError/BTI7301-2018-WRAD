USE wrad;

CREATE TABLE WRADUser
(
  ObjectGUID VARCHAR(36) NOT NULL,
  SAMAccountName VARCHAR(104) NOT NULL,
  DistinguishedName VARCHAR(2048) NOT NULL,
  LastLogonTimestamp TIMESTAMP DEFAULT NULL,
  userPrincipalName VARCHAR(1024),
  DisplayName VARCHAR(256) NOT NULL,
  CreatedDate TIMESTAMP,
  LastModifiedDate TIMESTAMP,
  Enabled BOOLEAN NOT NULL,
  Description TEXT,
  Expired BOOLEAN NOT NULL,
  PRIMARY KEY (ObjectGUID)
);

CREATE TABLE WRADUserArchive
(
  ArchiveID INT NOT NULL AUTO_INCREMENT,
  userPrincipalName VARCHAR(1024),
  SAMAccountName VARCHAR(104) NOT NULL,
  DistinguishedName VARCHAR(2048) NOT NULL,
  ObjectGUID VARCHAR(36) NOT NULL,
  OperationType ENUM('u','d'),
  VersionStartTime TIMESTAMP,
  VersionEndTime TIMESTAMP,
  DisplayName VARCHAR(256) NOT NULL,
  Description TEXT,
  Enabled BOOLEAN NOT NULL,
  Expired BOOLEAN NOT NULL,
  PRIMARY KEY (ArchiveID)
);

CREATE TABLE WRADGroup
(
  ObjectGUID VARCHAR(36) NOT NULL,
  CreatedDate TIMESTAMP,
  LastModifiedDate TIMESTAMP,
  SAMAccountName VARCHAR(104) NOT NULL,
  GroupType ENUM('ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP','ADS_GROUP_TYPE_GLOBAL_GROUP','ADS_GROUP_TYPE_UNIVERSAL_GROUP') NOT NULL,
  GroupTypeSecurity BOOLEAN,
  CommonName VARCHAR(256) NOT NULL,
  DistinguishedName VARCHAR(2048) NOT NULL,
  Description TEXT,
  PRIMARY KEY (ObjectGUID)
);

CREATE TABLE WRADUserGroup
(
  CreatedDate DATETIME,
  UserObjectGUID VARCHAR(36) NOT NULL,
  GroupObjectGUID VARCHAR(36) NOT NULL,
  PRIMARY KEY (UserObjectGUID, GroupObjectGUID),
  FOREIGN KEY (UserObjectGUID) REFERENCES WRADUser(ObjectGUID),
  FOREIGN KEY (GroupObjectGUID) REFERENCES WRADGroup(ObjectGUID)
);

CREATE TABLE WRADGroupGroup
(
  CreatedDate DATETIME,
  ChildGroup VARCHAR(36) NOT NULL,
  ParentGroup VARCHAR(36) NOT NULL,
  PRIMARY KEY (ChildGroup, ParentGroup),
  FOREIGN KEY (ChildGroup) REFERENCES WRADGroup(ObjectGUID),
  FOREIGN KEY (ParentGroup) REFERENCES WRADGroup(ObjectGUID)
);

CREATE TABLE WRADUserGroupArchive
(
  UserObjectGUID VARCHAR(36) NOT NULL,
  GroupObjectGUID VARCHAR(36) NOT NULL,
  VersionStartTime TIMESTAMP,
  VersionEndTime TIMESTAMP,
  ArchiveID INT NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (ArchiveID)
);

CREATE TABLE WRADGroupArchive
(
  ArchiveID INT NOT NULL AUTO_INCREMENT,
  ObjectGUID VARCHAR(36) NOT NULL,
  CommonName VARCHAR(256) NOT NULL,
  SAMAccountName VARCHAR(104) NOT NULL,
  GroupType ENUM('ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP','ADS_GROUP_TYPE_GLOBAL_GROUP','ADS_GROUP_TYPE_UNIVERSAL_GROUP') NOT NULL,
  GroupTypeSecurity BOOLEAN,
  VersionStartTime TIMESTAMP,
  OperationType ENUM('u','d'),
  VersionEndTime TIMESTAMP,
  DistinguishedName VARCHAR(2048) NOT NULL,
  Description TEXT,
  PRIMARY KEY (ArchiveID)
);

CREATE TABLE WRADGroupGroupArchive
(
  ArchiveID INT NOT NULL AUTO_INCREMENT,
  ParentGroup VARCHAR(36) NOT NULL,
  ChildGroup VARCHAR(36) NOT NULL,
  VersionStartTime TIMESTAMP,
  VersionEndTime TIMESTAMP,
  PRIMARY KEY (ArchiveID)
);

CREATE TABLE WRADSettings
(
  SettingID INT NOT NULL AUTO_INCREMENT,
  ADSyncIntervalInHours INT NOT NULL,
  PRIMARY KEY (SettingID)
);

CREATE TABLE WRADExcludeUser
(
  ExcludeID INT NOT NULL AUTO_INCREMENT,
  ObjectGUID VARCHAR(36) NOT NULL,
  PRIMARY KEY (SettingID),
  FOREIGN KEY (ObjectGUID) REFERENCES WRADUser(ObjectGUID)	
);


CREATE TABLE WRADExcludeGroup
(
  ExcludeID INT NOT NULL AUTO_INCREMENT,
  ObjectGUID VARCHAR(36) NOT NULL,
  PRIMARY KEY (SettingID),
  FOREIGN KEY (ObjectGUID) REFERENCES WRADGroup(ObjectGUID)	
);

DELIMITER $$
CREATE TRIGGER UserInsert
  BEFORE INSERT ON WRADUser
  FOR EACH ROW BEGIN
	SET NEW.LastModifiedDate = UTC_TIMESTAMP(),NEW.CreatedDate = UTC_TIMESTAMP();
 END$$ DELIMITER;

DELIMITER $$
CREATE TRIGGER UserDelete
  AFTER DELETE ON WRADUser
  FOR EACH ROW BEGIN
	INSERT INTO WRADUserArchive (ObjectGUID,SAMAccountName,DistinguishedName,userPrincipalName,DisplayName,Enabled,Description,Expired,OperationType,VersionStartTime,VersionEndTime) VALUES (OLD.ObjectGUID, OLD.SAMAccountName, OLD.DistinguishedName,OLD.userPrincipalName,OLD.DisplayName,OLD.Enabled,OLD.Description,OLD.Expired,'d',OLD.LastModifiedDate,UTC_TIMESTAMP());
 END$$ DELIMITER;

DELIMITER $$
CREATE TRIGGER UserUpdateBefore
  BEFORE UPDATE ON WRADUser
  FOR EACH ROW BEGIN
	IF NEW.SAMAccountName != OLD.SAMAccountName OR NEW.DistinguishedName != OLD.DistinguishedName OR NEW.userPrincipalName != OLD.userPrincipalName OR NEW.DisplayName != OLD.DisplayName OR NEW.Enabled != OLD.Enabled OR NEW.Description != OLD.Description OR NEW.Expired != OLD.Expired
	THEN 
	SET NEW.LastModifiedDate = UTC_TIMESTAMP();
	END IF;
 END$$ DELIMITER;

DELIMITER $$
CREATE TRIGGER UserUpdateAfter
  AFTER UPDATE ON WRADUser
  FOR EACH ROW
    BEGIN
  	IF NEW.SAMAccountName != OLD.SAMAccountName OR NEW.DistinguishedName != OLD.DistinguishedName OR NEW.userPrincipalName != OLD.userPrincipalName OR NEW.DisplayName != OLD.DisplayName OR NEW.Enabled != OLD.Enabled OR NEW.Description != OLD.Description OR NEW.Expired != OLD.Expired
	THEN 
	INSERT INTO WRADUserArchive (ObjectGUID,SAMAccountName,DistinguishedName,userPrincipalName,DisplayName,Enabled,Description,Expired,OperationType,VersionStartTime,VersionEndTime) VALUES (OLD.ObjectGUID, OLD.SAMAccountName, OLD.DistinguishedName,OLD.userPrincipalName,OLD.DisplayName,OLD.Enabled,OLD.Description,OLD.Expired,'u',OLD.LastModifiedDate,UTC_TIMESTAMP());
  END IF;
END$$ DELIMITER;

DELIMITER $$
CREATE TRIGGER GroupInsert
  BEFORE INSERT ON WRADGroup
  FOR EACH ROW BEGIN
	SET NEW.LastModifiedDate = UTC_TIMESTAMP(),NEW.CreatedDate = UTC_TIMESTAMP();
 END$$ DELIMITER;

DELIMITER $$
CREATE TRIGGER GroupDelete
  AFTER DELETE ON WRADGroup
  FOR EACH ROW BEGIN
	INSERT INTO WRADGroupArchive (ObjectGUID,SAMAccountName,DistinguishedName,CommonName,Description,GroupType,GroupTypeSecurity,OperationType,VersionStartTime,VersionEndTime) VALUES (OLD.ObjectGUID, OLD.SAMAccountName, OLD.DistinguishedName,OLD.CommonName,OLD.Description,OLD.GroupType,OLD.GroupTypeSecurity,'d',OLD.LastModifiedDate,UTC_TIMESTAMP());
 END$$ DELIMITER;

DELIMITER $$
CREATE TRIGGER GroupUpdateBefore
  BEFORE UPDATE ON WRADGroup
  FOR EACH ROW BEGIN
	SET NEW.LastModifiedDate = UTC_TIMESTAMP();
 END$$ DELIMITER;

DELIMITER $$
CREATE TRIGGER GroupUpdateAfter
  AFTER UPDATE ON WRADGroup
  FOR EACH ROW BEGIN
	INSERT INTO WRADGroupArchive (ObjectGUID,SAMAccountName,DistinguishedName,CommonName,Description,GroupType,GroupTypeSecurity,OperationType,VersionStartTime,VersionEndTime) VALUES (OLD.ObjectGUID, OLD.SAMAccountName, OLD.DistinguishedName,OLD.CommonName,OLD.Description,OLD.GroupType,OLD.GroupTypeSecurity,'u',OLD.LastModifiedDate,UTC_TIMESTAMP());
 END$$ DELIMITER;


