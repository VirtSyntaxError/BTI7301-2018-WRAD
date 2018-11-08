use wrad;
SET FOREIGN_KEY_CHECKS = 0; 
TRUNCATE TABLE WRADExcludeUser;
TRUNCATE TABLE WRADExcludeGroup;
TRUNCATE TABLE WRADUserGroup;
TRUNCATE TABLE WRADRefUserGroup;
TRUNCATE TABLE WRADGroupGroup;
TRUNCATE TABLE WRADRefGroupGroup;
TRUNCATE TABLE WRADRefUser;
TRUNCATE TABLE WRADRefGroup;
TRUNCATE TABLE WRADGroup;
TRUNCATE TABLE WRADUser;
TRUNCATE TABLE WRADEvent;
SET FOREIGN_KEY_CHECKS = 1;
INSERT INTO WRADUser(ObjectGUID, SAMAccountName, DistinguishedName, LastLogonTimestamp, userPrincipalName, DisplayName, CreatedDate, LastModifiedDate, Enabled, Description, Expired) VALUES
	('guid1', 'furigod', 'CN=\"dario\",CN=\"example\",CN=\"local\"', NULL, 'furigod', 'Dario Furigo', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', 1, '', 0),
	('guid2', 'schaerzb', 'CN=\"pidu\",CN=\"example\",CN=\"local\"', NULL, 'schaerzb', 'Beat Schärz', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', 1, '', 0),
	('guid3', 'koeferp', 'CN=\"koeferp\",CN=\"example\",CN=\"local\"', NULL, 'koeferp', 'Phillip Köfer', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', 1, '', 0),
	('guid4', 'michaelisn', 'CN=\"michaelisn\",CN=\"example\",CN=\"local\"', NULL, 'michaelisn', 'Nicolas Michaelis', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', 1, '', 0),
	('guid5', 'notinsoll', 'CN=\"notinsoll\",CN=\"example\",CN=\"local\"', NULL, 'notinsoll', 'User that is not in SOLL', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', 1, '', 0),
	('b87461bc-2f4f-44c3-a807-f40d8f26d4a1', 'WRADadmin', 'CN=WRADadmin,OU=IT,OU=California,OU=WRAD,DC=WRAD,DC=local', NULL, 'WRADadmin@WRAD.local', 'WRADadmin', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', 1, 'Built-in account for administering the computer/domain', 0);

INSERT INTO WRADRefUser(ObjectGUID, Username, DisplayName, CreatedDate, Enabled) VALUES
	('guid1', 'furigod', 'Dario Furigo', '0000-00-00 00:00:00.000000', 1),
	('guid2', 'schaerzb', 'Beat Schärz', '0000-00-00 00:00:00.000000', 0),
	('guid3', 'koeferp', 'Phillip Köfffffer', '0000-00-00 00:00:00.000000', 1),
	('noguid77', 'michaelisn', 'Nicolas Michaelis', '0000-00-00 00:00:00.000000', 1),
	('noguid78', 'jungoc', 'Christof Jungo', '0000-00-00 00:00:00.000000', 1);

INSERT INTO WRADGroup(ObjectGUID, CreatedDate, LastModifiedDate, SAMAccountName, GroupType, GroupTypeSecurity, CommonName, DistinguishedName, Description) VALUES
	('gguid1', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', 'group1', 'DomainLocal', 'Security', 'group1', 'CN=\"group1\",CN=\"example\",CN=\"local\"', ''),
	('gguid2', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', 'group2', 'Global', 'Distribution', 'group2', 'CN=\"group2\",CN=\"example\",CN=\"local\"', ''),
	('gguid3', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', 'group3', 'Universal', 'Distribution', 'group3', 'CN=\"group3\",CN=\"example\",CN=\"local\"', ''),
	('gguid4', '0000-00-00 00:00:00.000000', '0000-00-00 00:00:00.000000', 'groupnotinsoll', 'Universal', 'Distribution', 'groupnotinsoll', 'CN=\"group4\",CN=\"example\",CN=\"local\"', '');

INSERT INTO WRADRefGroup(ObjectGUID, CreatedDate, GroupType, GroupTypeSecurity, CommonName) VALUES
	('gguid1', '0000-00-00 00:00:00.000000', 'DomainLocal', 'Security', 'group1'),
	('gguid2', '0000-00-00 00:00:00.000000', 'DomainLocal', 'Distribution', 'group2'),
	('noguid88', '0000-00-00 00:00:00.000000', 'Universal', 'Distribution', 'group3'),
	('noguid89', '0000-00-00 00:00:00.000000', 'Universal', 'Distribution', 'group4');

INSERT INTO WRADUserGroup(CreatedDate, UserObjectGUID, GroupObjectGUID) VALUES
	('0000-00-00 00:00:00.000000', 'guid1', 'gguid1'),
	('0000-00-00 00:00:00.000000', 'guid2', 'gguid1'),
	('0000-00-00 00:00:00.000000', 'guid2', 'gguid2'),
	('0000-00-00 00:00:00.000000', 'guid3', 'gguid3'),
	('0000-00-00 00:00:00.000000', 'guid4', 'gguid3');

INSERT INTO WRADRefUserGroup(CreatedDate, UserObjectGUID, GroupObjectGUID) VALUES
-- 1. guet, 2. user in group, 2.5 user not in group (guid2,gguid2)
	('0000-00-00 00:00:00.000000', 'guid1', 'gguid1'),
	('0000-00-00 00:00:00.000000', 'guid1', 'noguid88'),
	('0000-00-00 00:00:00.000000', 'guid2', 'gguid1'),
	('0000-00-00 00:00:00.000000', 'guid3', 'noguid88'),
	('0000-00-00 00:00:00.000000', 'noguid77', 'noguid88');

INSERT INTO WRADGroupGroup(CreatedDate, ChildGroupObjectGUID, ParentGroupObjectGUID) VALUES
	('0000-00-00 00:00:00.000000', 'gguid1', 'gguid2'),
	('0000-00-00 00:00:00.000000', 'gguid2', 'gguid3');

INSERT INTO WRADRefGroupGroup(CreatedDate, ChildGroupObjectGUID, ParentGroupObjectGUID) VALUES
	('0000-00-00 00:00:00.000000', 'gguid1', 'gguid2'),
	('0000-00-00 00:00:00.000000', 'gguid1', 'noguid88'),
	('0000-00-00 00:00:00.000000', 'gguid2', 'noguid88');
