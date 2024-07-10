WITH PROJECT_HIERARCHY AS (
  SELECT 
    P1.ID AS PROJECT_ID, 
    P1.NAME AS PROJECT_NAME, 
    COALESCE(
      P1.CONTROLLING_PERMISSIONS_PROJECT_ID, 
      P1.ID
    ) AS CONTROL_PROJECT_ID, 
    COALESCE(P2.NAME, P1.NAME) AS CONTROL_PROJECT_NAME, 
    P1.PARENT_PROJECT_ID, 
    COALESCE(P3.NAME, P2.NAME, P1.NAME) AS PARENT_PROJECT 
  FROM 
    PROJECTS P1 
    LEFT JOIN PROJECTS P2 ON P1.CONTROLLING_PERMISSIONS_PROJECT_ID = P2.ID 
    LEFT JOIN PROJECTS P3 ON P1.PARENT_PROJECT_ID = P3.ID
), 
LATEST_USER_ROLES AS (
  SELECT 
    * 
  FROM 
    (
      SELECT 
        HU.USER_ID, 
        HU.SYSTEM_USER_ID, 
        HU.NAME AS USER_NAME, 
        HU.SITE_ROLE_ID AS USER_TYPE_CODE, 
        SR.NAME AS USER_TYPE, 
        SR.DISPLAY_NAME, 
        MAX(HE.CREATED_AT) AS LATEST_USE_DATE, 
        ROW_NUMBER() OVER (
          PARTITION BY HU.SYSTEM_USER_ID 
          ORDER BY 
            MAX(HE.CREATED_AT) DESC
        ) AS RN 
      FROM 
        HISTORICAL_EVENTS HE 
        LEFT JOIN HIST_USERS HU ON HE.HIST_ACTOR_USER_ID = HU.ID 
        LEFT JOIN SITE_ROLES SR ON HU.SITE_ROLE_ID = SR.ID 
      GROUP BY 
        HU.USER_ID, 
        HU.SYSTEM_USER_ID, 
        HU.NAME, 
        HU.SITE_ROLE_ID, 
        SR.NAME, 
        SR.DISPLAY_NAME
    ) AS SUBQUERY 
  WHERE 
    RN = 1
), 
EVENT_SUMMARY AS (
  SELECT 
    -------------------------------
    -- Event Details summary
    HE.HISTORICAL_EVENT_TYPE_ID, 
    HET.NAME AS EVENT_TYPE, 
    HET.ACTION_TYPE, 
    -------------------------------
    -- Day time this is used
    HE.CREATED_AT, 
    -------------------------------
    --user who initiated action
    HE.HIST_ACTOR_USER_ID, 
    HU.SYSTEM_USER_ID AS USER_ID, 
    HU.NAME AS USER_NAME, 
    HU.SITE_ROLE_ID AS USER_TYPE_CODE, 
    LUR.DISPLAY_NAME AS USER_TYPE, 
    COALESCE(SU.STATE, 'DEACTIVATED') AS USER_STATUS, 
    HE.HIST_TARGET_SITE_ID, 
    -------------------------------
    --Project Details
    HE.HIST_PROJECT_ID, 
    HP.PROJECT_ID, 
    HP.NAME AS PROJECT_NAME, 
    -------------------------------
    --PROJECT_HIERARCHY details
    PH.PROJECT_ID AS PROJECT_ID_H, 
    PH.PROJECT_NAME AS PROJECT_NAME_H, 
    PH.CONTROL_PROJECT_ID, 
    PH.CONTROL_PROJECT_NAME, 
    PH.PARENT_PROJECT_ID, 
    PH.PARENT_PROJECT, 
    -------------------------------
    --Workbook details
    HE.HIST_WORKBOOK_ID, 
    HW.WORKBOOK_ID, 
    HW.NAME AS WORKBOOK_NAME, 
    --------------------------------
    --View details
    HE.HIST_VIEW_ID, 
    HV.VIEW_ID, 
    HV.NAME AS VIEW_NAME, 
    --------------------------------
    --Connected datasource
    HE.HIST_DATASOURCE_ID, 
    HD.DATASOURCE_ID, 
    HD.NAME AS DATASOURCE_NAME ---------------------------------
    --userful for the future
    -- he.hist_group_id,
    -- he.hist_licensing_role_id,
    -- he.hist_data_connection_id,
    -- he.hist_capability_id
    ---------------------------------
  FROM 
    HISTORICAL_EVENTS HE 
    LEFT JOIN HISTORICAL_EVENT_TYPES HET ON HE.HISTORICAL_EVENT_TYPE_ID = HET.TYPE_ID 
    LEFT JOIN HIST_USERS HU ON HE.HIST_ACTOR_USER_ID = HU.ID 
    LEFT JOIN HIST_PROJECTS HP ON HE.HIST_PROJECT_ID = HP.ID 
    LEFT JOIN HIST_WORKBOOKS HW ON HE.HIST_WORKBOOK_ID = HW.ID 
    LEFT JOIN HIST_VIEWS HV ON HE.HIST_VIEW_ID = HV.ID 
    LEFT JOIN HIST_DATASOURCES HD ON HE.HIST_DATASOURCE_ID = HD.ID 
    LEFT JOIN PROJECT_HIERARCHY PH ON HP.PROJECT_ID = PH.PROJECT_ID 
    LEFT JOIN LATEST_USER_ROLES LUR ON HU.SYSTEM_USER_ID = LUR.SYSTEM_USER_ID 
    LEFT JOIN SYSTEM_USERS SU ON HU.SYSTEM_USER_ID = SU.ID
) 
SELECT 
  * 
FROM 
  EVENT_SUMMARY 
WHERE 
  CREATED_AT >= CURRENT_DATE - interval '91 days' 
  AND HISTORICAL_EVENT_TYPE_ID = 84 
  AND HIST_TARGET_SITE_ID = 3