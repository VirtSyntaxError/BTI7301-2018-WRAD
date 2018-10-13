USE wrad;

DROP TABLE IF EXISTS WRADGroupGroup;
DROP TABLE IF EXISTS WRADUserGroup;
DROP TABLE IF EXISTS WRADGroupGroupArchive;
DROP TABLE IF EXISTS WRADUserGroupArchive;
DROP TABLE IF EXISTS WRADSetting;
DROP TABLE IF EXISTS WRADExcludeUser;
DROP TABLE IF EXISTS WRADExcludeGroup;
DROP TABLE IF EXISTS WRADUser;
DROP TABLE IF EXISTS WRADUserArchive;
DROP TABLE IF EXISTS WRADGroup;
DROP TABLE IF EXISTS WRADGroupArchive;

CREATE USER 'wradadmin'@'localhost' IDENTIFIED VIA mysql_native_password USING '***';GRANT USAGE ON *.* TO 'wradadmin'@'localhost' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
GRANT ALL PRIVILEGES ON `wrad`.* TO 'wradadmin'@'localhost';


CREATE TABLE WRADUser
(
  ObjectGUID VARCHAR(36) NOT NULL,
  SAMAccountName VARCHAR(104) NOT NULL,
  DistinguishedName VARCHAR(2048) NOT NULL,
  LastLogonTimestamp TIMESTAMP NULL,
  userPrincipalName VARCHAR(1024) NOT NULL,
  DisplayName VARCHAR(256) NOT NULL,
  CreatedDate TIMESTAMP,
  LastModifiedDate TIMESTAMP,
  Enabled BOOLEAN NOT NULL,
  Description TEXT NOT NULL,
  Expired BOOLEAN NOT NULL,
  PRIMARY KEY (ObjectGUID)
);

CREATE TABLE WRADUserArchive
(
  ArchiveID INT NOT NULL AUTO_INCREMENT,
  userPrincipalName VARCHAR(1024) NOT NULL,
  SAMAccountName VARCHAR(104) NOT NULL,
  DistinguishedName VARCHAR(2048) NOT NULL,
  ObjectGUID VARCHAR(36) NOT NULL,
  OperationType ENUM('u','d'),
  VersionStartTime TIMESTAMP,
  VersionEndTime TIMESTAMP,
  DisplayName VARCHAR(256) NOT NULL,
  Description TEXT NOT NULL,
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
  GroupTypeSecurity BOOLEAN NOT NULL,
  CommonName VARCHAR(256) NOT NULL,
  DistinguishedName VARCHAR(2048) NOT NULL,
  Description TEXT NOT NULL,
  PRIMARY KEY (ObjectGUID)
);

CREATE TABLE WRADUserGroup
(
  CreatedDate TIMESTAMP,
  UserObjectGUID VARCHAR(36) NOT NULL,
  GroupObjectGUID VARCHAR(36) NOT NULL,
  PRIMARY KEY (UserObjectGUID, GroupObjectGUID),
  CONSTRAINT `FK_User` FOREIGN KEY (UserObjectGUID) REFERENCES WRADUser(ObjectGUID) ON DELETE CASCADE,
  CONSTRAINT `FK_Group` FOREIGN KEY (GroupObjectGUID) REFERENCES WRADGroup(ObjectGUID)  ON DELETE CASCADE
);

CREATE TABLE WRADGroupGroup
(
  CreatedDate TIMESTAMP,
  ChildGroupObjectGUID VARCHAR(36) NOT NULL,
  ParentGroupObjectGUID VARCHAR(36) NOT NULL,
  PRIMARY KEY (ChildGroupObjectGUID, ParentGroupObjectGUID),
  CONSTRAINT `FK_ChildGroup` FOREIGN KEY (ChildGroupObjectGUID) REFERENCES WRADGroup(ObjectGUID) ON DELETE CASCADE,
  CONSTRAINT `FK_ParentGroup` FOREIGN KEY (ParentGroupObjectGUID) REFERENCES WRADGroup(ObjectGUID) ON DELETE CASCADE
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
  GroupTypeSecurity BOOLEAN NOT NULL,
  VersionStartTime TIMESTAMP,
  OperationType ENUM('u','d'),
  VersionEndTime TIMESTAMP,
  DistinguishedName VARCHAR(2048) NOT NULL,
  Description TEXT NOT NULL,
  PRIMARY KEY (ArchiveID)
);

CREATE TABLE WRADGroupGroupArchive
(
  ArchiveID INT NOT NULL AUTO_INCREMENT,
  ParentGroupObjectGUID VARCHAR(36) NOT NULL,
  ChildGroupObjectGUID VARCHAR(36) NOT NULL,
  VersionStartTime TIMESTAMP,
  VersionEndTime TIMESTAMP,
  PRIMARY KEY (ArchiveID)
);

CREATE TABLE WRADSetting
(
  SettingID INT NOT NULL AUTO_INCREMENT,
  SettingName VARCHAR(30) NOT NULL,
  SettingValue VARCHAR(300) NOT NULL,
  PRIMARY KEY (SettingID)
);

INSERT INTO WRADSetting (SettingName,SettingValue) VALUES ("ADRoleDepartmentLead",""),("ADRoleAuditor",""),("ADRoleSysAdmin",""),("ADRoleApplOwner",""),("LogToFile","true"),("LogFilePath",""),("LogSyslogServer",""),("LogSyslogServerProtocol","udp");

CREATE TABLE WRADExcludeUser
(
  ExcludeID INT NOT NULL AUTO_INCREMENT,
  ObjectGUID VARCHAR(36) NOT NULL,
  PRIMARY KEY (ExcludeID),
  CONSTRAINT `FK_ExcludeUser` FOREIGN KEY (ObjectGUID) REFERENCES WRADUser(ObjectGUID) ON DELETE CASCADE
);


CREATE TABLE WRADExcludeGroup
(
  ExcludeID INT NOT NULL AUTO_INCREMENT,
  ObjectGUID VARCHAR(36) NOT NULL,
  PRIMARY KEY (ExcludeID),
  CONSTRAINT `FK_ExcludeGroup` FOREIGN KEY (ObjectGUID) REFERENCES WRADGroup(ObjectGUID) ON DELETE CASCADE	
);

DELIMITER //

CREATE TRIGGER UserInsert
  BEFORE INSERT ON WRADUser
  FOR EACH ROW BEGIN
	SET NEW.LastModifiedDate = UTC_TIMESTAMP(),NEW.CreatedDate = UTC_TIMESTAMP();
 END
// 

CREATE TRIGGER UserDelete
  AFTER DELETE ON WRADUser
  FOR EACH ROW BEGIN
	INSERT INTO WRADUserArchive (ObjectGUID,SAMAccountName,DistinguishedName,userPrincipalName,DisplayName,Enabled,Description,Expired,OperationType,VersionStartTime,VersionEndTime) VALUES (OLD.ObjectGUID, OLD.SAMAccountName, OLD.DistinguishedName,OLD.userPrincipalName,OLD.DisplayName,OLD.Enabled,OLD.Description,OLD.Expired,'d',OLD.LastModifiedDate,UTC_TIMESTAMP());
 END
//

CREATE TRIGGER UserUpdateBefore
  BEFORE UPDATE ON WRADUser
  FOR EACH ROW BEGIN
	IF NEW.SAMAccountName != OLD.SAMAccountName OR NEW.DistinguishedName != OLD.DistinguishedName OR NEW.userPrincipalName != OLD.userPrincipalName OR NEW.DisplayName != OLD.DisplayName OR NEW.Enabled != OLD.Enabled OR NEW.Description != OLD.Description OR NEW.Expired != OLD.Expired
	THEN 
	SET NEW.LastModifiedDate = UTC_TIMESTAMP();
	END IF;
 END
//

CREATE TRIGGER UserUpdateAfter
  AFTER UPDATE ON WRADUser
  FOR EACH ROW
    BEGIN
  	IF NEW.SAMAccountName != OLD.SAMAccountName OR NEW.DistinguishedName != OLD.DistinguishedName OR NEW.userPrincipalName != OLD.userPrincipalName OR NEW.DisplayName != OLD.DisplayName OR NEW.Enabled != OLD.Enabled OR NEW.Description != OLD.Description OR NEW.Expired != OLD.Expired
	THEN 
	INSERT INTO WRADUserArchive (ObjectGUID,SAMAccountName,DistinguishedName,userPrincipalName,DisplayName,Enabled,Description,Expired,OperationType,VersionStartTime,VersionEndTime) VALUES (OLD.ObjectGUID, OLD.SAMAccountName, OLD.DistinguishedName,OLD.userPrincipalName,OLD.DisplayName,OLD.Enabled,OLD.Description,OLD.Expired,'u',OLD.LastModifiedDate,UTC_TIMESTAMP());
  END IF;
END
//

CREATE TRIGGER GroupInsert
  BEFORE INSERT ON WRADGroup
  FOR EACH ROW BEGIN
	SET NEW.LastModifiedDate = UTC_TIMESTAMP(),NEW.CreatedDate = UTC_TIMESTAMP();
 END
//

CREATE TRIGGER GroupDelete
  AFTER DELETE ON WRADGroup
  FOR EACH ROW BEGIN
	INSERT INTO WRADGroupArchive (ObjectGUID,SAMAccountName,DistinguishedName,CommonName,Description,GroupType,GroupTypeSecurity,OperationType,VersionStartTime,VersionEndTime) VALUES (OLD.ObjectGUID, OLD.SAMAccountName, OLD.DistinguishedName,OLD.CommonName,OLD.Description,OLD.GroupType,OLD.GroupTypeSecurity,'d',OLD.LastModifiedDate,UTC_TIMESTAMP());
 END
//

CREATE TRIGGER GroupUpdateBefore
  BEFORE UPDATE ON WRADGroup
  FOR EACH ROW BEGIN
	SET NEW.LastModifiedDate = UTC_TIMESTAMP();
 END
//

CREATE TRIGGER GroupUpdateAfter
  AFTER UPDATE ON WRADGroup
  FOR EACH ROW BEGIN
	INSERT INTO WRADGroupArchive (ObjectGUID,SAMAccountName,DistinguishedName,CommonName,Description,GroupType,GroupTypeSecurity,OperationType,VersionStartTime,VersionEndTime) VALUES (OLD.ObjectGUID, OLD.SAMAccountName, OLD.DistinguishedName,OLD.CommonName,OLD.Description,OLD.GroupType,OLD.GroupTypeSecurity,'u',OLD.LastModifiedDate,UTC_TIMESTAMP());
 END
//

CREATE TRIGGER UserGroupInsert
  BEFORE INSERT ON WRADUserGroup
  FOR EACH ROW BEGIN
	SET NEW.CreatedDate = UTC_TIMESTAMP();
 END
//

CREATE TRIGGER UserGroupDelete
  AFTER DELETE ON WRADUserGroup
  FOR EACH ROW BEGIN
	INSERT INTO WRADUserGroupArchive (UserObjectGUID,GroupObjectGUID,VersionStartTime,VersionEndTime) VALUES (OLD.UserObjectGUID, OLD.GroupObjectGUID,OLD.CreatedDate,UTC_TIMESTAMP());
 END
//

CREATE TRIGGER GroupGroupInsert
  BEFORE INSERT ON WRADGroupGroup
  FOR EACH ROW BEGIN
	SET NEW.CreatedDate = UTC_TIMESTAMP();
 END
//

CREATE TRIGGER GroupGroupDelete
  AFTER DELETE ON WRADGroupGroup
  FOR EACH ROW BEGIN
	INSERT INTO WRADGroupGroupArchive (ParentGroup,ChildGroup,VersionStartTime,VersionEndTime) VALUES (OLD.ParentGroup, OLD.ChildGroup,OLD.CreatedDate,UTC_TIMESTAMP());
 END
//

DELIMITER ;

