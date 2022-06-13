let
    Source = #"07_ATRCompleteDataset",
    #"Added KnownArrDt" =
        Table.AddColumn(
            Source,
            "KnownArrDt",
            each
                [ArrDt]
                <> #date(1900, 01, 01) and not ([ArrDt] = null),
            type logical
        ),
    #"Added KnownArrTime" =
        Table.AddColumn(
            #"Added KnownArrDt",
            "KnownArrTime",
            each
                [ArrTime]
                <> #time(0, 0, 0) and not ([ArrTime] = null),
            type logical
        ),
    #"Added KnownInjuryDt" =
        Table.AddColumn(
            #"Added KnownArrTime",
            "KnownInjurtyDt",
            each
                [InjuryDt]
                <> #date(1900, 01, 01) and not ([InjuryDt] = null),
            type logical
        ),
    #"Added KnownInjuryTime" =
        Table.AddColumn(
            #"Added KnownInjuryDt",
            "KnownInjuryTime",
            each
                [InjuryTime]
                <> #time(0, 0, 0) and not ([InjuryTime] = null),
            type logical
        ),
    #"Added KnownEDDischargeDt" =
        Table.AddColumn(
            #"Added KnownInjuryTime",
            "KnownEDDischargeDt",
            each
                [EDDischargeDt]
                <> #date(1900, 1, 1) and not ([EDDischargeDt] = null),
            type logical
        ),
    #"Added KnownEDDischargeTime" =
        Table.AddColumn(
            #"Added KnownEDDischargeDt",
            "KnownEDDischargeTime",
            each
                [EDDischargeTime]
                <> #time(0, 0, 0) and not ([EDDischargeTime] = null),
            type logical
        ),
    #"Add TimeToED" =
        Table.AddColumn(
            #"Added KnownEDDischargeTime",
            "TimeToED",
            each
                if
                    [OthHospTransCodeId]
                    = 2 and [KnownInjurtyDt] and [KnownInjuryTime] and [KnownArrDt] and [KnownArrTime] and [ArrDtTime]
                    >= [InjuryDateTime]
                then
                    [ArrDtTime] - [InjuryDateTime]
                else
                    null,
            Duration.Type
        ),
    #"Add TimeInED" =
        Table.AddColumn(
            #"Add TimeToED",
            "TimeInED",
            each
                if
                    [KnownArrDt] and [KnownArrTime] and [KnownEDDischargeDt] and [KnownEDDischargeTime] and [EDDischargeDtTime]
                    >= [ArrDtTime]
                then
                    [EDDischargeDtTime] - [ArrDtTime]
                else
                    null,
            Duration.Type
        ),
    #"Replaced Value" =
        Table.ReplaceValue(
            #"Add TimeInED",
            "",
            null,
            Replacer.ReplaceValue,
            {
                "SevereComplications",
                "OperationProcedures",
                "ComorbCodeIds"
            }
        ),
    #"Replaced Value2" =
        Table.ReplaceValue(
            #"Replaced Value",
            each
                [PatDOB]
                = #date(1901, 1, 1) or [PatDOB]
                = #date(1900, 1, 1),
            null,
            (x, y, z) as nullable date =>
                if y then
                    z
                else
                    x,
            {"PatDOB"}
        ),
    #"Replaced Value3" =
        Table.ReplaceValue(
            #"Replaced Value2",
            each
                [PatAge]
                = 999 or [PatAge]
                = 9999 or [PatAge]
                = null,
            -1,
            (x, y, z) as nullable number =>
                if y then
                    z
                else
                    x,
            {"PatAge"}
        ),
    #"Changed Type" =
        Table.TransformColumnTypes(
            #"Replaced Value3",
            {
                {
                    "PatAge",
                    Int64.Type
                }
            }
        ),
    bufer_table = Table.Buffer(#"Changed Type"),
    test =
        Table.AddColumn(
            bufer_table,
            "Custom",
            each
                Table.FromColumns(
                    {
                        try Text.Split([OperationProcedures], ";") otherwise
                            {
                                null
                            },
                        try Text.Split([SevereComplications], ";") otherwise
                            {
                                null
                            },
                        try Text.Split([AIS], ";") otherwise
                            {
                                null
                            },
                        try Text.Split([ComorbCodeIds], ";") otherwise
                            {
                                null
                            }
                    },
                    type table [
                        OpProcCodeId = text,
                        SevCompCodeId = text,
                        AISCodeId = text,
                        ComorbCodeId = text
                    ]
                ),
            type table [
                OpProcCodeId = text,
                SevCompCodeId = text,
                AISCodeId = text,
                ComorbCodeId = text
            ]
        ),
    #"Expanded Custom" =
        Table.ExpandTableColumn(
            test,
            "Custom",
            {
                "OpProcCodeId",
                "SevCompCodeId",
                "AISCodeId",
                "ComorbCodeId"
            },
            {
                "OpProcCodeId",
                "SevCompCodeId",
                "AISCodeId",
                "ComorbCodeId"
            }
        )
in
    #"Expanded Custom"