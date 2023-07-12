WITH hbo_json_flaten_nonepisode AS (
	SELECT
	 	  JSON:Id::STRING AS Platform_Title_Id
	 	 ,JSON:CleanTitle::STRING AS Content_Title
		 ,country.value::STRING AS Origin_Country
		 ,languages.value::STRING AS Contentent_Language
		 ,JSON:IsOriginal:: STRING AS Original_Classification
		 ,Region:: STRING AS Region
		 ,actor.value::STRING AS Actors_Name
		 ,director.value::STRING AS Director_Name
		 ,genre.value:: STRING AS Genre_Name
		 ,image.value::STRING AS Content_Image
		 ,JSON:Synopsis:: STRING AS Synopsis
		 ,external_id.value:ID::STRING IMDB_Id
		 ,external_id.value:Provider::STRING IMDB_Provider
		
	FROM "METAHUB_HBO"."BB_SRC_JSON",
		 LATERAL flatten (INPUT => json:CountriesOfOrigin, OUTER => true) country
		 ,LATERAL flatten (INPUT => json:LanguageList, OUTER => true) languages
		 ,LATERAL flatten (INPUT => json:Cast, OUTER => true) actor
		 ,LATERAL flatten (INPUT => json:Directors, OUTER => true) director
		 ,LATERAL flatten (INPUT => json:Genres, OUTER => true) genre
		 ,LATERAL flatten (INPUT => json:Image, OUTER => true) image
		 ,LATERAL flatten (INPUT => json:ExternalIds, OUTER => true) external_id
		 
	WHERE CONTENT_TYPE <> 'Episode' AND IMDB_Provider='imdb' AND CREATED_AT >= '2023-07-01'),
	
	unique_title_id AS (
	SELECT 
		DISTINCT Platform_Title_Id, Content_Title, Region
	FROM hbo_json_flaten_nonepisode),
		
	viewing_count AS (	
	SELECT left(PLATFORM_TITLE_ID, len(PLATFORM_TITLE_ID) - 3) PLATFORM_TITLE_ID, Region, Count(*) VIEWING_NO
	FROM "HBO"."HBO_TIMELINE"
	WHERE left(PLATFORM_TITLE_ID, len(PLATFORM_TITLE_ID) - 3) IN (SELECT DISTINCT Platform_Title_Id FROM unique_title_id) 
	GROUP BY PLATFORM_TITLE_ID, Region ORDER BY VIEWING_NO DESC),
	
	title_count AS (
	SELECT viewing_count.PLATFORM_TITLE_ID
	,unique_title_id.Content_Title
	,viewing_count.Region
	,viewing_count.VIEWING_NO
	FROM viewing_count
	INNER JOIN unique_title_id ON 
	viewing_count.PLATFORM_TITLE_ID = unique_title_id.Platform_Title_Id)

	SELECT * FROM title_count