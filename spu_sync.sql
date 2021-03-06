
CREATE procedure [dbo].[spu_AD_Sync]
as

set nocount on;

declare @ldap varchar(255) = 'LDAP://dc=mydomain,dc=local';

declare @q nvarchar(1024);



-- get groups

create table #groups ( objectGuid uniqueidentifier, distinguishedName varchar(255), name varchar(255) );

select @q = '
	insert into #groups ( 
		objectGuid, 
		distinguishedName, 
		name
	)
	select 
		objectGuid, 
		distinguishedName, 
		name
	FROM OPENQUERY( ADSI, ''SELECT objectGuid, distinguishedName, name 
							FROM ''''' + @ldap + ''''' 
							where objectClass = ''''Group'''' '')';
						
exec(@q);

-- delete non-existant users

delete from ad_groups
where not exists (select * from #groups g where g.objectGuid=ad_groups.guid);


-- update existing groups

update g set 
	g.name=a.name, 
	g.distinguishedName=a.distinguishedName
from #groups a
join ad_groups g on g.guid=a.objectGuid
where 
	g.name<>a.name 
	or g.distinguishedName=a.name;


-- insert new groups

insert into ad_groups ( 
	GUID, 
	Name, 
	distinguishedName
)
select 
	a.objectguid, 
	a.name, 
	a.distinguishedName
from #groups a
left join ad_groups g on g.guid=a.objectGuid
where 
	g.id is null;

drop table #groups;



-- get users

create table #users ( userAccountControl varchar(255), objectGuid uniqueidentifier, distinguishedName varchar(255), samAccountName varchar(255), name varchar(255) );

select @q = '
	insert into #users ( 
		userAccountControl, 
		objectGuid, 
		distinguishedName, 
		samAccountName, 
		name
	)
	select 
		userAccountControl, 
		objectGuid, 
		distinguishedName, 
		samAccountName, 
		name
	FROM OPENQUERY( ADSI, ''SELECT userAccountControl, objectGuid, distinguishedName, samAccountName, name 
							FROM ''''' + @ldap + ''''' 
							where objectClass = ''''User'''' and objectCategory = ''''Person''''  '')
	where 
		samAccountName not like ''%$''';
		
exec(@q);


-- delete non-existant users

delete from ad_users
where not exists (select * from #users u where u.objectGuid=ad_users.guid);


-- update existing users

update u set u.name=a.name, u.distinguishedName=a.distinguishedName, u.accountname=a.samaccountname, u.active=case when useraccountcontrol&2=2 then 0 else 1 end
from #users a
join ad_users u on u.guid = a.objectguid
where ( u.name<>a.name or u.distinguishedName<>a.distinguishedName or u.accountname<>a.samaccountname
	or u.active<>(case when useraccountcontrol&2=2 then 0 else 1 end));


-- insert new users

insert into ad_users ( GUID, Name, distinguishedName, accountname, active)
select a.objectguid, a.name, a.distinguishedName, a.samaccountname, case when useraccountcontrol&2=2 then 0 else 1 end
from #users a
left join ad_users u on u.guid = a.objectguid
where u.id is null;


drop table #users




-- group members 

create table #guids ( guid uniqueidentifier );

declare groups cursor local fast_forward for
select id,  distinguishedname from ad_groups

declare @id int, @dname varchar(1024);

OPEN groups;

FETCH NEXT FROM groups INTO @id, @dname;

WHILE @@FETCH_STATUS = 0 BEGIN

	-- get all members of this group
	
	delete from #guids;

	select @q = 'insert into #guids(guid) select objectGuid from openquery(adsi, ''SELECT objectGuid FROM ''''' + @ldap + ''''' where memberof=''''' + @dname + ''''' '')';
			
	exec(@q);

	-- delete/insert groups
	 
	delete gg
	from ad_groups_groups gg
	join ad_groups g1 on g1.id = gg.childgroupid
	left join #guids a on a.guid = g1.guid
	where gg.groupid=@id and a.guid is null;
	
	insert into ad_groups_groups(groupid, childgroupid)
	select @id, g.id
	from #guids a
	join ad_groups g on g.guid = a.guid
	left join ad_groups_groups gg on gg.groupid=@id and gg.childgroupid=g.id
	where gg.id is null;
	
	
	-- delete/insert users
	
	delete gu
	from ad_groups_users gu
	join ad_users u1 on u1.id=gu.userid
	left join #guids a on a.guid = u1.guid
	where gu.groupid=@id and a.guid is null;
	
	insert into ad_groups_users(groupid,userid) 
	select @id, u.id
	from #guids a
	join ad_users u on u.guid = a.guid
	left join ad_groups_users gu on gu.groupid=@id and gu.userid=u.id
	where gu.id is null
			
	FETCH NEXT FROM groups INTO @id, @dname;

END;

CLOSE groups; DEALLOCATE groups;

drop table #guids;


-- update group members count

update ad_groups
set members = (select count(*) from ad_groups_users gu join ad_users u on u.id=gu.userid where gu.groupid=ad_groups.id and u.active=1)


