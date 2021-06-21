// This file contains your Data Connector logic
section FBads;

[DataSource.Kind="FBads", Publish="FBads.Publish"]
shared FBads.Stat= Value.ReplaceType(FBads.Func, FuncType);





FuncType = type function (
     account  as (type text meta [
        Documentation.FieldCaption = "Facebook account ID:",
        Documentation.FieldDescription = "",
        Documentation.SampleValues = {"12345678901234567"}
    ]),
       reportType  as (type text meta [
        Documentation.FieldCaption = "Report type:",
        Documentation.FieldDescription = "",
        Documentation.AllowedValues = {"campaign","group","ad"}
    ]),
    start as (type text meta [
        Documentation.FieldCaption = "Start date:",
        Documentation.FieldDescription = "Enter the first date of your statistics. You can specify date in YYYY-MM-DD format or use dynamic formats: today, yesterday, 69daysAgo.",
        Documentation.SampleValues = {"2020-02-28"}
    ]),
     end as (type text meta [
        Documentation.FieldCaption = "End date:",
        Documentation.FieldDescription = "Enter the last date of your statistics. You can specify date in YYYY-MM-DD format or use dynamic formats: today, yesterday, 69daysAgo.",
        Documentation.SampleValues = {"yesterday"}
    ]),
       limitVar  as (type nullable text meta [
        Documentation.FieldCaption = "Row limit for 1 query:",
        Documentation.FieldDescription = "",
        Documentation.AllowedValues = {"100","500","1000","5000","10000"}
    ]),
       delayVar  as (type nullable number meta [
        Documentation.FieldCaption = "Query delay (sec):",
        Documentation.FieldDescription = "",
        Documentation.AllowedValues = {0.01,0.05,0.1,0.2,0.3,0.4,0.5,0.7,1}
    ])
    )
    as table meta [
        Documentation.Name = "FBads.Ads Function",
        Documentation.LongDescription = "Created to get data from FBads service",
        Documentation.Examples = {
        [
            Description = "Returns a list of records from your FBads table",
            Code = "FBads.Data(""12345"",""2020-02-20"",""yesterday"")",
            Result = "{[Record1],[Record2],[Record3],...}"
        ],
        [
            Description = "Returns a list of records from your FBads table",
            Code = "FBads.Data(""54321"",""69daysAgo"",""today"")",
            Result = "{[Record1],[Record2],[Record3],...}"
        ]
        }
    ];





FBads.Func =( account as text, reportType as text, start as text, end as text,  limitVar as nullable text,  delayVar as nullable number)=>
let
    commonLimit = if limitVar=null then "150" else limitVar ,
    commonDelay = if delayVar=null then 0.2 else delayVar,
    source = Table.Join(dateTable(dateFunc(start),dateFunc(end),0),"month0",dateTable(dateFunc(start),dateFunc(end),1),"month1"),
    removeMonth = Table.RemoveColumns(source,{"month0"}),
    renameMonth = Table.RenameColumns(removeMonth,{"month1", "month"}),
    addOff=  Table.AddColumn(renameMonth, "after", each getOffset(account,reportType,commonLimit, commonDelay,[text0], [text1])),
    expa = Table.ExpandListColumn(addOff, "after"),
    tipchik = Table.TransformColumnTypes(expa,{{"after", type text}}),
    addData = Table.AddColumn(tipchik, "data", each getFB(account,reportType,commonLimit, commonDelay,[after], [text0], [text1])),
    removeCols = Table.RemoveColumns(addData,{"text0", "text1","after"}),
    added = Table.AddColumn(removeCols, "comment", each 
if (try [data])[Error]?[Message]?="Столбец ""Column1"" таблицы не найден." then "Нет данных" else 
if (try [data])[Error]?[Message]?=null then "Всё ОК" else (try [data])[Error]?[Detail]?[error]?[message]
),
    sort = Table.Sort(added, {{"month", Order.Ascending}}),
    ok = Table.SelectRows(sort, each ([comment] <> "Нет данных"))
in
   Table.TransformColumnTypes(ok,{{"comment", type text}});
       



dateFunc= (dat)=>
       if dat = "yesterday" then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()) , -1),"yyyy-MM-dd") 
       else if dat = "today" then Date.ToText(Date.From(DateTime.LocalNow()),"yyyy-MM-dd")
       else if (try Number.From(Text.BeforeDelimiter(dat,"daysAgo")) otherwise 0) >0 then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()),-1*Number.From(Text.BeforeDelimiter(dat,"daysAgo"))),"yyyy-MM-dd") 
       else dat;



dateTable = (date1, date2, order)=>
let
    listDates= List.Dates(Date.From(date1), Number.From(Date.From(date2)-Date.From(date1))+1, #duration(1,0,0,0) ),
    tableDates = Table.FromList(listDates, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    typeDates = Table.TransformColumnTypes(tableDates, {{"Column1", type date}}),
    sortDates = Table.Sort(typeDates,{{"Column1", order}}),
    monthAdd = Table.AddColumn(sortDates , "month"& Text.From(order), each Date.ToText([Column1],"yyyy-MM")),
    monthType = Table.TransformColumnTypes(monthAdd,{{"month"& Text.From(order), type text}}),
    removeDuplicates = Table.Distinct(monthType , {"month"& Text.From(order)}),
    textAdd = Table.AddColumn(removeDuplicates, "text"& Text.From(order), each (Date.ToText([Column1],"yyyy-MM-dd") )),
    renameDate = Table.RenameColumns(textAdd,{{"Column1", "date"&Text.From(order)}}),
    removeDate = Table.RemoveColumns(renameDate,{"date"& Text.From(order)}),
    textType = Table.TransformColumnTypes(removeDate,{{"text"& Text.From(order), type text}})
in textType;



getFB=(acc as text,report as text, commonLimit as text, commonDelay as number, aft as text, date1 as text,date2 as text)=> 
let
rep = if report="group" then "adset" else report,

fld = if report = "campaign" then "account_id,campaign_name,campaign_id,impressions,clicks,reach,spend,actions" else
      if report = "group" then "account_id,campaign_name,campaign_id,adset_name,adset_id,impressions,clicks,reach,spend,actions" else
      if report = "ad" then "account_id,campaign_name,campaign_id,adset_name,adset_id,ad_name,ad_id,impressions,clicks,reach,spend,actions" else "account_id,campaign_name,campaign_id,impressions,clicks,reach,spend,actions",

fldSp = if report = "campaign" then {"account_id","campaign_name","campaign_id","impressions","clicks","reach","spend","actions", "date_start"} else
        if report = "group" then {"account_id","campaign_name","campaign_id","adset_name","adset_id","impressions","clicks","reach","spend","actions", "date_start"} else
        if report = "ad" then {"account_id","campaign_name","campaign_id","adset_name","adset_id","ad_name","ad_id","impressions","clicks","reach","spend","actions", "date_start"} else {"account_id","campaign_name","campaign_id","impressions","clicks","reach","spend","actions","date_start"},

fldSpRes = if report = "campaign" then {"account_id","campaign_name","campaign_id","impressions","clicks","reach","spend","actions", "date_start"} else
        if report = "group" then {"account_id","campaign_name","campaign_id","group_name","group_id","impressions","clicks","reach","spend","actions", "date_start"} else
        if report = "ad" then {"account_id","campaign_name","campaign_id","group_name","group_id","ad_name","ad_id","impressions","clicks","reach","spend","actions", "date_start"} else {"account_id","campaign_name","campaign_id","impressions","clicks","reach","spend","actions","date_start"},


get = [limit=commonLimit, after=aft, #"access_token"=Extension.CurrentCredential()[Key], #"fields"=fld, #"level"=rep, #"time_increment"="1", #"time_range"="{'since':'"&date1&"','until':'"&date2&"'}"],
web =Function.InvokeAfter(()=> Web.Contents("https://graph.facebook.com/v10.0/", [RelativePath ="act_"&acc&"/insights", Query = get, ManualStatusHandling = {404, 400}]),#duration(0,0,0,commonDelay)),
result = Json.Document(web),
dataRes = result[data],
toTable = Table.FromList(dataRes, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
expand1 = Table.ExpandRecordColumn(toTable, "Column1", fldSp, fldSpRes),
expand2 = Table.ExpandListColumn(expand1, "actions"),
expand3 = Table.ExpandRecordColumn(expand2, "actions", {"action_type", "value"}, {"action_type", "value"}),
replaceNull1 = Table.ReplaceValue(expand3,null,"other_actions",Replacer.ReplaceValue,{"action_type"}),
replaceNull2 = Table.ReplaceValue(replaceNull1,null,"0",Replacer.ReplaceValue,{"value"}),
pivotCol = Table.Pivot(replaceNull2,  List.Distinct(replaceNull2[action_type]), "action_type", "value"),
chType = Table.TransformColumnTypes(pivotCol,{{"date_start", type date}, {"account_id", type text}, {"campaign_name", type text}, {"campaign_id", type text}, {"impressions", Int64.Type}, {"clicks", Int64.Type}, {"reach", Int64.Type}}),
transform = Table.TransformColumnTypes(chType, {{"spend", type number}}, "en-AU"),
order = Table.ReorderColumns(transform,{"date_start", "account_id", "campaign_name", "campaign_id", "impressions", "clicks", "reach", "spend", "link_click", "page_engagement", "post_engagement"})
in order;



getOffset=(acc as text,report as text,commonLimit as text, commonDelay as number, date1 as text,date2 as text)=> 
let
rep = if report="group" then "adset" else report,

fld = if report = "campaign" then "account_id,campaign_name,campaign_id" else
      if report = "group" then "account_id,campaign_name,campaign_id,adset_name,adset_id" else
      if report = "ad" then "account_id,campaign_name,campaign_id,adset_name,adset_id,ad_name,ad_id" else "account_id,campaign_name,campaign_id",

fldSp = if report = "campaign" then {"account_id","campaign_name","campaign_id", "date_start"} else
        if report = "group" then {"account_id","campaign_name","campaign_id","adset_name","adset_id", "date_start"} else
        if report = "ad" then {"account_id","campaign_name","campaign_id","adset_name","adset_id","ad_name","ad_id", "date_start"} else {"account_id","campaign_name","campaign_id","date_start"},

fldSpRes = if report = "campaign" then {"account_id","campaign_name","campaign_id", "date_start"} else
        if report = "group" then {"account_id","campaign_name","campaign_id","group_name","group_id", "date_start"} else
        if report = "ad" then {"account_id","campaign_name","campaign_id","group_name","group_id","ad_name","ad_id", "date_start"} else {"account_id","campaign_name","campaign_id","date_start"},

nextFunc=
    (aft)=>let
    get = [after = aft, limit = commonLimit, #"access_token"=Extension.CurrentCredential()[Key], 
    #"fields"=fld, #"level"=rep, #"time_increment"="1", #"time_range"="{'since':'"&date1&"','until':'"&date2&"'}"],
    web = Function.InvokeAfter(()=> Web.Contents("https://graph.facebook.com/v10.0/act_"&acc&"/insights", [Query = get,  ManualStatusHandling = {404, 400}]),#duration(0,0,0,commonDelay)),
    result = Json.Document(web),
    paging = try  Text.AfterDelimiter(result[paging][next],"after=") otherwise null
    in paging,

gen = List.Generate(()=>"", (x)=> x<>null,  nextFunc)

in gen;





FBads = [
    TestConnection = (dataSourcePath) => 
        { "FBads.Stat", 
        Json.Document(dataSourcePath)[account],
        Json.Document(dataSourcePath)[reportType],
        Json.Document(dataSourcePath)[start],
        Json.Document(dataSourcePath)[end],
        Json.Document(dataSourcePath)[limitVar]?,
        Json.Document(dataSourcePath)[delayVar]?
        },
    Authentication = [
        
         Key = []
   
    ],
    Label = "FBads Connection"
];



FBads.Publish = [
    Beta = false,
    Category = "Other",
    ButtonText = { "FBads Connector", "FBads Help" },
    LearnMoreUrl = "https://www.youtube.com/channel/UCqSLNYLN_3mf6nA1Xf7fu1g/",
    SourceImage = FBads.Icons,
    SourceTypeImage = FBads.Icons
];



FBads.Icons = [
    Icon16 = { Extension.Contents("FBads16.png"), Extension.Contents("FBads20.png"), Extension.Contents("FBads24.png"), Extension.Contents("FBads32.png") },
    Icon32 = { Extension.Contents("FBads32.png"), Extension.Contents("FBads40.png"), Extension.Contents("FBads48.png"), Extension.Contents("FBads64.png") }
];
