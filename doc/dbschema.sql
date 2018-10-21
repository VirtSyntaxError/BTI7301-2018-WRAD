CREATE DATABASE WRAD;
USE WRAD;

DROP TABLE IF EXISTS WRADGroupGroup;
DROP TABLE IF EXISTS WRADRefGroupGroup;
DROP TABLE IF EXISTS WRADRefNewGroupGroup;
DROP TABLE IF EXISTS WRADUserGroup;
DROP TABLE IF EXISTS WRADRefUserGroup;
DROP TABLE IF EXISTS WRADRefNewUserGroup;
DROP TABLE IF EXISTS WRADGroupGroupArchive;
DROP TABLE IF EXISTS WRADUserGroupArchive;
DROP TABLE IF EXISTS WRADSetting;
DROP TABLE IF EXISTS WRADExcludeUser;
DROP TABLE IF EXISTS WRADExcludeGroup;
DROP TABLE IF EXISTS WRADUser;
DROP TABLE IF EXISTS WRADRefUser;
DROP TABLE IF EXISTS WRADRefNewUser;
DROP TABLE IF EXISTS WRADUserArchive;
DROP TABLE IF EXISTS WRADGroup;
DROP TABLE IF EXISTS WRADRefGroup;
DROP TABLE IF EXISTS WRADRefNewGroup;
DROP TABLE IF EXISTS WRADGroupArchive;
DROP TABLE IF EXISTS WRADLog;

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
  CreatedDate TIMESTAMP NULL,
  LastModifiedDate TIMESTAMP NULL,
  Enabled BOOLEAN NOT NULL,
  Description TEXT NOT NULL,
  Expired BOOLEAN NOT NULL,
  PRIMARY KEY (ObjectGUID)
);

CREATE TABLE WRADRefUser
(
  ObjectGUID VARCHAR(36) NOT NULL,
  Username VARCHAR(1024) NOT NULL,
  DisplayName VARCHAR(256) NOT NULL,
  CreatedDate TIMESTAMP NULL,
  Enabled BOOLEAN NOT NULL,
  PRIMARY KEY (ObjectGUID)
);

CREATE TABLE WRADRefNewUser
(
  NewUserID INT NOT NULL AUTO_INCREMENT,
  Username VARCHAR(1024) NOT NULL,
  DisplayName VARCHAR(256) NOT NULL,
  CreatedDate TIMESTAMP NULL,
  Enabled BOOLEAN NOT NULL,
  PRIMARY KEY (NewUserID)
);

CREATE TABLE WRADUserArchive
(
  ArchiveID INT NOT NULL AUTO_INCREMENT,
  userPrincipalName VARCHAR(1024) NOT NULL,
  SAMAccountName VARCHAR(104) NOT NULL,
  DistinguishedName VARCHAR(2048) NOT NULL,
  ObjectGUID VARCHAR(36) NOT NULL,
  OperationType ENUM('u','d'),
  VersionStartTime TIMESTAMP NULL,
  VersionEndTime TIMESTAMP NULL,
  DisplayName VARCHAR(256) NOT NULL,
  Description TEXT NOT NULL,
  Enabled BOOLEAN NOT NULL,
  Expired BOOLEAN NOT NULL,
  PRIMARY KEY (ArchiveID)
);

CREATE TABLE WRADGroup
(
  ObjectGUID VARCHAR(36) NOT NULL,
  CreatedDate TIMESTAMP NULL,
  LastModifiedDate TIMESTAMP NULL,
  SAMAccountName VARCHAR(104) NOT NULL,
  GroupType ENUM('ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP','ADS_GROUP_TYPE_GLOBAL_GROUP','ADS_GROUP_TYPE_UNIVERSAL_GROUP') NOT NULL,
  GroupTypeSecurity ENUM('Security','Distribution') NOT NULL,
  CommonName VARCHAR(256) NOT NULL,
  DistinguishedName VARCHAR(2048) NOT NULL,
  Description TEXT NOT NULL,
  PRIMARY KEY (ObjectGUID)
);

CREATE TABLE WRADRefGroup
(
  ObjectGUID VARCHAR(36) NOT NULL,
  CreatedDate TIMESTAMP NULL,
  GroupType ENUM('ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP','ADS_GROUP_TYPE_GLOBAL_GROUP','ADS_GROUP_TYPE_UNIVERSAL_GROUP') NOT NULL,
  GroupTypeSecurity ENUM('Security','Distribution') NOT NULL,
  CommonName VARCHAR(256) NOT NULL,
  PRIMARY KEY (ObjectGUID)
);

CREATE TABLE WRADRefNewGroup
(
  NewGroupID INT NOT NULL AUTO_INCREMENT,
  CreatedDate TIMESTAMP NULL,
  GroupType ENUM('ADS_GROUP_TYPE_DOMAIN_LOCAL_GROUP','ADS_GROUP_TYPE_GLOBAL_GROUP','ADS_GROUP_TYPE_UNIVERSAL_GROUP') NOT NULL,
  GroupTypeSecurity ENUM('Security','Distribution') NOT NULL,
  CommonName VARCHAR(256) NOT NULL,
  PRIMARY KEY (NewGroupID)
);

CREATE TABLE WRADUserGroup
(
  CreatedDate TIMESTAMP NULL,
  UserObjectGUID VARCHAR(36) NOT NULL,
  GroupObjectGUID VARCHAR(36) NOT NULL,
  PRIMARY KEY (UserObjectGUID, GroupObjectGUID),
  CONSTRAINT `FK_User` FOREIGN KEY (UserObjectGUID) REFERENCES WRADUser(ObjectGUID),
  CONSTRAINT `FK_Group` FOREIGN KEY (GroupObjectGUID) REFERENCES WRADGroup(ObjectGUID)
);

CREATE TABLE WRADRefUserGroup
(
  CreatedDate TIMESTAMP NULL,
  UserObjectGUID VARCHAR(36) NOT NULL,
  GroupObjectGUID VARCHAR(36) NOT NULL,
  PRIMARY KEY (UserObjectGUID, GroupObjectGUID),
  CONSTRAINT `FK_RefUser` FOREIGN KEY (UserObjectGUID) REFERENCES WRADRefUser(ObjectGUID),
  CONSTRAINT `FK_RefGroup` FOREIGN KEY (GroupObjectGUID) REFERENCES WRADRefGroup(ObjectGUID)
);

CREATE TABLE WRADRefNewUserGroup
(
  RefNewUserGroupID INT NOT NULL AUTO_INCREMENT,
  CreatedDate TIMESTAMP NULL,
  Username VARCHAR(1024) NOT NULL,
  Groupname VARCHAR(256) NOT NULL,
  PRIMARY KEY (RefNewUserGroupID)
);

CREATE TABLE WRADGroupGroup
(
  CreatedDate TIMESTAMP NULL,
  ChildGroupObjectGUID VARCHAR(36) NOT NULL,
  ParentGroupObjectGUID VARCHAR(36) NOT NULL,
  PRIMARY KEY (ChildGroupObjectGUID, ParentGroupObjectGUID),
  CONSTRAINT `FK_ChildGroup` FOREIGN KEY (ChildGroupObjectGUID) REFERENCES WRADGroup(ObjectGUID),
  CONSTRAINT `FK_ParentGroup` FOREIGN KEY (ParentGroupObjectGUID) REFERENCES WRADGroup(ObjectGUID)
);

CREATE TABLE WRADRefGroupGroup
(
  CreatedDate TIMESTAMP NULL,
  ChildGroupObjectGUID VARCHAR(36) NOT NULL,
  ParentGroupObjectGUID VARCHAR(36) NOT NULL,
  PRIMARY KEY (ChildGroupObjectGUID, ParentGroupObjectGUID),
  CONSTRAINT `FK_RefChildGroup` FOREIGN KEY (ChildGroupObjectGUID) REFERENCES WRADRefGroup(ObjectGUID),
  CONSTRAINT `FK_RefParentGroup` FOREIGN KEY (ParentGroupObjectGUID) REFERENCES WRADRefGroup(ObjectGUID)
);

CREATE TABLE WRADRefNewGroupGroup
(
  RefNewGroupGroupID INT NOT NULL AUTO_INCREMENT,
  CreatedDate TIMESTAMP NULL,
  ChildGroup VARCHAR(256) NOT NULL,
  ParentGroup VARCHAR(256) NOT NULL,
  PRIMARY KEY (RefNewGroupGroupID)
);

CREATE TABLE WRADUserGroupArchive
(
  UserObjectGUID VARCHAR(36) NOT NULL,
  GroupObjectGUID VARCHAR(36) NOT NULL,
  VersionStartTime TIMESTAMP NULL,
  VersionEndTime TIMESTAMP NULL,
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
  GroupTypeSecurity ENUM('Security','Distribution') NOT NULL,
  VersionStartTime TIMESTAMP NULL,
  OperationType ENUM('u','d'),
  VersionEndTime TIMESTAMP NULL,
  DistinguishedName VARCHAR(2048) NOT NULL,
  Description TEXT NOT NULL,
  PRIMARY KEY (ArchiveID)
);

CREATE TABLE WRADGroupGroupArchive
(
  ArchiveID INT NOT NULL AUTO_INCREMENT,
  ParentGroupObjectGUID VARCHAR(36) NOT NULL,
  ChildGroupObjectGUID VARCHAR(36) NOT NULL,
  VersionStartTime TIMESTAMP NULL,
  VersionEndTime TIMESTAMP NULL,
  PRIMARY KEY (ArchiveID)
);

CREATE TABLE WRADSetting
(
  SettingID INT NOT NULL AUTO_INCREMENT,
  SettingName VARCHAR(30) NOT NULL,
  SettingValue VARCHAR(300) NOT NULL,
  PRIMARY KEY (SettingID)
);

INSERT INTO WRADSetting (SettingName,SettingValue) VALUES ("ADRoleDepartmentLead",""),("ADRoleAuditor",""),("ADRoleSysAdmin",""),("ADRoleApplOwner",""),("LogExternal","none"),("LogFilePath",""),("LogSyslogServer",""),("LogSyslogServerProtocol","udp"),("SearchBase","");

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

CREATE TABLE WRADLog
(
  LogID INT NOT NULL AUTO_INCREMENT,
  LogTimestamp TIMESTAMP NULL,
  LogSeverity INT NOT NULL,
  LogText TEXT NOT NULL,
  PRIMARY KEY (LogID)
);

DROP TRIGGER IF EXISTS UserInsert;
DROP TRIGGER IF EXISTS RefUserInsert;
DROP TRIGGER IF EXISTS RefNewUserInsert;
DROP TRIGGER IF EXISTS UserDeleteBefore;
DROP TRIGGER IF EXISTS UserDeleteAfter;
DROP TRIGGER IF EXISTS UserUpdateBefore;
DROP TRIGGER IF EXISTS UserUpdateAfter;
DROP TRIGGER IF EXISTS GroupInsert;
DROP TRIGGER IF EXISTS RefGroupInsert;
DROP TRIGGER IF EXISTS RefNewGroupInsert;
DROP TRIGGER IF EXISTS GroupDeleteBefore;
DROP TRIGGER IF EXISTS GroupDeleteAfter;
DROP TRIGGER IF EXISTS GroupUpdateBefore;
DROP TRIGGER IF EXISTS GroupUpdateAfter;
DROP TRIGGER IF EXISTS UserGroupInsert;
DROP TRIGGER IF EXISTS RefUserGroupInsert;
DROP TRIGGER IF EXISTS RefNewUserGroupInsert;
DROP TRIGGER IF EXISTS UserGroupDelete;
DROP TRIGGER IF EXISTS GroupGroupInsert;
DROP TRIGGER IF EXISTS RefGroupGroupInsert;
DROP TRIGGER IF EXISTS RefNewGroupGroupInsert;
DROP TRIGGER IF EXISTS GroupGroupDelete;


DELIMITER //

CREATE TRIGGER UserInsert
  BEFORE INSERT ON WRADUser
  FOR EACH ROW BEGIN
	SET NEW.LastModifiedDate = UTC_TIMESTAMP(),NEW.CreatedDate = UTC_TIMESTAMP();
 END
// 

CREATE TRIGGER RefUserInsert
  BEFORE INSERT ON WRADRefUser
  FOR EACH ROW BEGIN
	SET NEW.CreatedDate = UTC_TIMESTAMP();
 END
//

CREATE TRIGGER RefNewUserInsert
  BEFORE INSERT ON WRADRefNewUser
  FOR EACH ROW BEGIN
	SET NEW.CreatedDate = UTC_TIMESTAMP();
 END
//

CREATE TRIGGER UserDeleteBefore
  BEFORE DELETE ON WRADUser
  FOR EACH ROW BEGIN
	DELETE FROM WRADUserGroup WHERE UserObjectGUID = OLD.ObjectGUID;
 END
//

CREATE TRIGGER UserDeleteAfter
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

CREATE TRIGGER RefGroupInsert
  BEFORE INSERT ON WRADRefGroup
  FOR EACH ROW BEGIN
	SET NEW.CreatedDate = UTC_TIMESTAMP();
 END
//

CREATE TRIGGER RefNewGroupInsert
  BEFORE INSERT ON WRADRefNewGroup
  FOR EACH ROW BEGIN
	SET NEW.CreatedDate = UTC_TIMESTAMP();
 END
//

CREATE TRIGGER GroupDeleteBefore
  BEFORE DELETE ON WRADGroup
  FOR EACH ROW BEGIN
	DELETE FROM WRADUserGroup WHERE GroupObjectGUID = OLD.ObjectGUID;
	DELETE FROM WRADGroupGroup WHERE ChildGroupObjectGUID = OLD.ObjectGUID OR ParentGroupObjectGUID = OLD.ObjectGUID;
 END
//

CREATE TRIGGER GroupDeleteAfter
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

CREATE TRIGGER RefUserGroupInsert
  BEFORE INSERT ON WRADRefUserGroup
  FOR EACH ROW BEGIN
	SET NEW.CreatedDate = UTC_TIMESTAMP();
 END
//

CREATE TRIGGER RefNewUserGroupInsert
  BEFORE INSERT ON WRADRefNewUserGroup
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

CREATE TRIGGER RefGroupGroupInsert
  BEFORE INSERT ON WRADRefGroupGroup
  FOR EACH ROW BEGIN
	SET NEW.CreatedDate = UTC_TIMESTAMP();
 END
//

CREATE TRIGGER RefNewGroupGroupInsert
  BEFORE INSERT ON WRADRefNewGroupGroup
  FOR EACH ROW BEGIN
	SET NEW.CreatedDate = UTC_TIMESTAMP(),NEW.LastModifiedDate = UTC_TIMESTAMP();
 END
//

CREATE TRIGGER GroupGroupDelete
  AFTER DELETE ON WRADGroupGroup
  FOR EACH ROW BEGIN
	INSERT INTO WRADGroupGroupArchive (ParentGroupObjectGUID,ChildGroupObjectGUID,VersionStartTime,VersionEndTime) VALUES (OLD.ParentGroupObjectGUID, OLD.ChildGroupObjectGUID,OLD.CreatedDate,UTC_TIMESTAMP());
 END
//

DELIMITER ;

