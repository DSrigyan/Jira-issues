
select * from next_gen_permissions

select * from permissions_templates

select * from permission_sets

select * from permission_set_items

select * from permission_set_classes

select * from permission_reasons


select * from public.pending_search_update_items

select * from permission_set_items

select * from capabilities

select * from capability_roles

select * from SITE_ROLES

select * from roles order by id


SELECT 
	CR.ID AS CAPABILITY_ROLE_ID,
	CR.CAPABILITY_ID,
	CR.ROLE_ID,
	C.DISPLAY_NAME AS CAPABILITY_PERMISSION,
	R.NAME,
	R.DISPLAY_NAME,
	R.DISPLAYABLE,
	R.ADMINISTRATIVE
FROM CAPABILITY_ROLES CR
LEFT JOIN CAPABILITIES C ON CR.ID = C.ID
LEFT JOIN ROLES R ON CR.ROLE_ID = R.ID
-- SELECT * FROM roles