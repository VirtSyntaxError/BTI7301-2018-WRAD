use wrad;

INSERT INTO `wraduser` (`ObjectGUID`, `SAMAccountName`, `DistinguishedName`, `LastLogonTimestamp`, `userPrincipalName`, `DisplayName`, `CreatedDate`, `LastModifiedDate`, `Enabled`, `Description`, `Expired`) VALUES ('testid', 'dario', 'CN=\"dario\",CN=\"example\",CN=\"local\"', NULL, 'dario.furigo', 'Dario Furigo', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', '1', '', '0');

INSERT INTO `wraduser` (`ObjectGUID`, `SAMAccountName`, `DistinguishedName`, `LastLogonTimestamp`, `userPrincipalName`, `DisplayName`, `CreatedDate`, `LastModifiedDate`, `Enabled`, `Description`, `Expired`) VALUES ('testid2', 'pidu', 'CN=\"pidu\",CN=\"example\",CN=\"local\"', NULL, 'pidu.schaerz', 'Beat Schärz', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', '1', 'Pidus User', '0');

INSERT INTO `wradgroup` (`ObjectGUID`, `CreatedDate`, `LastModifiedDate`, `SAMAccountName`, `GroupType`, `GroupTypeSecurity`, `CommonName`, `DistinguishedName`, `Description`) VALUES ('testid', CURRENT_TIMESTAMP, '0000-00-00 00:00:00.000000', 'Domain Admins', 'ADS_GROUP_TYPE_GLOBAL_GROUP', '0', 'Domain Admins', 'cn=\"Domain Admins\",cn=\"example\",cn=\"local\"', 'Domain Admins');

INSERT INTO `wradgroup` (`ObjectGUID`, `CreatedDate`, `LastModifiedDate`, `SAMAccountName`, `GroupType`, `GroupTypeSecurity`, `CommonName`, `DistinguishedName`, `Description`) VALUES ('testid2', CURRENT_TIMESTAMP, '0000-00-00 00:00:00.000000', 'Domain Users', 'ADS_GROUP_TYPE_GLOBAL_GROUP', '0', 'Domain Admins', 'cn=\"Domain Users\",cn=\"example\",cn=\"local\"', 'Domain Users');


INSERT INTO `wradusergroup` (`CreatedDate`, `UserObjectGUID`, `GroupObjectGUID`) VALUES (CURRENT_TIMESTAMP, 'testid', 'testid2'), (CURRENT_TIMESTAMP, 'testid2', 'testid2');

INSERT INTO `wradusergroup` (`CreatedDate`, `UserObjectGUID`, `GroupObjectGUID`) VALUES (CURRENT_TIMESTAMP, 'testid', 'testid'), (CURRENT_TIMESTAMP, 'testid2', 'testid');


DELETE FROM `wradusergroup` WHERE `wradusergroup`.`UserObjectGUID` = 'testid' AND `wradusergroup`.`GroupObjectGUID` = 'testid2';
DELETE FROM `wradusergroup` WHERE `wradusergroup`.`UserObjectGUID` = 'testid2' AND `wradusergroup`.`GroupObjectGUID` = 'testid2';

UPDATE `wraduser` SET `SAMAccountName` = 'furid', `LastLogonTimestamp` = NULL WHERE `wraduser`.`ObjectGUID` = 'testid';
UPDATE `wraduser` SET `SAMAccountName` = 'beat', `LastLogonTimestamp` = NULL, `userPrincipalName` = 'beat.schaerz' WHERE `wraduser`.`ObjectGUID` = 'testid2';
UPDATE `wraduser` SET `LastLogonTimestamp` = NULL, `Description` = 'Darios User' WHERE `wraduser`.`ObjectGUID` = 'testid';

