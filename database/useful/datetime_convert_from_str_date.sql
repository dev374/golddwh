CAST(SUBSTRING(stg.import_am, CHARINDEX(',',stg.import_am,0)+1,50) as datetime)

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [K_ID]
      --,cast([IMPORT_AM] as datetime)
	  --,DATENAME(weekday,IMPORT_AM)
	  ,SUBSTRING([IMPORT_AM], CHARINDEX(',',[IMPORT_AM],0)+1,100)
	  ,CAST(SUBSTRING([IMPORT_AM], CHARINDEX(',',[IMPORT_AM],0)+1,50) as datetime)
	  ,[IMPORT_AM]
      ,[LIEFERN_AB]
      ,[VERTRAGSENDE]
      ,[WUNSCHTERMIN]
      ,[DATUM_EINZUG]
      ,[ABSCHLAGSMIT_AM]
      ,[FREI_ZUM]
      ,[SONDERVERTRAGSKUNDE]
      ,[BEMERKUNG_KUENDIGUNG]
      ,[STORNO]
      ,[hash_diff]
  FROM [adf].[dat_kunde]